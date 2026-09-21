import SwiftUI

enum ReadingTheme: String, CaseIterable, Identifiable {
    case paper
    case parchment
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paper: return "Paper"
        case .parchment: return "Parchment"
        case .night: return "Night"
        }
    }

    var page: Color {
        switch self {
        case .paper: return Color(red: 0.97, green: 0.94, blue: 0.89)
        case .parchment: return Color(red: 0.93, green: 0.86, blue: 0.72)
        case .night: return Color(red: 0.11, green: 0.10, blue: 0.09)
        }
    }

    var ink: Color {
        switch self {
        case .paper: return Color(red: 0.17, green: 0.14, blue: 0.10)
        case .parchment: return Color(red: 0.22, green: 0.16, blue: 0.10)
        case .night: return Color(red: 0.90, green: 0.86, blue: 0.78)
        }
    }

    var mute: Color {
        switch self {
        case .paper: return Color(red: 0.45, green: 0.38, blue: 0.30)
        case .parchment: return Color(red: 0.48, green: 0.36, blue: 0.24)
        case .night: return Color(red: 0.62, green: 0.56, blue: 0.48)
        }
    }

    var accent: Color {
        switch self {
        case .paper: return Color(red: 0.55, green: 0.28, blue: 0.18)
        case .parchment: return Color(red: 0.48, green: 0.24, blue: 0.14)
        case .night: return Color(red: 0.86, green: 0.64, blue: 0.42)
        }
    }

    var dark: Color {
        Color(red: 0.10, green: 0.08, blue: 0.06)
    }

    var gold: Color {
        switch self {
        case .paper: return Color(red: 0.80, green: 0.64, blue: 0.22)
        case .parchment: return Color(red: 0.74, green: 0.56, blue: 0.18)
        case .night: return Color(red: 0.90, green: 0.74, blue: 0.38)
        }
    }

    var scheme: ColorScheme {
        self == .night ? .dark : .light
    }
}

enum QuietFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func small(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}

