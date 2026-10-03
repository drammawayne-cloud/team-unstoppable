import XCTest
@testable import UnstoppableCore

final class ContentTests: XCTestCase {
    func testHTTPSAccepted() { XCTAssertNotNil(SafeLink.https("https://1teamunstoppable.com")) }
    func testHTTPRejected() { XCTAssertNil(SafeLink.https("http://example.com/audio.mp3")) }
    func testJavaScriptRejected() { XCTAssertNil(SafeLink.https("javascript:alert(1)")) }
    func testCredentialsRejected() { XCTAssertNil(SafeLink.https("https://user:pass@example.com")) }
    func testMissingHostRejected() { XCTAssertNil(SafeLink.https("https:///")) }
    func testNilRejected() { XCTAssertNil(SafeLink.https(nil)) }
    func testFallbackStationSecure() throws { XCTAssertEqual(try StationConfig.fallback.validated().stationName, "High Life Radio") }
    func testInsecureStationRejected() {
        var station = StationConfig.fallback
        station.streamUrl = "http://insecure.test/audio.mp3"
        XCTAssertThrowsError(try station.validated())
    }
    func testEmptyFeedAllowed() { XCTAssertNoThrow(try TeamContent.empty.validated()) }
    func testUnknownSchemaRejected() {
        var feed = TeamContent.empty; feed.schemaVersion = 900
        XCTAssertThrowsError(try feed.validated())
    }
    func testDuplicateMembersRejected() {
        let member = Member(id: "a", name: "Test", role: "DJ", bio: "Test", genres: [], imageURL: nil, websiteURL: nil)
        var feed = TeamContent.empty; feed.members = [member, member]
        XCTAssertThrowsError(try feed.validated())
    }
    func testInitials() {
        let member = Member(id: "a", name: "Dramma Wayne", role: "DJ", bio: "", genres: [], imageURL: nil, websiteURL: nil)
        XCTAssertEqual(member.initials, "DW")
    }
    func testFractionalAndPlainISODates() {
        XCTAssertNotNil(AppDate.parse("2026-10-03T20:00:00Z"))
        XCTAssertNotNil(AppDate.parse("2026-10-03T20:00:00.123Z"))
        XCTAssertNotNil(AppDate.parse("2026-10-03T20:00:00-04:00"))
    }
    func testInvalidEventDateRejected() {
        var feed = TeamContent.empty
        feed.events = [event(start: "not-a-date")]
        XCTAssertThrowsError(try feed.validated())
    }
    func testEventEndBeforeStartRejected() {
        var feed = TeamContent.empty
        var value = event(start: "2026-10-04T20:00:00Z")
        value.endsAt = "2026-10-03T20:00:00Z"
        feed.events = [value]
        XCTAssertThrowsError(try feed.validated())
    }
    func testUpcomingIncludesOngoingEvent() {
        var value = event(start: "2026-10-03T20:00:00Z")
        value.endsAt = "2026-10-03T23:00:00Z"
        XCTAssertTrue(value.isUpcoming(at: AppDate.parse("2026-10-03T21:00:00Z")!))
        XCTAssertFalse(value.isUpcoming(at: AppDate.parse("2026-10-04T00:00:00Z")!))
    }
    func testMaliciousTicketRejected() {
        var value = event(start: "2026-10-03T20:00:00Z")
        value.ticketURL = "javascript:bad"
        var feed = TeamContent.empty; feed.events = [value]
        XCTAssertThrowsError(try feed.validated())
    }
    func testInsecureMixRejected() {
        var feed = TeamContent.empty
        feed.mixes = [Mix(id: "test", title: "Fixture", artist: "Test", genre: "Test", audioURL: "http://example.com/mix.mp3", imageURL: nil)]
        XCTAssertThrowsError(try feed.validated())
    }
    func testMetadataObjectAndArray() throws {
        let text = "{\"is_online\":true,\"now_playing\":{\"song\":{\"title\":\"Test\"},\"played_at\":1000,\"duration\":300}}"
        XCTAssertEqual(try RadioMetadata.decode(Data(text.utf8)).now_playing?.song?.title, "Test")
        XCTAssertEqual(try RadioMetadata.decode(Data("[\(text)]".utf8)).is_online, true)
        XCTAssertThrowsError(try RadioMetadata.decode(Data("[]".utf8)))
    }
    func testStaleMetadataNeverMarkedFresh() throws {
        let info = try RadioMetadata.decode(Data("{\"now_playing\":{\"played_at\":1000,\"duration\":300}}".utf8))
        XCTAssertEqual(info.now_playing?.isFresh(at: Date(timeIntervalSince1970: 1300)), true)
        XCTAssertEqual(info.now_playing?.isFresh(at: Date(timeIntervalSince1970: 5000)), false)
        XCTAssertEqual(info.now_playing?.isFresh(at: Date(timeIntervalSince1970: 0)), false)
    }
    private func event(start: String) -> TeamEvent {
        TeamEvent(id: "fixture-event", title: "Test fixture only", startsAt: start, endsAt: nil, venue: "Test", address: "", description: "Not published", ticketURL: nil, imageURL: nil)
    }
}
