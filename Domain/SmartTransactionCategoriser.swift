import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// Sketch: on-device LLM categoriser using Apple's Foundation Models framework.
// Falls back to the existing keyword-based `TransactionCategoriser` when the
// system model is unavailable (older OS, Apple Intelligence off, low power, etc).

protocol TransactionCategorising: Sendable {
    func categorise(merchant: String, description: String) async -> TransactionCategory
    func categorise(_ inputs: [CategorisationInput]) async -> [String: TransactionCategory]
}

struct CategorisationInput: Sendable {
    let id: String
    let merchant: String
    let description: String
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
enum GeneratedCategory: String, CaseIterable {
    case bills
    case eatingOut = "eating_out"
    case groceries
    case transport
    case other

    var domain: TransactionCategory {
        switch self {
        case .bills:     .bills
        case .eatingOut: .eatingOut
        case .groceries: .groceries
        case .transport: .transport
        case .other:     .other
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct CategoryGuess {
    @Guide(description: "The single best-fitting category for this transaction.")
    let category: GeneratedCategory
}

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct BatchCategoryGuess {
    @Guide(description: "One result per input transaction, in the same order, with matching ids.")
    let results: [Item]

    @Generable
    struct Item {
        @Guide(description: "The id from the input line.")
        let id: String
        let category: GeneratedCategory
    }
}

actor SmartTransactionCategoriser: TransactionCategorising {

    // Tunable: input rows per LLM call. Keep small enough that prompt + structured
    // output stay well under the model's context window. 25 is a safe starting point.
    private let batchSize = 25

    // Try ML first; on any failure or unsupported device, fall back to keywords.
    func categorise(merchant: String, description: String) async -> TransactionCategory {
        if #available(iOS 26.0, macOS 26.0, *) {
            if let ml = await classifyWithFoundationModels(merchant: merchant, description: description) {
                return ml
            }
        }
        return TransactionCategoriser.categorise(
            classifications: nil,
            merchant: merchant
        )
    }

    // Batch entry point: returns id → category. Anything the ML pass doesn't
    // cover (unsupported device, partial response, error) falls back to the
    // keyword categoriser so every input always gets an answer.
    func categorise(_ inputs: [CategorisationInput]) async -> [String: TransactionCategory] {
        var result: [String: TransactionCategory] = [:]

        if #available(iOS 26.0, macOS 26.0, *) {
            result = await classifyBatchesWithFoundationModels(inputs)
        }

        for input in inputs where result[input.id] == nil {
            result[input.id] = TransactionCategoriser.categorise(
                classifications: nil,
                merchant: input.merchant
            )
        }
        return result
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static let instructions = """
        You categorise UK bank transactions into exactly one of these buckets:
        bills, eating_out, groceries, transport, other.
        Use the merchant name as the strongest signal; the description is a hint.
        If genuinely uncertain, choose "other".
        """

    @available(iOS 26.0, macOS 26.0, *)
    private func classifyWithFoundationModels(
        merchant: String,
        description: String
    ) async -> TransactionCategory? {
        guard SystemLanguageModel.default.isAvailable else { return nil }

        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: "Merchant: \(merchant)\nDescription: \(description)",
                generating: CategoryGuess.self,
                options: GenerationOptions(temperature: 0)
            )
            return response.content.category.domain
        } catch {
            return nil
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func classifyBatchesWithFoundationModels(
        _ inputs: [CategorisationInput]
    ) async -> [String: TransactionCategory] {
        guard SystemLanguageModel.default.isAvailable, !inputs.isEmpty else { return [:] }

        // One session reused across all batches: amortises model warmup and
        // keeps the system instructions cached across calls.
        let session = LanguageModelSession(instructions: Self.instructions)
        var out: [String: TransactionCategory] = [:]

        for chunk in inputs.chunked(into: batchSize) {
            let prompt = Self.buildBatchPrompt(chunk)
            do {
                let response = try await session.respond(
                    to: prompt,
                    generating: BatchCategoryGuess.self,
                    options: GenerationOptions(temperature: 0)
                )
                for item in response.content.results {
                    out[item.id] = item.category.domain
                }
            } catch {
                // Skip this chunk — outer caller will fill misses via keyword fallback.
                continue
            }
        }
        return out
    }

    @available(iOS 26.0, macOS 26.0, *)
    private static func buildBatchPrompt(_ chunk: [CategorisationInput]) -> String {
        // Compact, line-per-row format keeps the input cheap and parseable.
        // The structured output schema (BatchCategoryGuess) does the actual parsing.
        let lines = chunk.map { input in
            "id=\(input.id) | merchant=\(input.merchant) | description=\(input.description)"
        }
        return """
            Categorise each transaction below. Return one result per row, preserving the id.

            \(lines.joined(separator: "\n"))
            """
    }
    #else
    @available(iOS 26.0, macOS 26.0, *)
    private func classifyWithFoundationModels(
        merchant: String,
        description: String
    ) async -> TransactionCategory? { nil }

    @available(iOS 26.0, macOS 26.0, *)
    private func classifyBatchesWithFoundationModels(
        _ inputs: [CategorisationInput]
    ) async -> [String: TransactionCategory] { [:] }
    #endif
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
