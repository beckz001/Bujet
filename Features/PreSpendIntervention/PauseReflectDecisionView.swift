import SwiftUI

struct PauseReflectDecisionView: View {
    @Bindable var flow: PreSpendInterventionFlow
    let decision: InterventionDecision

    @State private var isWaitMenuPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ImpactSummaryCard(impact: decision.impact)

                NarrativeCard(
                    narrative: decision.narrative,
                    suggestedAction: decision.suggestedAction
                )

                actionButtons
            }
            .padding(20)
        }
        .confirmationDialog(
            "When should we check back in?",
            isPresented: $isWaitMenuPresented,
            titleVisibility: .visible
        ) {
            ForEach(InterventionWaitDuration.allCases) { duration in
                Button(duration.displayName) {
                    Task { await flow.chooseWait(duration) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            actionButton(
                title: "Buy now",
                systemImage: "checkmark.circle",
                isHighlighted: decision.suggestedAction == .buyNow
            ) {
                Task { await flow.chooseBuyNow() }
            }

            actionButton(
                title: "Wait on it",
                systemImage: "moon.zzz",
                isHighlighted: decision.suggestedAction == .wait
            ) {
                isWaitMenuPresented = true
            }

            actionButton(
                title: "Add to Wishlist Pot",
                systemImage: "leaf",
                isHighlighted: decision.suggestedAction == .addToWishlistPot
            ) {
                Task { await flow.chooseAddToPot() }
            }
        }
        .disabled(flow.isRecording)
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        systemImage: String,
        isHighlighted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
                if isHighlighted {
                    Text("Suggested")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        if isHighlighted {
            button.buttonStyle(.borderedProminent).controlSize(.large)
        } else {
            button.buttonStyle(.bordered).controlSize(.large)
        }
    }
}

private struct ImpactSummaryCard: View {
    let impact: ImpactSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: impact.category.systemImage)
                    .font(.body)
                    .frame(width: 32, height: 32)
                    .background(impact.category.color.opacity(0.2), in: Circle())
                    .foregroundStyle(impact.category.color)
                Text(impact.category.displayName)
                    .font(.headline)
                Spacer()
                severityBadge
            }

            Text(headlineText)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            if let detail = detailText {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if impact.budgetLimit != nil {
                BudgetProgressBar(impact: impact)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .surfaceTile(cornerRadius: 20)
    }

    private var severityBadge: some View {
        let (label, color): (String, Color) = {
            switch impact.severity {
            case .withinBudget:     return ("On track", .green)
            case .approachingLimit: return ("Close to cap", .orange)
            case .overBudget:       return ("Over budget", .red)
            case .noBudget:         return ("No budget set", .secondary)
            }
        }()
        return Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var headlineText: String {
        let formatter = currencyFormatter(impact.currencyCode)
        let amount = formatter.string(from: NSNumber(value: impact.amount)) ?? ""
        switch impact.severity {
        case .overBudget:
            let pct = Int(impact.percentOverBudget ?? 0)
            return "Spending \(amount) would put you ~\(pct)% over your \(impact.category.displayName) budget."
        case .approachingLimit:
            let used = Int(impact.percentOfBudgetUsed ?? 0)
            return "Spending \(amount) would use \(used)% of your \(impact.category.displayName) budget."
        case .withinBudget:
            let used = Int(impact.percentOfBudgetUsed ?? 0)
            return "Spending \(amount) would use \(used)% of your \(impact.category.displayName) budget."
        case .noBudget:
            if let pct = impact.percentAboveBaseline, pct >= 5 {
                return "Spending \(amount) would put you \(Int(pct))% above your typical \(impact.category.displayName) month."
            }
            return "Spending \(amount) is in line with your typical \(impact.category.displayName) month."
        }
    }

    private var detailText: String? {
        let formatter = currencyFormatter(impact.currencyCode)
        let before = formatter.string(from: NSNumber(value: impact.monthSpendBefore)) ?? ""
        let after = formatter.string(from: NSNumber(value: impact.monthSpendAfter)) ?? ""
        return "This month: \(before) → \(after)"
    }

    private func currencyFormatter(_ code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f
    }
}

private struct BudgetProgressBar: View {
    let impact: ImpactSummary

    var body: some View {
        GeometryReader { proxy in
            let limit = impact.budgetLimit ?? 0
            let beforeFraction = limit > 0 ? min(1.0, impact.monthSpendBefore / limit) : 0
            let afterFraction = limit > 0 ? min(1.2, impact.monthSpendAfter / limit) : 0
            let visibleAfter = min(1.0, afterFraction)
            let overflow = max(0, afterFraction - 1.0)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppPalette.progressTrack)
                Capsule()
                    .fill(impact.category.color.opacity(0.4))
                    .frame(width: proxy.size.width * visibleAfter)
                Capsule()
                    .fill(impact.category.color)
                    .frame(width: proxy.size.width * beforeFraction)
                if overflow > 0 {
                    Capsule()
                        .fill(.red)
                        .frame(width: proxy.size.width * min(0.1, overflow))
                        .offset(x: proxy.size.width - proxy.size.width * min(0.1, overflow))
                }
            }
        }
        .frame(height: 10)
    }
}

private struct NarrativeCard: View {
    let narrative: String
    let suggestedAction: SuggestedAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Coach", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(narrative)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile(cornerRadius: 20)
    }
}
