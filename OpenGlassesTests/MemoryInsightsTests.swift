import XCTest
@testable import OpenGlasses

/// Headless tests for Memory & Recall Phase 4 — `InsightsService` event-mapping and recap
/// formatting. The aggregation itself is covered by `MemoryRecallCoreTests`; here we check the
/// conversation-history → events mapping (pure) and the spoken recap text.
@MainActor
final class MemoryInsightsTests: XCTestCase {

    private func thread(_ messages: [(String, String)]) -> ConversationThread {
        var t = ConversationThread(mode: "direct", title: "T")
        t.messages = messages.map { ConversationMessage(role: $0.0, content: $0.1) }
        return t
    }

    func testBuildEventsMapsEveryMessage() {
        let threads = [
            thread([("user", "tell me about the museum app"), ("assistant", "sure")]),
            thread([("user", "remind me about the museum launch")]),
        ]
        let events = InsightsService.buildEvents(from: threads)
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.filter { $0.role == "user" }.count, 2)
        XCTAssertTrue(events.allSatisfy { $0.toolNames.isEmpty })
        XCTAssertEqual(events.first?.text, "tell me about the museum app")
    }

    func testReportFromBuiltEventsSurfacesTopics() {
        let threads = [thread([("user", "the museum proposal"), ("user", "museum budget")])]
        let events = InsightsService.buildEvents(from: threads)
        let report = InsightsAggregator.aggregate(events, since: Date().addingTimeInterval(-3600), now: Date())
        XCTAssertEqual(report.userTurns, 2)
        XCTAssertEqual(report.topTopics.first?.name, "museum")
    }

    func testRecapTextReadsNaturally() {
        let report = InsightsReport(
            windowStart: Date(), windowEnd: Date(), totalTurns: 8, userTurns: 4,
            topTools: [.init(name: "reminder", count: 3)],
            topTopics: [.init(name: "museum", count: 4), .init(name: "budget", count: 2)],
            summary: "x"
        )
        let recap = InsightsService.shared.recapText(report, days: 7)
        XCTAssertTrue(recap.contains("4 exchanges"))
        XCTAssertTrue(recap.contains("museum"))
        XCTAssertTrue(recap.contains("reminder"))
    }

    func testRecapTextEmpty() {
        let empty = InsightsReport(windowStart: Date(), windowEnd: Date(), totalTurns: 0,
                                   userTurns: 0, topTools: [], topTopics: [], summary: "")
        XCTAssertTrue(InsightsService.shared.recapText(empty, days: 7).lowercased().contains("nothing to report"))
    }
}
