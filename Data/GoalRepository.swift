import Foundation

protocol GoalRepository: Sendable {
    func fetchAll() async -> [Goal]
    func upsert(_ goal: Goal) async throws
    func delete(id: UUID) async throws
    func contribute(amount: Double, to goalID: UUID) async throws -> Goal?
}
