import Foundation
import Observation

/// Bridges a tap on a Pause & Reflect wait notification back into the UI.
/// The notification delegate sets `pendingProposal` from the background;
/// `MainTabView` observes it and reopens the reflect sheet pre-filled so the
/// user can re-decide (Buy now / Wait again / Add to pot).
@MainActor
@Observable
final class WaitReminderRouter {
    var pendingProposal: InterventionProposal?

    func consumePendingProposal() -> InterventionProposal? {
        let proposal = pendingProposal
        pendingProposal = nil
        return proposal
    }
}
