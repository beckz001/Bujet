import Foundation

actor LocalGoalRepository: GoalRepository {
    private let fileURL = URL.documentsDirectory.appending(path: "goals.json")
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

    func fetchAll() async -> [Goal] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([Goal].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            return []
        }
    }

    func upsert(_ goal: Goal) async throws {
        var all = await fetchAll()
        if let idx = all.firstIndex(where: { $0.id == goal.id }) {
            all[idx] = goal
        } else {
            all.append(goal)
        }
        try await persist(all)
    }

    func delete(id: UUID) async throws {
        let kept = await fetchAll().filter { $0.id != id }
        try await persist(kept)
    }

    func contribute(amount: Double, to goalID: UUID) async throws -> Goal? {
        var all = await fetchAll()
        guard let idx = all.firstIndex(where: { $0.id == goalID }) else { return nil }
        all[idx].savedAmount += amount
        if all[idx].isComplete && all[idx].completedAt == nil {
            all[idx].completedAt = .now
        }
        try await persist(all)
        return all[idx]
    }

    private func persist(_ goals: [Goal]) async throws {
        let data = try encoder.encode(goals)
        try data.write(to: fileURL, options: .atomic)
    }
}
