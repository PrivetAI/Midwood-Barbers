import SwiftUI

/// The whole board, in the three groups the shop keeps it in. Seven services is short
/// enough to show in full, so nothing is hidden behind a filter or a "more" row.
struct ServicesView: View {
    @EnvironmentObject private var chairbook: Chairbook
    @State private var booking: Service?

    var body: some View {
        Page {
            VStack(alignment: .leading, spacing: 7) {
                Overline(text: "The board")
                Text("Services")
                    .font(Pine.display(29))
                    .foregroundColor(Pine.letter)
                Text("Seven, from \(Shop.money(Shop.cheapestCents)). Every one books to the "
                     + "shop's \(Shop.chairCount) chairs, not to a name.")
                    .font(Pine.copy(14))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Shop.catalog) { group in
                VStack(alignment: .leading, spacing: 0) {
                    Overline(text: group.name)
                        .padding(.bottom, group.note == nil ? 6 : 5)

                    if let note = group.note {
                        Text(note)
                            .font(Pine.copy(13))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 6)
                    }

                    ForEach(Array(group.services.enumerated()), id: \.element.id) { index, service in
                        if index > 0 { HairRule() }
                        Button(action: { booking = service }) {
                            ServiceRow(service: service,
                                       opening: chairbook.nextOpening(for: service))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // The long sit is the scarce one, and the reason the "soonest" line above it
            // usually sits days behind the others.
            Slab {
                VStack(alignment: .leading, spacing: 8) {
                    Overline(text: "Why the long ones run out first")
                    Text("A chair only counts as free if it stays free for the whole "
                         + "service. Cut & Beard needs an hour and a quarter of one of "
                         + "two chairs, so it thins out days before a line-up does.")
                        .font(Pine.copy(13))
                        .foregroundColor(Pine.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .sheet(item: $booking) { service in
            BookingSheet(service: service).environmentObject(chairbook)
        }
    }
}
