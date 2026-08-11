import SwiftUI

/// The front screen leads with the next free chair rather than a hero image. For a shop
/// that runs on two chairs and a bench, that is the one fact anybody opens this for.
struct HomeView: View {
    @EnvironmentObject private var chairbook: Chairbook
    let openServices: () -> Void

    @State private var now = Date()
    @State private var booking: Service?

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                nextChair
                if let next = chairbook.upcoming.first { yours(next) }
                quickList
            }
            .padding(.horizontal, Gap.gutter)
            .padding(.top, 10)
            .padding(.bottom, 36)
            .frame(maxWidth: Gap.column, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(
            ZStack {
                Pine.room
                GrainBackdrop()
            }
            .ignoresSafeArea()
        )
        .onReceive(tick) { now = $0 }
        .sheet(item: $booking) { service in
            BookingSheet(service: service).environmentObject(chairbook)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Overline(text: "\(Shop.city), \(Shop.region)")
            Text(Shop.name)
                .font(Pine.display(34))
                .foregroundColor(Pine.letter)
                .fixedSize(horizontal: false, vertical: true)
            DoorLine(state: DoorState.now(now))
        }
    }

    /// The house haircut. Everything else on the board is measured against it.
    private var headline: Service { Shop.service("cut-standard") ?? Shop.allServices[0] }

    private var nextChair: some View {
        Slab(raised: true) {
            VStack(alignment: .leading, spacing: 14) {
                Overline(text: "Next free chair")

                if let opening = chairbook.nextOpening(for: headline) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(openingLabel(opening.day, opening.slot))
                            .font(Pine.display(25))
                            .foregroundColor(Pine.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(headline.name) · \(Shop.money(headline.priceCents)) · \(Shop.duration(headline.minutes))")
                            .font(Pine.copy(14))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        // No name here on purpose. The booking is with the shop, and the
                        // honest detail is how much of the room is still clear.
                        Text("\(opening.slot.chairsFree) of \(Shop.chairCount) chairs open then")
                            .font(Pine.figure(11))
                            .foregroundColor(Pine.parchment)
                    }
                    ParchmentButton(title: "Take This Chair") { booking = headline }
                } else {
                    Text("Booked out for the next fortnight.")
                        .font(Pine.copy(15))
                        .foregroundColor(Pine.letter)
                        .fixedSize(horizontal: false, vertical: true)
                    GhostButton(title: "See every service", action: openServices)
                }
            }
        }
    }

    private func openingLabel(_ day: Date, _ slot: ChairSlot) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today at \(slot.label)" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow at \(slot.label)" }
        return "\(Stamp.weekdayFull(day)) at \(slot.label)"
    }

    private func yours(_ held: Booking) -> some View {
        Slab {
            VStack(alignment: .leading, spacing: 9) {
                Overline(text: "Your chair", tint: Pine.parchment)
                Text(held.service?.name ?? "Booked")
                    .font(Pine.copy(17, .semibold))
                    .foregroundColor(Pine.letter)
                Text("\(Stamp.day(held.day)) at \(Shop.clock(held.minutes))")
                    .font(Pine.figure(13))
                    .foregroundColor(Pine.letterSoft)
            }
        }
    }

    /// Three off the board — a cut, a shave and the quick one. The rest is a tab away.
    private var quickList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Overline(text: "Book something")
                Spacer()
                Button(action: openServices) {
                    Text("All services")
                        .font(Pine.figure(11, .semibold))
                        .foregroundColor(Pine.parchment)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)

            ForEach(Array(featured.enumerated()), id: \.element.id) { index, service in
                if index > 0 { HairRule() }
                Button(action: { booking = service }) {
                    ServiceRow(service: service, opening: chairbook.nextOpening(for: service))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var featured: [Service] {
        ["cut-standard", "shave-straight", "lineup"].compactMap { Shop.service($0) }
    }
}

struct DoorLine: View {
    let state: DoorState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.isOpen ? Pine.parchment : Pine.letterSoft)
                .frame(width: 7, height: 7)
            Text(state.label)
                .font(Pine.figure(11, .semibold))
                .tracking(1.1)
                .foregroundColor(Pine.letter)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One line of the board: what it is, what it costs, how long the chair is yours, and the
/// soonest it can actually happen. That last part is what makes this a diary and not a
/// price list stuck in a window.
struct ServiceRow: View {
    let service: Service
    let opening: (day: Date, slot: ChairSlot)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(service.name)
                        .font(Pine.copy(15, .semibold))
                        .foregroundColor(Pine.letter)
                    if service.isSignature {
                        Overline(text: "Signature", tint: Pine.parchment)
                    }
                }
                Text(service.detail)
                    .font(Pine.copy(13))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(soonest)
                    .font(Pine.figure(11))
                    .foregroundColor(opening == nil ? Pine.letterSoft : Pine.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(Shop.money(service.priceCents))
                    .font(Pine.figure(15, .semibold))
                    .foregroundColor(Pine.letter)
                Text(Shop.duration(service.minutes))
                    .font(Pine.figure(11))
                    .foregroundColor(Pine.letterSoft)
            }
        }
        .padding(.vertical, 14)
    }

    private var soonest: String {
        guard let opening = opening else { return "Booked out this fortnight" }
        let calendar = Calendar.current
        if calendar.isDateInToday(opening.day) { return "Soonest today \(opening.slot.label)" }
        if calendar.isDateInTomorrow(opening.day) { return "Soonest tomorrow \(opening.slot.label)" }
        return "Soonest \(Stamp.day(opening.day)) \(opening.slot.label)"
    }
}
