import SwiftUI

/// Two different things share this screen and they are never allowed to mix.
///
/// The top is the shop's public standing: 4.9 from 394 on its own listing, one figure for
/// the whole shop, and a way out to the words themselves. Nothing here breaks that average
/// up, quotes a review or names anybody — a two-chair shop has one standing, and this app
/// counted none of it. Everything below is the customer's own arithmetic on their own
/// visits, kept on this phone and sent nowhere.
struct ReviewsView: View {
    @EnvironmentObject private var chairbook: Chairbook

    @State private var scoring: Booking?

    var body: some View {
        Page {
            VStack(alignment: .leading, spacing: 7) {
                Overline(text: "The mirror")
                Text("Reviews")
                    .font(Pine.display(29))
                    .foregroundColor(Pine.letter)
            }

            standing
            toScore
            // Nothing scored yet means there is no record to print. A card claiming a
            // nought-star average would be an opinion nobody gave.
            if let average = chairbook.ownAverage { record(average) }
            listing
        }
        .sheet(item: $scoring) { visit in
            RateSheet(visit: visit, existing: chairbook.rating(for: visit))
                .environmentObject(chairbook)
        }
    }

    // MARK: The shop's standing

    private var standing: some View {
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
                    Text("The shop's standing on its public listing.")
                        .font(Pine.copy(13))
                        .foregroundColor(Pine.letterSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Scoring a visit

    /// Only chairs that have already been sat in are offered. Nothing can be scored in
    /// advance, and a chair still to come stays on the Visits screen where it belongs.
    private var toScore: some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline(text: "Rate your visit")

            if chairbook.past.isEmpty {
                Slab {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nothing to rate yet")
                            .font(Pine.copy(16, .semibold))
                            .foregroundColor(Pine.letter)
                        Text("Once a chair you booked is behind you it turns up here to "
                             + "score. Whatever you put on it stays on this phone.")
                            .font(Pine.copy(14))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if chairbook.unrated.isEmpty {
                Text("Every visit you have had is rated. Tap one below to change what you said.")
                    .font(Pine.copy(14))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(chairbook.unrated.enumerated()), id: \.element.id) { index, visit in
                        if index > 0 { HairRule() }
                        Button(action: { scoring = visit }) {
                            openRow(visit)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    /// A visit waiting for a score: what it was and when. No name — the chair was the
    /// shop's, and there is nothing else honest to put on this line.
    private func openRow(_ visit: Booking) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(visit.service?.name ?? "Visit")
                    .font(Pine.copy(15, .semibold))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stamp(visit))
                    .font(Pine.figure(11))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { _ in StarMark(filled: false) }
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 8)
            Text("Rate")
                .font(Pine.figure(12, .semibold))
                .foregroundColor(Pine.parchment)
        }
        .padding(.vertical, 14)
    }

    private func stamp(_ visit: Booking) -> String {
        "\(Stamp.day(visit.day)) · \(Shop.clock(visit.minutes))"
    }

    // MARK: Your own record

    private func record(_ average: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Overline(text: "Your own record")

            Slab {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(String(format: "%.1f", average))
                            .font(Pine.display(26))
                            .foregroundColor(Pine.parchment)
                        Text(countLine)
                            .font(Pine.figure(11))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Rectangle().fill(Pine.hair).frame(width: Gap.hair, height: 42)
                    VStack(alignment: .leading, spacing: 6) {
                        StarRow(value: average)
                        Text("Your average across the visits you scored.")
                            .font(Pine.copy(13))
                            .foregroundColor(Pine.letterSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(chairbook.ratedVisits.enumerated()), id: \.element.id) { index, scored in
                    if index > 0 { HairRule() }
                    Button(action: { scoring = scored.visit }) {
                        scoredRow(scored)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var countLine: String {
        let scored = chairbook.ratedVisits.count
        let total = chairbook.past.count
        if scored == total {
            return total == 1 ? "Your one visit, rated" : "All \(total) visits rated"
        }
        return "\(scored) of \(total) visits rated"
    }

    private func scoredRow(_ scored: RatedVisit) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { index in
                        StarMark(filled: index <= scored.rating.stars)
                    }
                }
                Text(scored.visit.service?.name ?? "Visit")
                    .font(Pine.copy(15, .semibold))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text(stamp(scored.visit))
                    .font(Pine.figure(11))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                if !scored.rating.note.isEmpty {
                    Text(scored.rating.note)
                        .font(Pine.copy(13))
                        .foregroundColor(Pine.letter)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 8)
            Text("Change")
                .font(Pine.figure(11, .semibold))
                .foregroundColor(Pine.parchment)
        }
        .padding(.vertical, 14)
    }

    // MARK: Out to the listing

    private var listing: some View {
        Slab {
            VStack(alignment: .leading, spacing: 10) {
                Overline(text: "Public reviews")
                Text("The \(Shop.ratingCount) reviews behind that "
                     + "\(String(format: "%.1f", Shop.ratingAverage)) were written on the "
                     + "shop's Google listing, and that is where they stay — this app keeps "
                     + "none of them. What you score here is yours, kept on this phone, and "
                     + "the shop never sees it.")
                    .font(Pine.copy(13))
                    .foregroundColor(Pine.letterSoft)
                    .fixedSize(horizontal: false, vertical: true)
                GhostButton(title: "Read them on Google") { LinkOut.open(LinkOut.listing) }
            }
        }
    }
}

/// One visit, one to five stars, and a line the customer writes for themselves. Small on
/// purpose: the shop never sees any of it, so there is nothing here to fill in for
/// anybody else's benefit.
struct RateSheet: View {
    let visit: Booking
    /// The existing score is handed in rather than read out of the book: an environment
    /// object is not available yet when a view's state is being set up.
    let existing: Rating?

    @EnvironmentObject private var chairbook: Chairbook
    @Environment(\.presentationMode) private var presentation

    @State private var stars: Int
    @State private var note: String

    /// A note somebody writes for themselves is a line, not an essay, and the row it ends
    /// up on is one panel wide.
    private let noteLimit = 140

    init(visit: Booking, existing: Rating?) {
        self.visit = visit
        self.existing = existing
        _stars = State(initialValue: existing?.stars ?? 0)
        _note = State(initialValue: existing?.note ?? "")
    }

    var body: some View {
        ZStack {
            Pine.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                bar
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        visitCard
                        starPicker
                        noteField
                        ParchmentButton(title: existing == nil ? "Save this rating"
                                                              : "Update this rating",
                                        isEnabled: stars > 0, action: save)
                    }
                    .padding(.horizontal, Gap.gutter)
                    .padding(.vertical, 20)
                    .frame(maxWidth: Gap.column, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var bar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Text("Rate your visit")
                    .font(Pine.display(19))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var visitCard: some View {
        Slab(raised: true) {
            VStack(alignment: .leading, spacing: 6) {
                Text(visit.service?.name ?? "Visit")
                    .font(Pine.copy(17, .semibold))
                    .foregroundColor(Pine.letter)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(Stamp.day(visit.day)) at \(Shop.clock(visit.minutes))")
                    .font(Pine.figure(13))
                    .foregroundColor(Pine.letterSoft)
            }
        }
    }

    private var starPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline(text: "How was it")
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { index in
                    Button(action: { stars = index }) {
                        StarMark(filled: index <= stars, size: 30)
                            // A Canvas over a clear background has no tap area of its own.
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer(minLength: 8)
                Text(stars == 0 ? "—" : "\(stars) of 5")
                    .font(Pine.figure(13, .semibold))
                    .foregroundColor(stars == 0 ? Pine.letterSoft : Pine.parchment)
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline(text: "A note — optional")
            TextField("For you only", text: $note)
                .font(Pine.copy(15))
                .foregroundColor(Pine.letter)
                .accentColor(Pine.parchment)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Pine.slab)
                .overlay(
                    RoundedRectangle(cornerRadius: Gap.corner)
                        .stroke(Pine.hair, lineWidth: Gap.hair)
                )
                .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
                // Held to a line as it is typed rather than refused on save, which would
                // throw away what had already been written.
                .onChange(of: note) { typed in
                    if typed.count > noteLimit { note = String(typed.prefix(noteLimit)) }
                }
            Text("Kept on this phone. Nothing is sent to the shop and nothing is published "
                 + "— to say something in public, use the shop's Google listing.")
                .font(Pine.copy(12))
                .foregroundColor(Pine.letterSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func save() {
        guard stars > 0 else { return }
        chairbook.rate(visit, stars: stars, note: note)
        presentation.wrappedValue.dismiss()
    }
}
