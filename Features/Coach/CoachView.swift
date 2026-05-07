import SwiftUI

struct CoachView: View {
    let viewModel: CoachViewModel
    let makePotEditorViewModel: (@escaping () -> Void) -> PotEditorViewModel
    let makePotContributionViewModel: (Goal, @escaping () -> Void) -> PotContributionViewModel
    let onTransactionsChanged: () -> Void

    @State private var presentedPotEditor: PotEditorViewModel?
    @State private var presentedContribution: PotContributionViewModel?

    #if DEBUG
    @State private var showingResetSavedAlert = false
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SavedByPausingCard(
                    amount: viewModel.moneySavedByPausing,
                    currencyCode: viewModel.currencyCode
                )

                if !viewModel.pendingWaits.isEmpty {
                    pendingWaitsSection
                }

                insightsSection

                potsSection

                #if DEBUG
                debugResetButton
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppPalette.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Coach")
                    .font(.custom("InstrumentSerif-Italic", size: 34))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedPotEditor = makePotEditorViewModel {
                        Task { await viewModel.refresh() }
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New pot")
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .sheet(item: $presentedPotEditor) { vm in
            PotEditorSheet(viewModel: vm)
        }
        .sheet(item: $presentedContribution) { vm in
            PotContributionSheet(viewModel: vm)
        }
    }

    @ViewBuilder
    private var pendingWaitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Decisions to resolve")
                .font(.system(.subheadline, design: .serif))

            VStack(spacing: 12) {
                ForEach(viewModel.pendingWaits) { log in
                    PendingWaitCard(log: log) { outcome in
                        Task {
                            await viewModel.resolveWait(log, as: outcome)
                            if outcome == .purchased {
                                onTransactionsChanged()
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.goToPreviousWeek() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous week")

                ZStack {
                    Text(viewModel.weekRangeLabel)
                        .font(.system(.title3, design: .serif))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if viewModel.isLoadingInsights {
                        HStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    Task { await viewModel.goToNextWeek() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .opacity(viewModel.canGoToNextWeek ? 1 : 0.3)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canGoToNextWeek)
                .accessibilityLabel("Next week")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .surfaceTile()

            if viewModel.insights.isEmpty && !viewModel.isLoadingInsights {
                EmptyInsightsCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
    }

    #if DEBUG
    @ViewBuilder
    private var debugResetButton: some View {
        Button(
            "Reset saved-by-pausing",
            systemImage: "arrow.counterclockwise",
            role: .destructive
        ) {
            showingResetSavedAlert = true
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
        .alert("Reset saved-by-pausing?", isPresented: $showingResetSavedAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task { await viewModel.resetInterventionLog() }
            }
        } message: {
            Text("Clears all wait decisions and resets the saved-by-pausing total to zero. Pending waits will also disappear.")
        }
    }
    #endif

    @ViewBuilder
    private var potsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Pots")
                    .font(.system(.subheadline, design: .serif))
                Spacer()
            }

            if viewModel.goals.isEmpty {
                EmptyPotsCard {
                    presentedPotEditor = makePotEditorViewModel {
                        Task { await viewModel.refresh() }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.goals) { goal in
                        PotRow(goal: goal) {
                            presentedContribution = makePotContributionViewModel(goal) {
                                Task { await viewModel.refresh() }
                            }
                        } onDelete: {
                            Task { await viewModel.delete(goal) }
                        }
                    }
                }
            }
        }
    }
}

private struct SavedByPausingCard: View {
    let amount: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Saved by pausing this month", systemImage: "moon.zzz.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(formatted)
                .font(.system(.largeTitle, design: .serif))
                .fontWeight(.semibold)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }

    private var formatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

private struct PendingWaitCard: View {
    let log: InterventionLog
    let onResolve: (WaitOutcome) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: log.category.systemImage)
                    .font(.body)
                    .frame(width: 32, height: 32)
                    .background(log.category.color.opacity(0.2), in: Circle())
                    .foregroundStyle(log.category.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.itemDescription)
                        .font(.headline)
                    Text("\(formattedAmount) · paused \(relativeDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text("Did you end up buying it?")
                .font(.subheadline)

            HStack(spacing: 12) {
                Button {
                    onResolve(.skipped)
                } label: {
                    Label("Skipped it", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    onResolve(.purchased)
                } label: {
                    Label("Bought it", systemImage: "bag")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }

    private var formattedAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = log.currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: log.amount)) ?? "\(log.amount)"
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: log.decidedAt, relativeTo: .now)
    }
}

private struct EmptyPotsCard: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No pots yet")
                .font(.headline)
            Text("Pots are little buckets you save into — toward a holiday, a wishlist item, or anything else. Use Pause & Reflect to turn an impulse into a pot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                onCreate()
            } label: {
                Label("Create a pot", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }
}

private struct PotRow: View {
    let goal: Goal
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if goal.isPot {
                        Label("Wishlist", systemImage: "leaf.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    if goal.isComplete {
                        Text("Ready!")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                    if let notes = goal.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: goal.progress)
                    .tint(AppPalette.progressFill)

                HStack {
                    Text(format(goal.savedAmount))
                        .font(.subheadline.weight(.semibold))
                    Text("of \(format(goal.targetAmount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(goal.progress * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .surfaceTile()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Add to pot", systemImage: "plus", action: onTap)
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    private func format(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = goal.currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct EmptyInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Nothing notable this week", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
            Text("Bujet flags categories that jump above your usual or repeat small charges with the same merchant. Nothing crossed those thresholds this week.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }
}

private struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: leadingIcon)
                    .font(.body)
                    .frame(width: 32, height: 32)
                    .background(iconTint.opacity(0.2), in: Circle())
                    .foregroundStyle(iconTint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.candidate.headline)
                        .font(.headline)
                    Text(insight.candidate.periodLabel.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                sourceBadge
            }

            Text(insight.narrative)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceTile()
    }

    private var leadingIcon: String {
        if let category = insight.candidate.category {
            return category.systemImage
        }
        return "sparkles"
    }

    private var iconTint: Color {
        insight.candidate.category?.color ?? .accentColor
    }

    @ViewBuilder
    private var sourceBadge: some View {
        if insight.source == .onDeviceLLM {
            Label("On-device AI", systemImage: "sparkles")
                .labelStyle(.titleAndIcon)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
