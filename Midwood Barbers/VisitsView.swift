import SwiftUI

/// What you are holding, as ticket stubs. No name on a stub — the chair is the shop's,
/// so the stub carries the time, the service and the price and nothing invented.
struct VisitsView: View {
    @EnvironmentObject private var chairbook: Chairbook
    let openServices: () -> Void

    @State private var pendingCancel: Booking?
    /// The service a past stub is being taken up again with. No barber travels with it —
    /// there is nobody to carry over, because the chair was the shop's the first time too.
    @State private var again: Service?

    var body: some View {
        Page {
            VStack(alignment: .leading, spacing: 7) {
                Overline(text: "Your chair")
                Text("Visits")
                    .font(Pine.display(29))
                    .foregroundColor(Pine.letter)
            }

            if chairbook.bookings.isEmpty {
                Slab {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nothing booked yet")
                            .font(Pine.copy(16, .semibold))
                            .foregroundColor(Pine.letter)
                        Text("Pick something off the board and the chair turns up here.")
                            .font(Pine.copy(14))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        GhostButton(title: "See the board", action: openServices)
                    }
                }
            }

            if !chairbook.upcoming.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Overline(text: "Coming up")
                    ForEach(chairbook.upcoming) { held in
                        stub(held, isPast: false)
                    }
                }
            }

            if !chairbook.past.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Overline(text: "Been and gone")
                    tally
                    ForEach(chairbook.past) { held in
                        stub(held, isPast: true)
                    }
                }
            }
        }
        .alert(item: $pendingCancel) { held in
            Alert(title: Text("Give up this chair?"),
                  message: Text("\(held.service?.name ?? "Booking") · \(Stamp.day(held.day)) at \(Shop.clock(held.minutes))"),
                  primaryButton: .destructive(Text("Give it up")) { chairbook.cancel(held) },
                  secondaryButton: .cancel())
        }
        .sheet(item: $again) { service in
            BookingSheet(service: service).environmentObject(chairbook)
        }
    }

    /// Three figures over the visits that have been: how many, what they came to, and how
    /// often. The gap only turns up from the second visit on — between one visit and
    /// nothing there is no gap at all, and a printed "0 days" would read as a fact.
    private var tally: some View {
        Slab {
            HStack(spacing: 14) {
                figure("\(chairbook.past.count)",
                       chairbook.past.count == 1 ? "visit" : "visits")
                Rectangle().fill(Pine.hair).frame(width: Gap.hair, height: 34)
                figure(Shop.money(chairbook.spentCents), "spent")
                if let gap = chairbook.averageGapDays {
                    Rectangle().fill(Pine.hair).frame(width: Gap.hair, height: 34)
                    figure(gap == 1 ? "1 day" : "\(gap) days", "between")
                }
            }
        }
    }

    private func figure(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Pine.figure(18, .bold))
                .foregroundColor(Pine.parchment)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption.uppercased())
                .font(Pine.figure(10, .semibold))
                .tracking(1)
                .foregroundColor(Pine.letterSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The time reads large because it is the only part anybody checks twice, and the
    /// parchment band down the edge keeps a stub from looking like just another panel.
    private func stub(_ held: Booking, isPast: Bool) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isPast ? Pine.hair : Pine.parchment)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Shop.clock(held.minutes))
                            .font(Pine.figure(20, .bold))
                            .foregroundColor(isPast ? Pine.letterSoft : Pine.letter)
                        Text(Stamp.day(held.day))
                            .font(Pine.figure(12))
                            .foregroundColor(Pine.letterSoft)
                    }
                    Spacer(minLength: 8)
                    if !isPast {
                        Button(action: { pendingCancel = held }) {
                            CrossMark(size: 15)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                HairRule()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(held.service?.name ?? "Booking")
                            .font(Pine.copy(15, .semibold))
                            .foregroundColor(isPast ? Pine.letterSoft : Pine.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(Shop.duration(held.runMinutes)) in the chair")
                            .font(Pine.figure(11))
                            .foregroundColor(Pine.letterSoft)
                    }
                    Spacer(minLength: 8)
                    if let service = held.service {
                        Text(Shop.money(service.priceCents))
                            .font(Pine.figure(14, .semibold))
                            .foregroundColor(isPast ? Pine.letterSoft : Pine.parchment)
                    }
                }

                // The usual thing anybody does with a haircut they have had: have it
                // again. Only the service carries over — a service that has since left the
                // board has nothing to reopen, so the row is not drawn at all.
                if isPast, let service = held.service {
                    HairRule()
                    Button(action: { again = service }) {
                        Text("Book this again")
                            .font(Pine.figure(12, .semibold))
                            .foregroundColor(Pine.parchment)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
        }
        .background(Pine.slabFill(!isPast))
        .overlay(
            RoundedRectangle(cornerRadius: Gap.corner)
                .stroke(Pine.edge, lineWidth: Gap.hair)
        )
        .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
        .shadow(color: Color.black.opacity(isPast ? 0.18 : 0.36),
                radius: isPast ? 6 : 12, x: 0, y: isPast ? 3 : 6)
    }
}
