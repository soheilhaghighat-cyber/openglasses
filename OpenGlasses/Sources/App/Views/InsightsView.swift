import SwiftUI

/// On-device usage insights (Memory & Recall Phase 4): a private recap of how you've been
/// using the assistant — activity, top topics, top tools — computed locally from conversation
/// history. Read-only; nothing leaves the device.
struct InsightsView: View {
    @EnvironmentObject var appState: AppState

    @State private var days = 7
    @State private var report: InsightsReport?

    var body: some View {
        Form {
            Section {
                Picker("Window", selection: $days) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                .pickerStyle(.segmented)
                .onChange(of: days) { _, _ in refresh() }
            }

            if let report, report.totalTurns > 0 {
                Section("Activity") {
                    row("Exchanges", "\(report.userTurns)")
                    row("Total turns", "\(report.totalTurns)")
                }
                if !report.topTopics.isEmpty {
                    Section("Top topics") {
                        ForEach(report.topTopics, id: \.name) { topic in
                            row(topic.name, "\(topic.count)")
                        }
                    }
                }
                if !report.topTools.isEmpty {
                    Section("Most-used tools") {
                        ForEach(report.topTools, id: \.name) { tool in
                            row(tool.name, "\(tool.count)")
                        }
                    }
                }
                Section {
                    Button {
                        let text = InsightsService.shared.recapText(report, days: days)
                        Task { await appState.speechService.speak(text) }
                    } label: {
                        Label("Speak recap", systemImage: "speaker.wave.2.fill")
                    }
                }
            } else {
                ContentUnavailableView("No activity yet",
                                       systemImage: "chart.bar",
                                       description: Text("Have a few conversations and your usage recap will show up here."))
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        report = InsightsService.shared.report(days: days)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
