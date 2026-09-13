import Foundation
import Testing
@testable import EW4NativeCore

@Test func p61DefenseAndUseItemFormsKeepRecoveredXMLGeometry() {
    let defense = NativeOriginalFormGeometryCore.Defense.self
    #expect(defense.frame == NativeRect(x: 0, y: 0, width: 300, height: 184))
    #expect(defense.list == NativeRect(x: 2, y: 30, width: 298, height: 65))
    #expect(defense.itemWidth == 72)
    #expect(defense.interval == 3)
    #expect(defense.itemRect(index: 0) == NativeRect(x: 136, y: 98, width: 72, height: 65))
    #expect(defense.itemRect(index: 3) == NativeRect(x: 361, y: 98, width: 72, height: 65))
    #expect(defense.description == NativeRect(x: 2, y: 98, width: 296, height: 84))
    #expect(defense.descriptionText == NativeRect(x: 2, y: 19, width: 292, height: 63))

    let useItem = NativeOriginalFormGeometryCore.UseItem.self
    #expect(useItem.frame == NativeRect(x: 0, y: 0, width: 280, height: 175))
    #expect(useItem.list == NativeRect(x: 9, y: 35, width: 269, height: 45))
    #expect(useItem.itemSize == NativeSize(width: 45, height: 45))
    #expect(useItem.interval == 9)
    #expect(useItem.itemRect(index: 0) == NativeRect(x: 153, y: 107, width: 45, height: 45))
    #expect(useItem.itemRect(index: 4) == NativeRect(x: 369, y: 107, width: 45, height: 45))
    #expect(useItem.description == NativeRect(x: 2, y: 88, width: 275, height: 84))
    #expect(useItem.descriptionText == NativeRect(x: 3, y: 19, width: 269, height: 63))
}

@Test func p61ConsumableItemArtworkResolvesToFrozenOriginalResources() {
    let names = ["Wine", "Spirit", "Medikit", "Medikit L", "First Aid Box"]
    let expected = ["Wine.png", "Spirit.png", "Medikit.png", "Medikit_L.png", "First_Aid_Box.png"]
    for (name, file) in zip(names, expected) {
        #expect(NativeOriginalItemArtCore.resourceFileName(for: name) == file)
        let url = TestResourcePaths.resources.appendingPathComponent("Items", isDirectory: true).appendingPathComponent(file)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
}

@Test func p61UseItemRendererUsesOriginalArtworkAndNoRawIDPlaceholder() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalUseItemRenderer.swift"), encoding: .utf8)
    #expect(source.contains("NativeOriginalItemArtCore.resourceFileName"))
    #expect(source.contains("item_selected_ex.png"))
    #expect(source.contains("title_useitem"))
    #expect(source.contains("desc_\\(item.name)"))
    #expect(!source.contains("label(\"\\(items[i].id)\""))
}

@Test func p62DefenseCardContentGeometryMatchesMatureP39Contract() {
    let defense = NativeOriginalFormGeometryCore.Defense.self
    #expect(defense.itemImage == NativeRect(x: 15, y: 1, width: 42, height: 35))
    #expect(defense.itemName == NativeRect(x: 2, y: 36, width: 68, height: 11))
    #expect(defense.itemCost == NativeRect(x: 2, y: 47, width: 68, height: 12))
}

@Test func p62DefenseArtworkCatalogMatchesMatureP39AndFrozenResources() {
    let expected: [String: NativeOriginalDefenseArt] = [
        "Trench": .init(folder: "image_ui_hd", fileName: "defense_moat.png"),
        "Fence": .init(folder: "image_ui_hd", fileName: "defense_fences.png"),
        "Bunker": .init(folder: "image_ui_hd", fileName: "defense_bunker.png"),
        "Small Fortress": .init(folder: "image_recruit_hd2", fileName: "buildmarker_smallfortress.png"),
        "Fortress": .init(folder: "image_recruit_hd", fileName: "buildmarker_mediumfortress.png"),
        "Large Fortress": .init(folder: "image_recruit_hd", fileName: "buildmarker_largefortress.png"),
        "Coastal Fort": .init(folder: "image_recruit_hd", fileName: "buildmarker_coastalartillery.png"),
    ]
    #expect(NativeOriginalDefenseArtCore.catalog == expected)
    for (key, art) in expected {
        #expect(NativeOriginalDefenseArtCore.art(for: key) == art)
        let url = TestResourcePaths.resources
            .appendingPathComponent("Sprites", isDirectory: true)
            .appendingPathComponent(art.folder, isDirectory: true)
            .appendingPathComponent(art.fileName)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }
    #expect(NativeOriginalDefenseArtCore.art(for: "Unknown Defense") == nil)
}

@Test func p62DefenseRendererConsumesOriginalArtAndSelectionOverlay() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalDefenseRenderer.swift"), encoding: .utf8)
    #expect(source.contains("NativeOriginalDefenseArtCore.art(for: choice.key)"))
    #expect(source.contains("item_selected_ex.png"))
    #expect(source.contains("placeAspectFit"))
    #expect(!source.contains("sel ? ui(203,188,155)"))
}
