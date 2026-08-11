import SwiftUI

/// Booking shows the day as a column: every half hour top to bottom, the taken ones
/// struck through. Scattering the free times into a cloud of chips hides the shape of the
/// day, and "come at ten instead" stops being an obvious move.
///
/// There is no barber picker here, and no empty space where one used to be. Midwood books
/// to the shop, so the only choice on this screen is a day and a time — and the count of
/// open chairs is what a name would otherwise have told you.
struct BookingSheet: View {
    let service: Service

    @EnvironmentObject private var chairbook: Chairbook
    @Environment(\.presentationMode) private var presentation

    @State private var day = Chairbook.firstOpenDay()
    @State private var confirmed: ChairSlot?

    var body: some View {
        ZStack {
            Pine.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                bar
                if confirmed == nil { picker } else { receipt }
            }
        }
    }

    private var bar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(Pine.display(19))
                        .foregroundColor(Pine.letter)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Shop.money(service.priceCents)) · \(Shop.duration(service.minutes))")
                        .font(Pine.figure(12))
                        .foregroundColor(Pine.letterSoft)
                }
                Spacer(minLength: 8)
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
        }
    }

    // MARK: Picking

    private var picker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                dayStrip
                column
            }
            .padding(.horizontal, Gap.gutter)
            .padding(.vertical, 18)
            .frame(maxWidth: Gap.column, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var days: [Date] {
        (0..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }
    }

    /// Sunday and Monday are drawn dimmed and struck, and cannot be tapped. Two days off
    /// a week is a fifth of this strip, so leaving them live and then apologising in the
    /// column below would waste a tap every time.
    private var dayStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Overline(text: "Day")
                Spacer()
                Overline(text: "Closed Sun & Mon", tint: Pine.letterSoft.opacity(0.8))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(days, id: \.timeIntervalSince1970) { candidate in
                        let shut = !Shop.isOpenDay(candidate)
                        Button(action: { if !shut { day = candidate } }) {
                            VStack(spacing: 4) {
                                Text(Stamp.weekday(candidate).uppercased())
                                    .font(Pine.figure(10, .semibold))
                                    .tracking(0.8)
                                Text(Stamp.dayNumber(candidate))
                                    .font(Pine.figure(16, .bold))
                                    .strikethrough(shut, color: Pine.letterSoft.opacity(0.5))
                            }
                            .foregroundColor(dayTint(candidate, shut: shut))
                            .frame(width: 52, height: 56)
                            .background(isChosen(candidate) ? Pine.parchment : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: Gap.corner)
                                    .stroke(strokeTint(candidate, shut: shut), lineWidth: Gap.hair)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(shut)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func isChosen(_ candidate: Date) -> Bool {
        Calendar.current.isDate(candidate, inSameDayAs: day)
    }

    private func dayTint(_ candidate: Date, shut: Bool) -> Color {
        if isChosen(candidate) { return Pine.onParchment }
        return shut ? Pine.letterSoft.opacity(0.4) : Pine.letter
    }

    private func strokeTint(_ candidate: Date, shut: Bool) -> Color {
        if isChosen(candidate) { return Pine.parchment }
        return shut ? Pine.hair.opacity(0.5) : Pine.hair
    }

    private var slots: [ChairSlot] { chairbook.slots(on: day, service: service) }

    private var column: some View {
        let open = slots.filter { $0.isFree }.count

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Overline(text: Stamp.weekdayFull(day))
                Spacer()
                Text("\(open) free")
                    .font(Pine.figure(11, .semibold))
                    .foregroundColor(open == 0 ? Pine.letterSoft : Pine.parchment)
            }
            .padding(.bottom, 8)

            if slots.isEmpty {
                Text("The shop is shut on \(Stamp.weekdayFull(day)).")
                    .font(Pine.copy(14))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 14)
            } else {
                ForEach(slots) { slot in
                    Button(action: { take(slot) }) {
                        HStack(spacing: 12) {
                            Text(slot.label)
                                .font(Pine.figure(14, slot.isFree ? .semibold : .regular))
                                .foregroundColor(slot.isFree ? Pine.letter
                                                             : Pine.letterSoft.opacity(0.7))
                                .strikethrough(!slot.isFree, color: Pine.letterSoft.opacity(0.6))
                                .frame(width: 84, alignment: .leading)

                            Text(slot.isFree ? Shop.chairPhrase(slot.chairsFree) : "taken")
                                .font(Pine.figure(12))
                                .foregroundColor(Pine.letterSoft.opacity(slot.isFree ? 1 : 0.7))

                            Spacer(minLength: 4)

                            if slot.isFree {
                                Text("Take")
                                    .font(Pine.figure(12, .semibold))
                                    .foregroundColor(Pine.parchment)
                            }
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!slot.isFree)

                    HairRule()
                }

                if open == 0 {
                    Text("Both chairs are spoken for all day. Try another date on the strip.")
                        .font(Pine.copy(13))
                        .foregroundColor(Pine.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                }
            }
        }
    }

    private func take(_ slot: ChairSlot) {
        guard slot.isFree else { return }
        chairbook.book(service: service, day: day, minutes: slot.minutes)
        confirmed = slot
    }

    // MARK: Confirmation

    private var receipt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Slab(raised: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        Overline(text: "Held on this phone", tint: Pine.parchment)
                        Text("\(Stamp.day(day)) at \(confirmed.map { Shop.clock($0.minutes) } ?? "")")
                            .font(Pine.display(23))
                            .foregroundColor(Pine.letter)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(service.name) · \(Shop.money(service.priceCents)) · \(Shop.duration(service.minutes))")
                            .font(Pine.copy(15))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        HairRule()
                        Text("This build keeps the book on your phone. Nothing has reached "
                             + "the shop — call \(Shop.phone) to confirm the chair.")
                            .font(Pine.copy(13))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ParchmentButton(title: "Done") { presentation.wrappedValue.dismiss() }
            }
            .padding(.horizontal, Gap.gutter)
            .padding(.vertical, 20)
            .frame(maxWidth: Gap.column, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
