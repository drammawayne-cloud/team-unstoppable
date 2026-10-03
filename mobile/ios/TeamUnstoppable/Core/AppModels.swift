import Foundation

public enum ContentError: Error, LocalizedError {
    case invalidURL, invalidContent
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "This link is not a secure, supported address."
        case .invalidContent: return "The content feed could not be verified. Saved content is still available."
        }
    }
}

public enum SafeLink {
    public static func https(_ value: String?) -> URL? {
        guard let value, let parts = URLComponents(string: value),
              parts.scheme?.lowercased() == "https", let host = parts.host,
              !host.isEmpty, parts.user == nil, parts.password == nil,
              let url = parts.url else { return nil }
        return url
    }
}

public enum AppDate {
    public static func parse(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

public struct StationConfig: Codable, Equatable {
    public var streamUrl: String
    public var nowPlayingUrl: String
    public var stationName: String
    public func validated() throws -> StationConfig {
        guard SafeLink.https(streamUrl) != nil, SafeLink.https(nowPlayingUrl) != nil,
              !stationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ContentError.invalidURL }
        return self
    }
    public static let fallback = StationConfig(
        streamUrl: "https://richrow-radio.129-213-164-255.sslip.io/listen/rich_row_radio/radio.mp3",
        nowPlayingUrl: "https://richrow-radio.129-213-164-255.sslip.io/api/nowplaying/rich_row_radio",
        stationName: "High Life Radio")
}

public struct Member: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var role: String
    public var bio: String
    public var genres: [String]
    public var imageURL: String?
    public var websiteURL: String?
    public var initials: String { name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined() }
}
public struct TeamEvent: Codable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var startsAt: String
    public var endsAt: String?
    public var venue: String
    public var address: String
    public var description: String
    public var ticketURL: String?
    public var imageURL: String?
    public var start: Date? { AppDate.parse(startsAt) }
    public var end: Date? { endsAt.flatMap(AppDate.parse) }
    public func isUpcoming(at date: Date = Date()) -> Bool { (end ?? start ?? .distantPast) >= date }
}
public struct Mix: Codable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var artist: String
    public var genre: String
    public var audioURL: String
    public var imageURL: String?
}
public struct TeamVideo: Codable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var url: String
}
public struct TeamContent: Codable, Equatable {
    public var schemaVersion: Int
    public var members: [Member]
    public var events: [TeamEvent]
    public var mixes: [Mix]
    public var videos: [TeamVideo]
    public static let empty = TeamContent(schemaVersion: 1, members: [], events: [], mixes: [], videos: [])
    public func validated() throws -> TeamContent {
        func validIDs<T: Identifiable>(_ values: [T]) -> Bool where T.ID == String {
            values.allSatisfy { !$0.id.isEmpty } && Set(values.map(\.id)).count == values.count
        }
        func secureOptional(_ value: String?) -> Bool { value == nil || SafeLink.https(value) != nil }
        guard schemaVersion == 1, members.count <= 500, events.count <= 2000, mixes.count <= 2000,
              videos.count <= 2000, validIDs(members), validIDs(events), validIDs(mixes), validIDs(videos),
              members.allSatisfy({ !$0.name.isEmpty && secureOptional($0.imageURL) && secureOptional($0.websiteURL) }),
              events.allSatisfy({ !$0.title.isEmpty && $0.start != nil && ($0.endsAt == nil || $0.end != nil) && ($0.end == nil || $0.end! >= $0.start!) && secureOptional($0.ticketURL) && secureOptional($0.imageURL) }),
              mixes.allSatisfy({ !$0.title.isEmpty && SafeLink.https($0.audioURL) != nil && secureOptional($0.imageURL) }),
              videos.allSatisfy({ !$0.title.isEmpty && SafeLink.https($0.url) != nil }) else { throw ContentError.invalidContent }
        return self
    }
}

public struct RadioSong: Decodable {
    public var title: String?
    public var artist: String?
    public var text: String?
}
public struct RadioTrack: Decodable {
    public var song: RadioSong?
    public var played_at: Double?
    public var duration: Double?
    public func isFresh(at now: Date = Date()) -> Bool {
        guard let played_at, played_at <= now.timeIntervalSince1970 + 60 else { return false }
        return now.timeIntervalSince1970 <= played_at + max(duration ?? 0, 300) + 180
    }
}
public struct RadioMetadata: Decodable {
    public struct Live: Decodable { public var is_live: Bool?; public var streamer_name: String? }
    public var is_online: Bool?
    public var now_playing: RadioTrack?
    public var live: Live?
    public static func decode(_ data: Data) throws -> RadioMetadata {
        let decoder = JSONDecoder()
        if let single = try? decoder.decode(RadioMetadata.self, from: data) { return single }
        guard let first = try decoder.decode([RadioMetadata].self, from: data).first else { throw ContentError.invalidContent }
        return first
    }
}
