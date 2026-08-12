import UIKit

/// The three things this app hands to the phone rather than doing badly itself: the way to
/// the door, the shop's telephone, and the listing where the public reviews actually live.
///
/// One door for all three, so the guard is written once. `canOpenURL` first — on a device
/// with no dialler the button should quietly do nothing rather than throw somebody out to
/// an app that cannot take it.
enum LinkOut {
    /// Apple Maps, given the address to label the pin and the coordinates to put it in the
    /// right place. "The Plaza" alone would send somebody to any of a dozen guesses.
    static var directions: String {
        let query = Shop.addressLine
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        return "https://maps.apple.com/?q=\(query)&ll=\(Shop.latitude),\(Shop.longitude)"
    }

    static var call: String { "tel://\(Shop.phoneDigits)" }

    /// Where the shop's real reviews are. This app carries the standing — one average and
    /// one count — and hands the words themselves back to the listing rather than
    /// reprinting anybody's review inside a booking app.
    static let listing = "https://www.google.com/maps/search/"
        + "?api=1&query=Midwood%20Barbers%202915%20The%20Plaza%20Charlotte%20NC"

    static func open(_ address: String) {
        guard let url = URL(string: address),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
