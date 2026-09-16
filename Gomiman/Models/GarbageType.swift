import Foundation
import SwiftUI

public enum GarbageType: Int, CaseIterable, Identifiable, Codable, Sendable {
    case burnable = 1
    case nonBurnable = 2
    case glassBottle = 3
    case can = 4
    case plastic = 5
    case paper = 6
    case petBottle = 7

    public var id: Int { rawValue }

    public var typeName: String {
        switch self {
        case .burnable: return "可燃"
        case .nonBurnable: return "不燃"
        case .glassBottle: return "びん"
        case .can: return "かん"
        case .plastic: return "プラスチック"
        case .paper: return "古紙"
        case .petBottle: return "ペットボトル"
        }
    }

    public var shortName: String {
        switch self {
        case .burnable: return "可燃"
        case .nonBurnable: return "不燃"
        case .glassBottle: return "びん"
        case .can: return "かん"
        case .plastic: return "プラ"
        case .paper: return "古紙"
        case .petBottle: return "ボトル"
        }
    }

    public static func from(id: Int) -> GarbageType? {
        return GarbageType(rawValue: id)
    }

    public static var allTypes: [GarbageType] {
        return allCases
    }
}
