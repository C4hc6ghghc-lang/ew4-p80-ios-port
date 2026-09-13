import Foundation

public struct NativeOriginalDefenseArt: Equatable, Sendable {
    public let folder: String
    public let fileName: String

    public init(folder: String, fileName: String) {
        self.folder = folder
        self.fileName = fileName
    }

    public var resourcePath: String { "\(folder)/\(fileName)" }
}

/// Exact defense-card artwork mapping preserved by the mature P39 controller.
/// Every entry points at an existing byte-provenanced resource in Native Resources.
public enum NativeOriginalDefenseArtCore {
    public static let catalog: [String: NativeOriginalDefenseArt] = [
        "Trench": .init(folder: "image_ui_hd", fileName: "defense_moat.png"),
        "Fence": .init(folder: "image_ui_hd", fileName: "defense_fences.png"),
        "Bunker": .init(folder: "image_ui_hd", fileName: "defense_bunker.png"),
        "Small Fortress": .init(folder: "image_recruit_hd2", fileName: "buildmarker_smallfortress.png"),
        "Fortress": .init(folder: "image_recruit_hd", fileName: "buildmarker_mediumfortress.png"),
        "Large Fortress": .init(folder: "image_recruit_hd", fileName: "buildmarker_largefortress.png"),
        "Coastal Fort": .init(folder: "image_recruit_hd", fileName: "buildmarker_coastalartillery.png"),
    ]

    public static func art(for key: String) -> NativeOriginalDefenseArt? {
        catalog[key]
    }
}
