import Foundation

enum TransactionCategoriser {
    static func categorise(
        classifications: [String]?,
        merchant: String
    ) -> TransactionCategory {
        if let classifications, let fromClassifications = categorise(classifications: classifications) {
            return fromClassifications
        }
        return categorise(merchant: merchant) ?? .other
    }

    // MARK: - TrueLayer classification mapping

    private static func categorise(classifications: [String]) -> TransactionCategory? {
        for raw in classifications {
            let token = raw.lowercased()
            if let match = classificationKeywordMap.first(where: { token.contains($0.key) }) {
                return match.value
            }
        }
        return nil
    }

    private static let classificationKeywordMap: [(key: String, value: TransactionCategory)] = [
        ("groceries",      .groceries),
        ("supermarket",    .groceries),
        ("food shop",      .groceries),
        ("restaurant",     .eatingOut),
        ("food & drink",   .eatingOut),
        ("food and drink", .eatingOut),
        ("eating out",     .eatingOut),
        ("takeaway",       .eatingOut),
        ("cafe",           .eatingOut),
        ("coffee",         .eatingOut),
        ("bills",          .bills),
        ("utilities",      .bills),
        ("rent",           .bills),
        ("mortgage",       .bills),
        ("insurance",      .bills),
        ("subscription",   .bills),
        ("transport",      .transport),
        ("travel",         .transport),
        ("fuel",           .transport),
        ("gas station",    .transport),
        ("petrol",         .transport),
        ("parking",        .transport)
    ]

    // MARK: - Merchant keyword fallback (UK-leaning)

    private static func categorise(merchant: String) -> TransactionCategory? {
        let token = merchant.lowercased()
        return merchantKeywordMap.first(where: { token.contains($0.key) })?.value
    }

    private static let merchantKeywordMap: [(key: String, value: TransactionCategory)] = [
        // Groceries
        ("tesco",         .groceries),
        ("sainsbury",     .groceries),
        ("asda",          .groceries),
        ("aldi",          .groceries),
        ("lidl",          .groceries),
        ("morrisons",     .groceries),
        ("waitrose",      .groceries),
        ("co-op",         .groceries),
        ("coop",          .groceries),
        ("iceland",       .groceries),
        ("marks & spencer", .groceries),
        ("m&s food",      .groceries),
        ("ocado",         .groceries),

        // Eating out
        ("mcdonald",      .eatingOut),
        ("kfc",           .eatingOut),
        ("burger king",   .eatingOut),
        ("subway",        .eatingOut),
        ("nando",         .eatingOut),
        ("pret",          .eatingOut),
        ("greggs",        .eatingOut),
        ("costa",         .eatingOut),
        ("starbucks",     .eatingOut),
        ("caffe nero",    .eatingOut),
        ("deliveroo",     .eatingOut),
        ("just eat",      .eatingOut),
        ("uber eats",     .eatingOut),
        ("domino",        .eatingOut),
        ("pizza hut",     .eatingOut),
        ("wagamama",      .eatingOut),
        ("five guys",     .eatingOut),

        // Transport
        ("uber",          .transport),
        ("bolt",          .transport),
        ("lyft",          .transport),
        ("tfl",           .transport),
        ("transport for london", .transport),
        ("trainline",     .transport),
        ("national rail", .transport),
        ("lner",          .transport),
        ("avanti",        .transport),
        ("shell",         .transport),
        ("bp ",           .transport),
        ("esso",          .transport),
        ("texaco",        .transport),
        ("ryanair",       .transport),
        ("easyjet",       .transport),
        ("british airways", .transport),

        // Bills
        ("british gas",   .bills),
        ("octopus energy", .bills),
        ("edf",           .bills),
        ("eon",           .bills),
        ("scottish power", .bills),
        ("thames water",  .bills),
        ("anglian water", .bills),
        ("bt ",           .bills),
        ("sky ",          .bills),
        ("virgin media",  .bills),
        ("o2",            .bills),
        ("vodafone",      .bills),
        ("ee ",           .bills),
        ("three",         .bills),
        ("netflix",       .bills),
        ("spotify",       .bills),
        ("disney+",       .bills),
        ("amazon prime",  .bills),
        ("apple.com/bill", .bills),
        ("council tax",   .bills)
    ]
}
