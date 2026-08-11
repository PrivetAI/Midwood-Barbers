import Foundation

// The shop, written down once. Prices sit in cents so nothing rounds twice, and minutes
// drive the diary — a 75-minute cut and beard genuinely takes more of the day than a
// 15-minute line-up, and the booking column shows it.

struct Service: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let priceCents: Int
    let minutes: Int
    let isSignature: Bool
}

struct ServiceGroup: Identifiable, Equatable {
    let id: String
    let name: String
    let note: String?
    let services: [Service]
}

struct OpeningHours: Identifiable, Equatable {
    /// 1 = Sunday, matching Calendar's own weekday numbering.
    let weekday: Int
    let opensAt: Int?
    let closesAt: Int?

    var id: Int { weekday }
    var isClosed: Bool { opensAt == nil || closesAt == nil }

    var dayName: String { Shop.weekdayNames[weekday] }

    var rangeLabel: String {
        guard let open = opensAt, let close = closesAt else { return "Closed" }
        return "\(Shop.clock(open)) – \(Shop.clock(close))"
    }
}

enum Shop {
    static let name = "Midwood Barbers"
    static let shortName = "Midwood"
    static let tagline = "The Plaza, Villa Heights. Chairs, not a call centre."
    static let about = "A Villa Heights shop on The Plaza. Straight razors, proper fades, "
        + "and a bench by the window for whoever's next."
    static let street = "2915 The Plaza"
    static let city = "Charlotte"
    static let region = "NC"
    static let postalCode = "28205"
    static let phone = "(980) 237-1222"
    static let established = "Est. 2019"
    /// What this trade calls the person in the chair. Used in copy, never as a filter —
    /// see below.
    static let staffNoun = "barber"

    /// There is no roster in this build, and that is deliberate rather than missing.
    /// Midwood is a two-chair shop: a booking belongs to the shop, and the only honest
    /// question at a given time is how many of the two chairs are still free. So there is
    /// no barber picker anywhere in the app, and nothing anywhere is booked "with" a name.
    static let chairCount = 2

    static let ratingAverage = 4.9
    static let ratingCount = 394

    static var addressLine: String { "\(street), \(city), \(region) \(postalCode)" }

    static let catalog: [ServiceGroup] = [
        ServiceGroup(id: "cuts", name: "Cuts", note: nil, services: [
            Service(id: "cut-standard", name: "Haircut",
                    detail: "Cut, wash and a neck shave.",
                    priceCents: 4000, minutes: 45, isSignature: true),
            Service(id: "cut-skinfade", name: "Skin Fade",
                    detail: "Bald on the sides, blended up.",
                    priceCents: 4500, minutes: 45, isSignature: false),
            Service(id: "cut-kids", name: "Kids Cut",
                    detail: "Twelve and under.",
                    priceCents: 3000, minutes: 30, isSignature: false)
        ]),
        ServiceGroup(id: "razor", name: "Razor Work",
                     note: "Hot lather, cold towel, no rushing.", services: [
            Service(id: "shave-straight", name: "Straight Razor Shave",
                    detail: "The full traditional shave.",
                    priceCents: 4500, minutes: 45, isSignature: true),
            Service(id: "beard-trim", name: "Beard Trim",
                    detail: "Shaped and lined with the razor.",
                    priceCents: 2500, minutes: 30, isSignature: false),
            Service(id: "cut-beard", name: "Cut & Beard",
                    detail: "Both, back to back.",
                    priceCents: 6000, minutes: 75, isSignature: false)
        ]),
        ServiceGroup(id: "quick", name: "Quick Work", note: nil, services: [
            Service(id: "lineup", name: "Line-up",
                    detail: "Edges only.",
                    priceCents: 1800, minutes: 15, isSignature: false)
        ])
    ]

    static var allServices: [Service] { catalog.flatMap { $0.services } }

    static func service(_ id: String) -> Service? { allServices.first { $0.id == id } }

    static var cheapestCents: Int { allServices.map { $0.priceCents }.min() ?? 0 }

    /// Five days only. Sunday and Monday the door does not open at all, and Saturday
    /// finishes two hours early — a two-chair shop cannot run seven days, and pretending
    /// otherwise would be the one thing in here that is not true.
    static let hours: [OpeningHours] = [
        OpeningHours(weekday: 1, opensAt: nil, closesAt: nil),
        OpeningHours(weekday: 2, opensAt: nil, closesAt: nil),
        OpeningHours(weekday: 3, opensAt: 10 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 4, opensAt: 10 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 5, opensAt: 10 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 6, opensAt: 10 * 60, closesAt: 19 * 60),
        OpeningHours(weekday: 7, opensAt: 10 * 60, closesAt: 17 * 60)
    ]

    static func hours(for weekday: Int) -> OpeningHours {
        hours.first { $0.weekday == weekday } ?? hours[0]
    }

    static func isOpenDay(_ day: Date) -> Bool {
        !hours(for: Calendar.current.component(.weekday, from: day)).isClosed
    }

    /// The week starting Monday, the way a shop sign reads. All seven rows are kept so the
    /// two shut days are visible instead of being folded into a "Tue–Sat" line.
    static var weekOrdered: [OpeningHours] {
        [2, 3, 4, 5, 6, 7, 1].compactMap { day in hours.first { $0.weekday == day } }
    }

    /// The stretch of the day the diary has to cover, across every day the shop opens.
    /// Used to normalise the time-of-day pressure in the availability model.
    static var earliestOpen: Int { hours.compactMap { $0.opensAt }.min() ?? 0 }
    static var latestClose: Int { hours.compactMap { $0.closesAt }.max() ?? 24 * 60 }

    static let weekdayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday",
                               "Thursday", "Friday", "Saturday"]

    static func clock(_ minutes: Int) -> String {
        let hour = minutes / 60, minute = minutes % 60
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return minute == 0 ? "\(hour12) \(suffix)"
                           : String(format: "%d:%02d %@", hour12, minute, suffix)
    }

    static func money(_ cents: Int) -> String {
        cents % 100 == 0 ? "$\(cents / 100)" : String(format: "$%.2f", Double(cents) / 100)
    }

    static func duration(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
    }

    /// "2 chairs free" / "1 chair free" — the line that stands where a barber's name
    /// would otherwise go.
    static func chairPhrase(_ count: Int) -> String {
        count == 1 ? "1 chair free" : "\(count) chairs free"
    }
}
