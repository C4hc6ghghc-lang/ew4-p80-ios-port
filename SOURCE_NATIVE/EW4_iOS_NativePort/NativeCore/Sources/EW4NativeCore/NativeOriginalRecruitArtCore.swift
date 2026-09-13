import Foundation

public struct NativeOriginalRecruitArt: Equatable, Sendable {
    public let unitPath: String
    public let markerPath: String

    public init(unitPath: String, markerPath: String) {
        self.unitPath = unitPath
        self.markerPath = markerPath
    }
}

/// Original recruit-card/unit-info art pairing recovered from the frozen P39
/// controller and backed by byte-provenanced EW4 sprite resources.
public enum NativeOriginalRecruitArtCore {
    public static let catalog: [String: NativeOriginalRecruitArt] = [
        "Militia": .init(unitPath: "image_recruit_hd2/recruit_militia.png", markerPath: "image_recruit_hd3/recruitmarker_militia.png"),
        "Line Infantry": .init(unitPath: "image_recruit_hd2/recruit_line.png", markerPath: "image_recruit_hd2/recruitmarker_line.png"),
        "Light Infantry": .init(unitPath: "image_recruit_hd/recruit_light.png", markerPath: "image_recruit_hd2/recruitmarker_light.png"),
        "Grenadier": .init(unitPath: "image_recruit_hd/recruit_grenadier.png", markerPath: "image_recruit_hd2/recruitmarker_grenadier.png"),
        "Guards": .init(unitPath: "image_recruit_hd/recruit_guard.png", markerPath: "image_recruit_hd2/recruitmarker_guard.png"),
        "Machine Gun": .init(unitPath: "image_recruit_hd2/recruit_machinegun.png", markerPath: "image_recruit_hd3/recruitmarker_machinegun.png"),
        "Light Cavalry": .init(unitPath: "image_recruit_hd2/recruit_lightcavalry.png", markerPath: "image_recruit_hd2/recruitmarker_lightcavalry.png"),
        "Heavy Cavalry": .init(unitPath: "image_recruit_hd/recruit_heavycavalry.png", markerPath: "image_recruit_hd2/recruitmarker_heavycavalry.png"),
        "Guards Cavalry": .init(unitPath: "image_recruit_hd2/recruit_musketcavalry.png", markerPath: "image_recruit_hd3/recruitmarker_musketcavalry.png"),
        "Armored Car": .init(unitPath: "image_recruit_hd/recruit_armoredcar.png", markerPath: "image_recruit_hd2/recruitmarker_armoredcar.png"),
        "Light Artillery": .init(unitPath: "image_recruit_hd2/recruit_lightartillery.png", markerPath: "image_recruit_hd2/recruitmarker_lightartillery.png"),
        "Heavy Artillery": .init(unitPath: "image_recruit_hd/recruit_heavyartillery.png", markerPath: "image_recruit_hd2/recruitmarker_heavyartillery.png"),
        "Siege Artillery": .init(unitPath: "image_recruit_hd/recruit_fortressartillery.png", markerPath: "image_recruit_hd2/recruitmarker_fortressartillery.png"),
        "Rocket": .init(unitPath: "image_recruit_hd2/recruit_rocket.png", markerPath: "image_recruit_hd3/recruitmarker_rocket.png"),
        "Privateer": .init(unitPath: "image_recruit_hd/recruit_cruiser.png", markerPath: "image_recruit_hd2/recruitmarker_cruiser.png"),
        "Frigate": .init(unitPath: "image_recruit_hd/recruit_frigate.png", markerPath: "image_recruit_hd2/recruitmarker_frigate.png"),
        "Battleship": .init(unitPath: "image_recruit_hd/recruit_battleship.png", markerPath: "image_recruit_hd2/recruitmarker_battleship.png"),
        "Ironclad": .init(unitPath: "image_recruit_hd/recruit_ironclads.png", markerPath: "image_recruit_hd2/recruitmarker_ironclads.png"),
        "Small Fortress": .init(unitPath: "image_recruit_hd3/build_smallfortress.png", markerPath: "image_recruit_hd2/buildmarker_smallfortress.png"),
        "Fortress": .init(unitPath: "image_recruit_hd2/build_mediumfortress.png", markerPath: "image_recruit_hd/buildmarker_mediumfortress.png"),
        "Large Fortress": .init(unitPath: "image_recruit_hd2/build_largefortress.png", markerPath: "image_recruit_hd/buildmarker_largefortress.png"),
        "Coastal Fort": .init(unitPath: "image_recruit_hd2/build_coastalartillery.png", markerPath: "image_recruit_hd/buildmarker_coastalartillery.png"),
    ]

    public static func art(for armyName: String) -> NativeOriginalRecruitArt {
        catalog[armyName] ?? catalog["Militia"]!
    }
}
