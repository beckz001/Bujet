import SwiftUI

/// Standard tile background used across Home and Insights. Adapts to dark mode
/// via `secondarySystemGroupedBackground`, which sits naturally on the cream
/// app background in light mode and a dark grey in dark mode.
struct SurfaceTileModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
    }
}

extension View {
    func surfaceTile(cornerRadius: CGFloat = 24) -> some View {
        modifier(SurfaceTileModifier(cornerRadius: cornerRadius))
    }
}

enum AppPalette {
    static let background = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(hex: "EFEFD0")
    })
    
    static let trendUpBackground = Color(hex: "FFD4D4")
    static let trendUpForeground = Color(hex: "B8412A")
    static let trendDownBackground = Color(hex: "CDFFF3")
    static let trendDownForeground = Color(hex: "5A7A3A")

    static let progressFill = Color(hex: "004E89")
    static let progressTrack = Color(hex: "D9D9D9")
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
