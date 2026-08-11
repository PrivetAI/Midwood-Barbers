import SwiftUI
import WebKit

struct MidwoodWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let settings = WKWebViewConfiguration()
        settings.allowsInlineMediaPlayback = true

        let panel = WKWebView(frame: .zero, configuration: settings)
        panel.allowsBackForwardNavigationGestures = true
        // Belt and braces — the real guarantee against the notch is the frame, set where
        // this is presented. Never .never: that always draws under the clock.
        panel.scrollView.contentInsetAdjustmentBehavior = .always
        panel.isOpaque = true
        panel.backgroundColor = UIColor(red: 0.086, green: 0.141, blue: 0.114, alpha: 1)

        if let url = URL(string: urlString) {
            panel.load(URLRequest(url: url))
        }
        return panel
    }

    /// Stays empty on purpose. Loading here would reload the page on every SwiftUI
    /// re-render, and the page would never settle.
    func updateUIView(_ panel: WKWebView, context: Context) {}
}

/// Reached from the Shop screen. The same address the app opens on, so there is one page
/// to keep current rather than two — and no redirect check on this route.
struct MidwoodPolicyScreen: View {
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ZStack {
            Pine.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Privacy Policy")
                        .font(Pine.display(18))
                        .foregroundColor(Pine.letter)
                    Spacer()
                    Button(action: { presentation.wrappedValue.dismiss() }) {
                        CrossMark(size: 17, color: Pine.letter)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Gap.gutter)
                .padding(.vertical, 12)
                HairRule()

                MidwoodWebPanel(urlString: MidwoodGate.sourceLink)
            }
        }
    }
}
