import SwiftUI

/// Held for the second or two the launch check takes. Wears the shop's pine and parchment
/// so the wait reads as the app opening rather than as a blank frame.
struct MidwoodOpeningScreen: View {
    @State private var breathing = false

    var body: some View {
        ZStack {
            Pine.ground.ignoresSafeArea()
            GrainBackdrop().ignoresSafeArea()

            VStack(spacing: 22) {
                RazorMark(size: 40, color: Pine.parchment)
                    .frame(width: 78, height: 78)
                    .overlay(Circle().stroke(Pine.parchment.opacity(0.8), lineWidth: 1.5))
                    .scaleEffect(breathing ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                               value: breathing)

                VStack(spacing: 7) {
                    Text(Shop.name)
                        .font(Pine.display(24))
                        .foregroundColor(Pine.letter)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Overline(text: "\(Shop.city), \(Shop.region)")
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear { breathing = true }
    }
}
