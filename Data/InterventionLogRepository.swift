import Foundation

protocol InterventionLogRepository: Sendable {
    func fetchAll() async -> [InterventionLog]
    func fetchPendingWaits() async -> [InterventionLog]
    func append(_ log: InterventionLog) async throws
    func resolveWait(id: UUID, outcome: WaitOutcome) async throws
    func moneySavedByPausing() async -> Double
}
