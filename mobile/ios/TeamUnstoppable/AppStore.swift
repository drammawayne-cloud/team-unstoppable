import Foundation
import Combine
import UserNotifications

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var content = TeamContent.empty
    @Published private(set) var station = StationConfig.fallback
    @Published private(set) var saved: Set<String>
    @Published private(set) var refreshing = false
    @Published var contentStatus = "Saved content"
    @Published var stationStatus = "Using saved station settings"
    @Published private(set) var refreshedAt: Date?
    static let website = URL(string: "https://1teamunstoppable.com")!
    private let feedURL = URL(string: "https://raw.githubusercontent.com/drammawayne-cloud/team-unstoppable/main/mobile/content.json")!
    private let stationURL = URL(string: "https://raw.githubusercontent.com/drammawayne-cloud/highlife-radio/main/station.json")!
    private let defaults: UserDefaults
    private let session: URLSession
    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("team-content-v1.json")
    }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        saved = Set(defaults.stringArray(forKey: "saved-content") ?? [])
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 20
        session = URLSession(configuration: config)
        if let data = defaults.data(forKey: "station-config"),
           let decoded = try? JSONDecoder().decode(StationConfig.self, from: data).validated() { station = decoded }
        if let data = try? Data(contentsOf: cacheURL),
           let decoded = try? JSONDecoder().decode(TeamContent.self, from: data).validated() {
            content = decoded
        } else if let url = Bundle.main.url(forResource: "content", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(TeamContent.self, from: data).validated() {
            content = decoded
        }
    }
    func isSaved(_ kind: String, _ id: String) -> Bool { saved.contains("\(kind):\(id)") }
    func toggleSave(_ kind: String, _ id: String) {
        let key = "\(kind):\(id)"
        if saved.contains(key) { saved.remove(key) } else { saved.insert(key) }
        defaults.set(Array(saved).sorted(), forKey: "saved-content")
    }
    func clearSaved() {
        saved.removeAll()
        defaults.removeObject(forKey: "saved-content")
        defaults.removeObject(forKey: "booking-draft")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    private func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              SafeLink.https(response.url?.absoluteString) != nil, data.count <= 1_000_000 else { throw ContentError.invalidContent }
        return data
    }
    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        async let feed: Void = refreshFeed()
        async let radio: Void = refreshStation()
        _ = await (feed, radio)
    }
    private func refreshFeed() async {
        do {
            let data = try await get(feedURL)
            let decoded = try JSONDecoder().decode(TeamContent.self, from: data).validated()
            content = decoded
            try? data.write(to: cacheURL, options: .atomic)
            refreshedAt = Date()
            contentStatus = "Content up to date"
        } catch {
            contentStatus = "Offline or feed unavailable · showing saved content"
        }
    }
    private func refreshStation() async {
        do {
            let data = try await get(stationURL)
            station = try JSONDecoder().decode(StationConfig.self, from: data).validated()
            defaults.set(data, forKey: "station-config")
            stationStatus = "Synced with High Life Radio"
        } catch {
            stationStatus = "Using saved station settings · sync unavailable"
        }
    }
    func remind(_ event: TeamEvent) async throws -> String {
        guard let start = event.start, start > Date() else { throw ContentError.invalidContent }
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .sound]) else {
            return "Notifications are disabled. Enable them for Team Unstoppable in iPhone Settings."
        }
        let at = start.addingTimeInterval(-3600)
        guard at > Date() else { return "This event starts in less than an hour. A one-hour reminder cannot be scheduled." }
        let notification = UNMutableNotificationContent()
        notification.title = event.title
        notification.body = "Starts in one hour at \(event.venue)."
        notification.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: at.timeIntervalSinceNow, repeats: false)
        try await center.add(UNNotificationRequest(identifier: "event-\(event.id)", content: notification, trigger: trigger))
        return "Reminder set for one hour before the event."
    }
}
