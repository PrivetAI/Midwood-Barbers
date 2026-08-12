import Foundation
import Combine

/// A half hour in the day and how much of the shop is still free in it.
///
/// There is no roster in this build, so a slot cannot say "Ray at 2:30". What it can say
/// honestly is how many of the shop's two chairs stay clear for the whole run of the
/// service — which is the thing a customer actually wants to know.
struct ChairSlot: Identifiable, Equatable {
    let minutes: Int
    let chairsFree: Int

    var id: Int { minutes }
    var isFree: Bool { chairsFree > 0 }
    var label: String { Shop.clock(minutes) }
}

/// An appointment the customer holds. Kept on the device — this build sends nothing
/// anywhere, and the shop is called to confirm.
struct Booking: Identifiable, Codable, Equatable {
    let id: UUID
    var serviceId: String
    var day: Date
    var minutes: Int

    init(id: UUID = UUID(), serviceId: String, day: Date, minutes: Int) {
        self.id = id
        self.serviceId = serviceId
        self.day = day
        self.minutes = minutes
    }

    /// Read field by field with a default for each, so adding a property in a later
    /// version cannot make the whole saved list fail to decode and quietly wipe
    /// somebody's appointments. The synthesised decoder throws on a missing key.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        serviceId = try box.decodeIfPresent(String.self, forKey: .serviceId) ?? ""
        day = try box.decodeIfPresent(Date.self, forKey: .day) ?? Date()
        minutes = try box.decodeIfPresent(Int.self, forKey: .minutes) ?? 0
    }

    var service: Service? { Shop.service(serviceId) }

    /// How long the chair is actually held for. Falls back to a quarter hour if the
    /// service behind an old booking has since left the board.
    var runMinutes: Int { service?.minutes ?? 15 }

    /// The wall-clock moment, used to sort and to decide what is still to come.
    var start: Date {
        Calendar.current.date(bySettingHour: minutes / 60,
                              minute: minutes % 60,
                              second: 0,
                              of: day) ?? day
    }
}

/// What the customer made of a chair they have already sat in. Kept beside the bookings on
/// the same phone and shown to nobody: the shop's public reviews live on its own listing,
/// and the note especially is private to whoever wrote it.
struct Rating: Identifiable, Codable, Equatable {
    var bookingId: UUID
    var stars: Int
    var note: String
    var ratedOn: Date

    /// One rating per visit, so the booking it belongs to is the identity.
    var id: UUID { bookingId }

    init(bookingId: UUID, stars: Int, note: String, ratedOn: Date = Date()) {
        self.bookingId = bookingId
        self.stars = stars
        self.note = note
        self.ratedOn = ratedOn
    }

    /// Field by field with a default for each, the same way `Booking` reads — a property
    /// added in a later version must not throw the whole saved list away and take every
    /// score the customer has given with it.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        bookingId = try box.decodeIfPresent(UUID.self, forKey: .bookingId) ?? UUID()
        stars = try box.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        note = try box.decodeIfPresent(String.self, forKey: .note) ?? ""
        ratedOn = try box.decodeIfPresent(Date.self, forKey: .ratedOn) ?? Date()
    }
}

/// A visit and the score put on it, carried together. No name travels with it — the chair
/// was the shop's, so what is being scored is the visit and nothing narrower.
struct RatedVisit: Identifiable {
    let visit: Booking
    let rating: Rating

    var id: UUID { visit.id }
}

/// Chair occupancy that behaves like a real book: identical between launches, and moving
/// together across the room so a busy hour is a busy hour rather than two coin flips.
enum ChairLoad {
    /// The day is cut into quarter hours. The shortest thing on the board is a fifteen
    /// minute line-up, so anything coarser could not tell the truth about it.
    static let cell = 15

    /// FNV-1a. `String.hashValue` is seeded per process and would reshuffle the whole
    /// fortnight on every launch — the 2:30 chair taken this morning must still be taken
    /// this afternoon, or the app is lying about its own diary.
    static func digest(_ text: String) -> UInt64 {
        var value: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            value ^= UInt64(byte)
            value = value &* 0x100000001b3
        }
        return value
    }

    static func unit(_ text: String) -> Double {
        Double(digest(text) % 10_000) / 10_000
    }

    /// How busy the whole shop is in this quarter hour. Shop-wide on purpose and with no
    /// service in the seed: drawing each chair independently makes a two-chair shop look
    /// permanently half empty, because both chairs are only busy when p² says so.
    static func surge(dayKey: String, minutes: Int) -> Double {
        unit("surge|\(dayKey)|\(minutes)")
    }

    /// Whether one chair is busy in one quarter hour. The shop-wide pressure sets the
    /// tide; the per-chair draw decides which chair goes first.
    ///
    /// The service is deliberately not in the seed. There is one diary, and a quarter hour
    /// that is busy is busy whatever the customer came in for — seeding per service let a
    /// 75-minute sit be free in an hour where a 15-minute line-up was taken, which cannot
    /// happen in a real book. Scarcity comes from the run length instead, below.
    static func isTaken(dayKey: String, chair: Int, minutes: Int) -> Bool {
        let pressure = surge(dayKey: dayKey, minutes: minutes)
        let personal = unit("chair|\(dayKey)|\(chair)|\(minutes)")
        // Late afternoon fills first; the first hour after opening stays clear longest.
        let span = max(1, Shop.latestClose - Shop.earliestOpen)
        let timeOfDay = Double(minutes - Shop.earliestOpen) / Double(span)
        let load = 0.14 + pressure * 0.34 + timeOfDay * 0.18
        return personal < load
    }
}

final class Chairbook: ObservableObject {
    @Published private(set) var bookings: [Booking] = []
    @Published private(set) var ratings: [Rating] = []

    private let storageKey = "midwood.bookings.v1"
    private let ratingsKey = "midwood.ratings.v1"

    init() {
        if let raw = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Booking].self, from: raw) {
            bookings = decoded
        }
        if let raw = UserDefaults.standard.data(forKey: ratingsKey),
           let decoded = try? JSONDecoder().decode([Rating].self, from: raw) {
            ratings = decoded
        }
    }

    // MARK: Availability

        /// The string every occupancy hash is seeded from, so it must be stable whatever
    /// the phone's language and calendar are set to.
    static let keyFormatter = Fixed.formatter("yyyy-MM-dd", posix: true)

static func dayKey(_ day: Date) -> String {
        keyFormatter.string(from: day)
    }

    /// Every half hour the shop is open on this day, with the number of chairs that stay
    /// clear for the service's whole run. A chair that frees up halfway through a Cut &
    /// Beard is no use to anybody, so partial runs do not count — which is exactly why a
    /// 75-minute sit is genuinely scarcer here than a 15-minute line-up.
    func slots(on day: Date, service: Service) -> [ChairSlot] {
        let weekday = Calendar.current.component(.weekday, from: day)
        let hours = Shop.hours(for: weekday)
        guard let opens = hours.opensAt, let closes = hours.closesAt else { return [] }

        let key = Chairbook.dayKey(day)
        // A time that has already gone by is not a time anybody can take. On today's
        // column the day starts at the next half hour, the same rule the "soonest" line
        // on the board goes by — otherwise the board offers a ten o'clock chair at four.
        let calendar = Calendar.current
        let passed: Int
        if calendar.isDateInToday(day) {
            let now = Date()
            passed = calendar.component(.hour, from: now) * 60
                + calendar.component(.minute, from: now)
        } else {
            passed = -1
        }

        var result: [ChairSlot] = []
        var start = opens

        while start + service.minutes <= closes {
            guard start > passed else {
                start += 30
                continue
            }

            var free = 0
            for chair in 0..<Shop.chairCount {
                var minute = start
                var clear = true
                while minute < start + service.minutes {
                    if ChairLoad.isTaken(dayKey: key, chair: chair, minutes: minute) {
                        clear = false
                        break
                    }
                    minute += ChairLoad.cell
                }
                if clear { free += 1 }
            }

            // Whatever the customer is already holding takes a chair out of the room too.
            let held = heldOverlaps(day: day, from: start, to: start + service.minutes)
            result.append(ChairSlot(minutes: start, chairsFree: max(0, free - held)))
            start += 30
        }
        return result
    }

    /// The soonest the shop can actually take this service inside the next fortnight, or
    /// nil if it is booked out that far.
    func nextOpening(for service: Service) -> (day: Date, slot: ChairSlot)? {
        let calendar = Calendar.current
        let now = Date()
        let nowMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            for slot in slots(on: day, service: service) where slot.isFree {
                // A time that has already gone by today is not an opening.
                if offset == 0 && slot.minutes <= nowMinutes { continue }
                return (day, slot)
            }
        }
        return nil
    }

    /// The first day inside the fortnight the shop can still take somebody. Booking opens
    /// here rather than on today, so a customer who picks the app up on a Sunday — or at
    /// ten to seven on a Friday — is not dropped onto a column with nothing left in it.
    static func firstOpenDay() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let nowMinutes = calendar.component(.hour, from: now) * 60
            + calendar.component(.minute, from: now)

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard let closes = Shop.hours(for: weekday).closesAt else { continue }
            // Today only counts if enough of it is left for the shortest thing on the board.
            if offset == 0 && nowMinutes + 15 > closes { continue }
            return day
        }
        return now
    }

    // MARK: Bookings

    /// How many chairs the customer's own bookings take out of a window.
    private func heldOverlaps(day: Date, from: Int, to: Int) -> Int {
        let key = Chairbook.dayKey(day)
        return bookings.filter { held in
            guard Chairbook.dayKey(held.day) == key else { return false }
            return from < held.minutes + held.runMinutes && to > held.minutes
        }.count
    }

    func book(service: Service, day: Date, minutes: Int) {
        bookings.append(Booking(serviceId: service.id, day: day, minutes: minutes))
        persist()
    }

    func cancel(_ booking: Booking) {
        bookings.removeAll { $0.id == booking.id }
        // The score goes with it. A rating whose visit has gone can never be shown or
        // changed again, and left in storage it would sit in the customer's own average
        // for ever with nothing behind it.
        ratings.removeAll { $0.bookingId == booking.id }
        persist()
        persistRatings()
    }

    var upcoming: [Booking] {
        bookings.filter { $0.start >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.start < $1.start }
    }

    var past: [Booking] {
        bookings.filter { $0.start < Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.start > $1.start }
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(bookings) {
            UserDefaults.standard.set(raw, forKey: storageKey)
        }
    }

    // MARK: What you made of it

    func rating(for booking: Booking) -> Rating? {
        ratings.first { $0.bookingId == booking.id }
    }

    /// One score per visit, replaced rather than added to — going back to change your mind
    /// about a chair should not leave two opinions of it in the average.
    func rate(_ booking: Booking, stars: Int, note: String) {
        let clamped = min(5, max(1, stars))
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        ratings.removeAll { $0.bookingId == booking.id }
        ratings.append(Rating(bookingId: booking.id, stars: clamped, note: trimmed))
        persistRatings()
    }

    /// Visits that have been and carry no score yet — what the Reviews screen offers. A
    /// chair still to come is not on this list; there is nothing to say about it.
    var unrated: [Booking] { past.filter { rating(for: $0) == nil } }

    /// The scored ones, newest first because `past` already is. Built from `past` rather
    /// than from the ratings, so a score whose booking has gone simply never appears.
    var ratedVisits: [RatedVisit] {
        past.compactMap { visit in
            rating(for: visit).map { RatedVisit(visit: visit, rating: $0) }
        }
    }

    /// The customer's own average, or nil until they have scored something. Nought stars is
    /// an opinion nobody gave, and the divisor would be zero.
    var ownAverage: Double? {
        let scored = ratedVisits
        guard !scored.isEmpty else { return nil }
        return Double(scored.reduce(0) { $0 + $1.rating.stars }) / Double(scored.count)
    }

    // MARK: The history, totalled

    /// What the visits behind you came to, at today's board. A service that has since left
    /// the board counts as nothing rather than bringing the sum down with it.
    var spentCents: Int {
        past.compactMap { $0.service?.priceCents }.reduce(0, +)
    }

    /// The usual number of days from one visit to the next. Nil below two visits: there is
    /// no gap between a single visit and nothing, and the divisor would be zero.
    var averageGapDays: Int? {
        let calendar = Calendar.current
        let days = past.map { calendar.startOfDay(for: $0.start) }.sorted()
        guard days.count > 1 else { return nil }
        let gaps = zip(days, days.dropFirst()).compactMap {
            calendar.dateComponents([.day], from: $0, to: $1).day
        }
        guard !gaps.isEmpty else { return nil }
        return max(0, Int((Double(gaps.reduce(0, +)) / Double(gaps.count)).rounded()))
    }

    private func persistRatings() {
        if let raw = try? JSONEncoder().encode(ratings) {
            UserDefaults.standard.set(raw, forKey: ratingsKey)
        }
    }
}

/// Open, closing soon, or shut — worked out from the shop's own hours. With two days off
/// a week this has real work to do: "closed, opens Tuesday 10 AM" is the common answer,
/// not the edge case.
enum DoorState {
    case open(until: Int)
    case closingSoon(until: Int)
    case shut(day: String?, at: Int?)

    static func now(_ moment: Date = Date()) -> DoorState {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: moment)
        let minutes = calendar.component(.hour, from: moment) * 60
            + calendar.component(.minute, from: moment)
        let today = Shop.hours(for: weekday)

        if let opens = today.opensAt, let closes = today.closesAt,
           minutes >= opens, minutes < closes {
            return closes - minutes <= 60 ? .closingSoon(until: closes) : .open(until: closes)
        }

        // Walk forward to the next day the door opens, today included if it is still early.
        for offset in 0..<8 {
            let day = (weekday - 1 + offset) % 7 + 1
            guard let opens = Shop.hours(for: day).opensAt else { continue }
            if offset == 0 {
                if minutes < opens { return .shut(day: nil, at: opens) }
                continue
            }
            let label = offset == 1 ? "tomorrow" : Shop.weekdayNames[day]
            return .shut(day: label, at: opens)
        }
        return .shut(day: nil, at: nil)
    }

    var isOpen: Bool {
        if case .shut = self { return false }
        return true
    }

    var label: String {
        switch self {
        case .open(let until):
            return "OPEN UNTIL \(Shop.clock(until).uppercased())"
        case .closingSoon(let until):
            return "CLOSING AT \(Shop.clock(until).uppercased())"
        case .shut(let day, let at):
            guard let at = at else { return "CLOSED" }
            guard let day = day else { return "CLOSED · OPENS \(Shop.clock(at).uppercased())" }
            return "CLOSED · OPENS \(day.uppercased()) \(Shop.clock(at).uppercased())"
        }
    }
}

/// Built once and pinned to English and Gregorian — these apps ship in English only,
/// and a day strip that changed language with the phone would not match the shop's sign.
enum Stamp {
    private static let fullFace = Fixed.formatter("EEE d MMM")
    private static let shortFace = Fixed.formatter("EEE")
    private static let figureFace = Fixed.formatter("d")
    private static let longFace = Fixed.formatter("EEEE")

    static func day(_ date: Date) -> String {
        fullFace.string(from: date)
    }

    static func weekday(_ date: Date) -> String {
        shortFace.string(from: date)
    }

    static func dayNumber(_ date: Date) -> String {
        figureFace.string(from: date)
    }

    static func weekdayFull(_ date: Date) -> String {
        longFace.string(from: date)
    }
}

/// Date formatting is pinned rather than left to the device. `DateFormatter` otherwise
/// follows the phone's locale and calendar, which would translate the day strip and — far
/// worse — change the day key the occupancy hash is seeded from, reshuffling the whole
/// fortnight for anyone whose phone is not on English and Gregorian.
enum Fixed {
    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()

    static func formatter(_ format: String, posix: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: posix ? "en_US_POSIX" : "en_US")
        formatter.calendar = Fixed.gregorian
        formatter.dateFormat = format
        return formatter
    }
}
