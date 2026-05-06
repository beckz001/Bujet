import Foundation

protocol InterventionLogRepository: Sendable {
    func fetchAll() async -> [InterventionLog]
    func append(_ log: InterventionLog) async throws
    func markDeclinedAfterWait(id: UUID) async throws
    func moneySavedByPausing() async -> Double
}
