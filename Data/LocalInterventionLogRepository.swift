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

    func append(_ log: InterventionLog) async throws {
        var all = await fetchAll()
        all.append(log)
        try await persist(all)
    }

    func markDeclinedAfterWait(id: UUID) async throws {
        var all = await fetchAll()
        guard let idx = all.firstIndex(where: { $0.id == id }) else { return }
        all[idx].didDeclineAfterWait = true
        try await persist(all)
    }

    func moneySavedByPausing() async -> Double {
        await fetchAll()
            .filter { $0.didDeclineAfterWait }
            .reduce(0) { $0 + $1.amount }
    }

    private func persist(_ logs: [InterventionLog]) async throws {
        let data = try encoder.encode(logs)
        try data.write(to: fileURL, options: .atomic)
    }
}
