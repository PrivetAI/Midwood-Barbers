import SwiftUI

/// The shop's colours, written out one by one rather than taken from the system, so the
/// app looks the same whatever the phone's appearance setting happens to say.
///
/// Dark pine with a parchment accent. The accent where a barbershop normally reaches for
/// gold — near-white cream carries better on a green this deep, and it reads as an old
/// shopfront rather than as a metallic.
enum Pine {
    static let ground = Color(red: 0.086, green: 0.141, blue: 0.114)      // #16241D
    static let slab = Color(red: 0.114, green: 0.180, blue: 0.145)        // #1D2E25
    static let slabRaised = Color(red: 0.141, green: 0.220, blue: 0.176)  // #24382D
    static let letter = Color(red: 0.929, green: 0.906, blue: 0.851)      // #EDE7D9
    static let letterSoft = Color(red: 0.557, green: 0.604, blue: 0.561)  // #8E9A8F
    static let parchment = Color(red: 0.949, green: 0.925, blue: 0.867)   // #F2ECDD
    static let onParchment = Color(red: 0.086, green: 0.141, blue: 0.114) // #16241D
    static let hair = Color(red: 0.180, green: 0.267, blue: 0.216)        // #2E4437

    /// The room the screens sit in: a touch of light at the top of the glass falling away
    /// towards the bottom. A single flat green reads as card stock; a wash reads as depth.
    static var room: LinearGradient {
        LinearGradient(colors: [slab, ground], startPoint: .top, endPoint: .bottom)
    }

    static func slabFill(_ raised: Bool) -> LinearGradient {
        LinearGradient(colors: raised ? [slabRaised, slab] : [slab, ground],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Light catches the top edge of a panel and fades — the cheapest way to make a flat
    /// rectangle sit above the background rather than be cut out of it.
    static var edge: LinearGradient {
        LinearGradient(colors: [hair, hair.opacity(0.35)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// Serif, set heavy. A razor shop that has been on the same corner since 2019 gets a
    /// signwriter's face, not a UI font.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func copy(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Prices, clock times and counts. Seven services from $18 to $60 and a column of
    /// half hours only line up if the figures are monospaced.
    static func figure(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum Gap {
    static let gutter: CGFloat = 20
    static let corner: CGFloat = 5
    static let hair: CGFloat = 1
    /// Long lines of serif copy stop being readable past about this width, and it keeps
    /// the layout honest when the app runs in iPad compatibility or in landscape.
    static let column: CGFloat = 640
}

// MARK: - Drawn marks
//
// Every mark below is a Canvas. Nothing here comes from the system icon set, so nothing
// shifts underneath the app when iOS reworks its own glyphs.

/// The bench by the window — the front screen's mark, and the thing the shop is known for.
struct BenchMark: View {
    var size: CGFloat = 24
    var color: Color = Pine.parchment

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let stroke = max(1.4, unit * 0.085)

            var seat = Path()
            seat.move(to: CGPoint(x: unit * 0.16, y: unit * 0.56))
            seat.addLine(to: CGPoint(x: unit * 0.84, y: unit * 0.56))
            context.stroke(seat, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke, lineCap: .round))

            var back = Path()
            back.move(to: CGPoint(x: unit * 0.22, y: unit * 0.34))
            back.addLine(to: CGPoint(x: unit * 0.78, y: unit * 0.34))
            context.stroke(back, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke * 0.8, lineCap: .round))

            for leg in 0..<2 {
                let x = unit * (leg == 0 ? 0.26 : 0.74)
                var post = Path()
                post.move(to: CGPoint(x: x, y: unit * 0.3))
                post.addLine(to: CGPoint(x: x, y: unit * 0.82))
                context.stroke(post, with: .color(color),
                               style: StrokeStyle(lineWidth: stroke * 0.8, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

/// An open straight razor: blade laid back against the handle. The services mark, and the
/// one shape in the set that could only belong to a barbershop.
struct RazorMark: View {
    var size: CGFloat = 24
    var color: Color = Pine.parchment

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let stroke = max(1.4, unit * 0.08)

            var blade = Path()
            blade.move(to: CGPoint(x: unit * 0.18, y: unit * 0.32))
            blade.addLine(to: CGPoint(x: unit * 0.72, y: unit * 0.2))
            blade.addCurve(to: CGPoint(x: unit * 0.2, y: unit * 0.44),
                           control1: CGPoint(x: unit * 0.6, y: unit * 0.42),
                           control2: CGPoint(x: unit * 0.4, y: unit * 0.48))
            blade.closeSubpath()
            context.stroke(blade, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke, lineJoin: .round))

            var handle = Path()
            handle.move(to: CGPoint(x: unit * 0.2, y: unit * 0.52))
            handle.addLine(to: CGPoint(x: unit * 0.78, y: unit * 0.74))
            context.stroke(handle, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke * 1.5, lineCap: .round))

            // The pivot pin, where blade and handle meet.
            context.fill(Path(ellipseIn: CGRect(x: unit * 0.14, y: unit * 0.38,
                                                width: unit * 0.14, height: unit * 0.14)),
                         with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

/// A torn ticket stub — the mark for what you are holding.
struct StubMark: View {
    var size: CGFloat = 24
    var color: Color = Pine.parchment

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let stroke = max(1.4, unit * 0.085)

            let frame = Path(roundedRect: CGRect(x: unit * 0.14, y: unit * 0.26,
                                                 width: unit * 0.72, height: unit * 0.48),
                             cornerRadius: unit * 0.06)
            context.stroke(frame, with: .color(color), lineWidth: stroke)

            // The perforation the stub tears along.
            var perf = Path()
            var y = unit * 0.3
            while y < unit * 0.7 {
                perf.move(to: CGPoint(x: unit * 0.58, y: y))
                perf.addLine(to: CGPoint(x: unit * 0.58, y: y + unit * 0.05))
                y += unit * 0.11
            }
            context.stroke(perf, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke * 0.7, lineCap: .round))

            var line = Path()
            line.move(to: CGPoint(x: unit * 0.24, y: unit * 0.44))
            line.addLine(to: CGPoint(x: unit * 0.46, y: unit * 0.44))
            context.stroke(line, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke * 0.7, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// The shopfront on The Plaza: an awning over a window.
struct AwningMark: View {
    var size: CGFloat = 24
    var color: Color = Pine.parchment

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let stroke = max(1.4, unit * 0.085)

            var awning = Path()
            awning.move(to: CGPoint(x: unit * 0.12, y: unit * 0.42))
            awning.addLine(to: CGPoint(x: unit * 0.28, y: unit * 0.2))
            awning.addLine(to: CGPoint(x: unit * 0.72, y: unit * 0.2))
            awning.addLine(to: CGPoint(x: unit * 0.88, y: unit * 0.42))
            awning.closeSubpath()
            context.stroke(awning, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke, lineJoin: .round))

            // The scalloped hem along the bottom of the canvas.
            for scallop in 0..<3 {
                let x = unit * (0.24 + Double(scallop) * 0.26)
                var arc = Path()
                arc.addArc(center: CGPoint(x: x, y: unit * 0.42), radius: unit * 0.09,
                           startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                context.stroke(arc, with: .color(color), lineWidth: stroke * 0.7)
            }

            var window = Path()
            window.move(to: CGPoint(x: unit * 0.24, y: unit * 0.58))
            window.addLine(to: CGPoint(x: unit * 0.24, y: unit * 0.84))
            window.addLine(to: CGPoint(x: unit * 0.76, y: unit * 0.84))
            window.addLine(to: CGPoint(x: unit * 0.76, y: unit * 0.58))
            context.stroke(window, with: .color(color),
                           style: StrokeStyle(lineWidth: stroke * 0.8, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A small cross, drawn rather than borrowed from the system set.
struct CrossMark: View {
    var size: CGFloat = 15
    var color: Color = Pine.letterSoft

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let inset = unit * 0.24
            var path = Path()
            path.move(to: CGPoint(x: inset, y: inset))
            path.addLine(to: CGPoint(x: unit - inset, y: unit - inset))
            path.move(to: CGPoint(x: unit - inset, y: inset))
            path.addLine(to: CGPoint(x: inset, y: unit - inset))
            context.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: max(1.3, unit * 0.11), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct StarMark: View {
    let filled: Bool
    var size: CGFloat = 13

    var body: some View {
        Canvas { context, canvas in
            let unit = min(canvas.width, canvas.height)
            let center = CGPoint(x: unit / 2, y: unit / 2)
            let outer = unit * 0.48
            let inner = outer * 0.42

            var path = Path()
            for step in 0..<10 {
                let radius = step % 2 == 0 ? outer : inner
                let angle = -Double.pi / 2 + Double(step) * Double.pi / 5
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                    y: center.y + CGFloat(sin(angle)) * radius)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()

            if filled {
                context.fill(path, with: .color(Pine.parchment))
            } else {
                context.stroke(path, with: .color(Pine.parchment.opacity(0.45)), lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Woodgrain, dialled almost all the way down. Stands in for photography the shop has not
/// sent, without pretending to be a photograph.
struct GrainBackdrop: View {
    var spacing: CGFloat = 11
    var opacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            let tint = Pine.parchment.opacity(opacity)
            var y: CGFloat = 0
            var wave = 0
            while y < size.height {
                let bow = CGFloat(6 + (wave % 3) * 5)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addQuadCurve(to: CGPoint(x: size.width, y: y),
                                  control: CGPoint(x: size.width / 2,
                                                   y: y + (wave % 2 == 0 ? bow : -bow)))
                context.stroke(path, with: .color(tint), lineWidth: 1)
                y += spacing
                wave += 1
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Shared chrome

struct Overline: View {
    let text: String
    var tint: Color = Pine.letterSoft

    var body: some View {
        Text(text.uppercased())
            .font(Pine.figure(11, .semibold))
            .tracking(1.5)
            .foregroundColor(tint)
    }
}

struct HairRule: View {
    var body: some View {
        Rectangle().fill(Pine.hair).frame(height: Gap.hair)
    }
}

struct Slab<Content: View>: View {
    var raised = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Pine.slabFill(raised))
            .overlay(
                RoundedRectangle(cornerRadius: Gap.corner)
                    .stroke(Pine.edge, lineWidth: Gap.hair)
            )
            .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
            // Cast down and away, never a halo — the panel should read as lifted off the
            // pine, not lit from behind it.
            .shadow(color: Color.black.opacity(raised ? 0.4 : 0.26),
                    radius: raised ? 14 : 8, x: 0, y: raised ? 7 : 4)
    }
}

struct ParchmentButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Pine.copy(16, .semibold))
                .foregroundColor(Pine.onParchment)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(Pine.parchment.opacity(isEnabled ? 1 : 0.3))
                .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Pine.copy(15, .medium))
                .foregroundColor(Pine.letter)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: Gap.corner)
                        .stroke(Pine.hair, lineWidth: Gap.hair)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Every screen sits on the pine, scrolls, and clears the tab bar. The bottom padding is
/// the bar's height plus room to breathe — otherwise the last row is cut in half by it.
struct Page<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding(.horizontal, Gap.gutter)
            .padding(.top, 10)
            .padding(.bottom, 40)
            // Clamped and centred: on iPad, and in landscape on any phone, a full-width
            // line of serif copy runs far past a comfortable measure.
            .frame(maxWidth: Gap.column, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Pine.room.ignoresSafeArea())
    }
}
