import SwiftUI

extension Color {
    static var cardBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }

    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "#", with: "")
        guard s.count == 6 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&rgb) else { return nil }
        self.init(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >>  8) / 255,
            blue:  Double( rgb & 0x0000FF       ) / 255
        )
    }

    func toHex() -> String? {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        #else
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r) * 255),
                      lroundf(Float(g) * 255),
                      lroundf(Float(b) * 255))
    }
}

// 습관 색상 팔레트 (hex 문자열)
let habitColorPalette: [String] = [
    "#FF6B6B",  // 빨강
    "#FF9F43",  // 오렌지
    "#FFC312",  // 노랑
    "#2ED573",  // 초록
    "#1DD1A1",  // 민트
    "#74B9FF",  // 하늘
    "#5352ED",  // 남색
    "#A29BFE",  // 보라
    "#FD79A8",  // 핑크
    "#E17055",  // 코랄
    "#00CEC9",  // 시안
    "#6C5CE7",  // 인디고
]
