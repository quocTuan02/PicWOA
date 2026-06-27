import Foundation

enum SceneContext: String, Sendable {
    case indoor
    case outdoor
    case unknown

    var displayName: String {
        switch self {
        case .indoor: return "Trong nhà"
        case .outdoor: return "Ngoài trời"
        case .unknown: return "Không xác định"
        }
    }
}
