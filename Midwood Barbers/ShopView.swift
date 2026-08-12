import SwiftUI
import MapKit

/// The one pin on the shop's map. `Map` wants a collection of identified items even where
/// the collection is a single shop that has not moved since 2019.
struct ShopPin: Identifiable {
    let id = "shop"
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: Shop.latitude, longitude: Shop.longitude)
    }
}

/// The shop itself: the week it keeps, where it is, and what people make of it. There is
/// no roster section here, because there is no roster — a two-chair shop on The Plaza
/// takes the booking, and whoever is free takes the chair.
struct ShopView: View {
    @State private var now = Date()
    @State private var readingPolicy = false

    /// A fixed window on a fixed shop. The map never moves and never follows the phone —
    /// nothing on this screen asks where anybody is, so the app carries no location
    /// permission and no key for one.
    @State private var window = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: Shop.latitude, longitude: Shop.longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004))

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

            map

            // Side by side, because they are the two things somebody standing on The Plaza
            // with this open actually wants: the door, or the shop's phone. Both hand off
            // to an app that does the job properly rather than a worse copy of it in here.
            HStack(spacing: 10) {
                GhostButton(title: "Directions") { LinkOut.open(LinkOut.directions) }
                GhostButton(title: "Call") { LinkOut.open(LinkOut.call) }
            }
        }
    }

    /// A still picture of the corner, in the app's own panel chrome. Interaction is off in
    /// both directions — the map takes no gestures and swallows no taps, so it cannot eat
    /// a scroll meant for the screen. The buttons under it open the phone's own maps, which
    /// does the panning far better than a 170pt window ever would.
    private var map: some View {
        Map(coordinateRegion: $window,
            interactionModes: [],
            annotationItems: [ShopPin()]) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                ZStack {
                    Circle()
                        .fill(Pine.parchment)
                        .frame(width: 13, height: 13)
                    Circle()
                        .stroke(Pine.parchment.opacity(0.5), lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
        }
        .frame(height: 170)
        .allowsHitTesting(false)
        .overlay(
            RoundedRectangle(cornerRadius: Gap.corner)
                .stroke(Pine.edge, lineWidth: Gap.hair)
        )
        .clipShape(RoundedRectangle(cornerRadius: Gap.corner))
        .accessibilityElement()
        .accessibilityLabel("Map of \(Shop.name), \(Shop.addressLine)")
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
