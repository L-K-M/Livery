import Foundation

/// Which top corner a `DecorationStyle` is drawn in.
public enum DecorationPosition: String, CaseIterable, Identifiable, Sendable {
    case topLeading
    case topTrailing

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .topLeading: return "Top left"
        case .topTrailing: return "Top right"
        }
    }
}
