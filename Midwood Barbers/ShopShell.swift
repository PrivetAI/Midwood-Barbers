import SwiftUI

/// A hand-built bar rather than TabView: `.tabItem` renders only Image and Text, so the
/// Canvas marks this app draws would simply never appear inside one.
struct ShopShell: View {
    @EnvironmentObject private var chairbook: Chairbook
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0: HomeView(openServices: { tab = 1 })
                case 1: ServicesView()
                case 2: VisitsView(openServices: { tab = 1 })
                default: ShopView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // A ScrollView draws its content up through the top inset by design — fine
            // under a navigation bar, but nothing here has one, so rows would ride over
            // the clock. Clipping to the content area is what actually stops it.
            .clipped()

            bar
        }
        // Painted through `.background` rather than as a ZStack sibling: a sibling that
        // ignores the safe area stretches the stack itself, and the scrolling content
        // above then runs under the clock again.
        .background(Pine.room.ignoresSafeArea())
        // No screen here carries a navigation bar. A zero-height band that ignores the
        // top inset expands into it and paints it out, without joining the layout.
        .overlay(
            Pine.slab
                .frame(height: 0)
                .ignoresSafeArea(edges: .top),
            alignment: .top
        )
    }

    private var bar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Pine.hair)
                .frame(height: Gap.hair)
            HStack(spacing: 0) {
                button(index: 0, label: "Home") { BenchMark(size: 22, color: tint(0)) }
                button(index: 1, label: "Services") { RazorMark(size: 22, color: tint(1)) }
                button(index: 2, label: "Visits") { StubMark(size: 22, color: tint(2)) }
                button(index: 3, label: "Shop") { AwningMark(size: 22, color: tint(3)) }
            }
            .padding(.top, 9)
            .padding(.bottom, 3)
            .background(
                LinearGradient(colors: [Pine.slabRaised, Pine.slab],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: -4)
    }

    private func tint(_ index: Int) -> Color {
        tab == index ? Pine.parchment : Pine.letterSoft
    }

    private func button<Mark: View>(index: Int, label: String,
                                    @ViewBuilder mark: () -> Mark) -> some View {
        Button(action: { tab = index }) {
            VStack(spacing: 5) {
                mark()
                Text(label)
                    .font(Pine.figure(10, .semibold))
                    .tracking(0.7)
                    .foregroundColor(tint(index))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
