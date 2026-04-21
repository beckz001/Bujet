import Foundation

extension String {
    /// Alphanumeric + spaces only
    var alphanumericWithSpacesOnly: String {
        self.filter { $0.isLetter || $0.isNumber || $0 == " " }
    }

    /// Banking-style amount sanitiser (numbers + one decimal, 2 dp)
    var sanitisedAmount: String {
        var result = ""
        var hasDecimal = false
        var decimalCount = 0

        for char in self {
            if char.isNumber {
                if hasDecimal {
                    guard decimalCount < 2 else { continue }
                    decimalCount += 1
                }
                result.append(char)
            } else if char == "." && !hasDecimal {
                hasDecimal = true
                result.append(char)
            }
        }

        return result
    }
}
