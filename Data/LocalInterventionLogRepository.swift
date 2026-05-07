import Foundation

actor LocalInterventionLogRepository: InterventionLogRepository {
    private let fileURL = URL.documentsDirectory.appending(path: "intervention_log.json")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchAll() async -> [InterventionLog] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([InterventionLog].self, from: data)
                .sorted { $0.decidedAt > $1.decidedAt }
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            return []
        }
    }

    func fetchPendingWaits() async -> [InterventionLog] {
        await fetchAll().filter(\.isPendingWait)
    }

    func append(_ log: InterventionLog) async throws {
        var all = await fetchAll()
        all.append(log)
        try await persist(all)
    }

    func resolveWait(id: UUID, outcome: WaitOutcome) async throws {
        var all = await fetchAll()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].waitOutcome = outcome
        try await persist(all)
    }

    func moneySavedByPausing() async -> Double {
        await fetchAll()
            .filter { $0.waitOutcome == .skipped }
            .reduce(0) { $0 + $1.amount }
    }

    func moneySavedByPausing(in interval: DateInterval) async -> Double {
        await fetchAll()
            .filter { $0.waitOutcome == .skipped && interval.contains($0.decidedAt) }
            .reduce(0) { $0 + $1.amount }
    }

    #if DEBUG
    func clearAll() async throws {
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    #endif

    private func persist(_ logs: [InterventionLog]) async throws {
        let data = try encoder.encode(logs)
        try data.write(to: fileURL, options: .atomic)
    }
}
