import SwiftUI

/// The shop itself: the week it keeps, where it is, and what people make of it. There is
/// no roster section here, because there is no roster — a two-chair shop on The Plaza
/// takes the booking, and whoever is free takes the chair.
struct ShopView: View {
    @State private var now = Date()
    @State private var readingPolicy = false

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Page {
            VStack(alignment: .leading, spacing: 8) {
                Overline(text: "\(Shop.city), \(Shop.region)")
                Text(Shop.name)
                    .font(Pine.display(28))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
                DoorLine(state: DoorState.now(now))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(Shop.tagline)
                    .font(Pine.copy(15, .semibold))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Shop.about)
                    .font(Pine.copy(15))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            rating
            hoursTable
            contact
            policy
        }
        .onReceive(tick) { now = $0 }
        .sheet(isPresented: $readingPolicy) {
            MidwoodPolicyScreen()
        }
    }

    private var rating: some View {
        Slab(raised: true) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String(format: "%.1f", Shop.ratingAverage))
                        .font(Pine.display(30))
                        .foregroundColor(Pine.parchment)
                    Text("\(Shop.ratingCount) reviews")
                        .font(Pine.figure(11))
                        .foregroundColor(Pine.letterSoft)
                }
                Rectangle().fill(Pine.hair).frame(width: Gap.hair, height: 46)
                VStack(alignment: .leading, spacing: 6) {
                    StarRow(value: Shop.ratingAverage)
                    Text("\(Shop.established). \(Shop.chairCount) chairs, five days, and a "
                         + "bench by the window.")
                        .font(Pine.copy(13))
                        .foregroundColor(Pine.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// All seven rows. Sunday and Monday shut and the early Saturday finish are the three
    /// things anybody opens this table for, so nothing is folded into a "Tue–Sat" line.
    private var hoursTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Overline(text: "Hours")
                .padding(.bottom, 10)
            ForEach(Array(Shop.weekOrdered.enumerated()), id: \.element.weekday) { index, day in
                if index > 0 { HairRule() }
                HStack {
                    Text(day.dayName)
                        .font(Pine.copy(15, isToday(day) ? .semibold : .regular))
                        .foregroundColor(day.isClosed ? Pine.letterSoft : Pine.letter)
                    Spacer(minLength: 8)
                    Text(day.rangeLabel)
                        .font(Pine.figure(13))
                        .foregroundColor(day.isClosed ? Pine.letterSoft.opacity(0.65)
                                                      : Pine.letterSoft)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, isToday(day) ? 10 : 0)
                .background(isToday(day) ? Pine.slab : Color.clear)
            }
        }
    }

    private func isToday(_ day: OpeningHours) -> Bool {
        Calendar.current.component(.weekday, from: now) == day.weekday
    }

    private var contact: some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline(text: "Find the shop")
            Text(Shop.addressLine)
                .font(Pine.copy(15))
                .foregroundColor(Pine.letter)
                .fixedSize(horizontal: false, vertical: true)
            Text(Shop.phone)
                .font(Pine.figure(15))
                .foregroundColor(Pine.parchment)
        }
    }

    private var policy: some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline(text: "Legal")
            GhostButton(title: "Privacy Policy") { readingPolicy = true }
        }
    }
}

struct StarRow: View {
    let value: Double

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                StarMark(filled: value >= Double(index) - 0.25)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(String(format: "%.1f", value)) out of 5")
    }
}
