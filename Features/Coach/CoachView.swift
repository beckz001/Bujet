import SwiftUI

struct CoachView: View {
    let viewModel: CoachViewModel
    let makePotEditorViewModel: (@escaping () -> Void) -> PotEditorViewModel
    let makePotContributionViewModel: (Goal, @escaping () -> Void) -> PotContributionViewModel

    @State private var presentedPotEditor: PotEditorViewModel?
    @State private var presentedContribution: PotContributionViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.moneySavedByPausing > 0 {
                    SavedByPausingCard(
                        amount: viewModel.moneySavedByPausing,
                        currencyCode: viewModel.currencyCode
                    )
                }

                potsSection
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
            Label("Money saved by pausing", systemImage: "moon.zzz.fill")
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
                    } else {
                        Label("Goal", systemImage: "flag.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.blue)
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

                Text(goal.name)
                    .font(.headline)
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
