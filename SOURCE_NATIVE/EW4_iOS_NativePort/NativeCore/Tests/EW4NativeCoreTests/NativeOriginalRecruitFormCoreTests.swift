import Testing
@testable import EW4NativeCore

@Test func p60RecruitFormKeepsRecoveredXMLGeometry() {
    let g = NativeOriginalFormGeometryCore.Recruit.self
    #expect(g.frame == NativeRect(x: 0, y: 0, width: 441, height: 185))
    #expect(g.list == NativeRect(x: 2, y: 37, width: 440, height: 65))
    #expect(g.listItemWidth == 72)
    #expect(g.listInterval == 1)
    #expect(g.infoGrid == NativeRect(x: 2, y: 109, width: 152, height: 72))
    #expect(g.infoColumns == 4)
    #expect(g.infoRowHeight == 24)
    #expect(g.description == NativeRect(x: 155, y: 109, width: 284, height: 72))
}

@Test func p60RecruitArtCatalogCoversAllRecruitableArmyFamilies() {
    let names = [
        "Militia", "Line Infantry", "Light Infantry", "Grenadier", "Guards", "Machine Gun",
        "Light Cavalry", "Heavy Cavalry", "Guards Cavalry", "Armored Car",
        "Light Artillery", "Heavy Artillery", "Siege Artillery", "Rocket",
        "Privateer", "Frigate", "Battleship", "Ironclad"
    ]
    for name in names {
        let art = NativeOriginalRecruitArtCore.art(for: name)
        #expect(!art.unitPath.isEmpty)
        #expect(!art.markerPath.isEmpty)
    }
    #expect(NativeOriginalRecruitArtCore.art(for: "Unknown Unit") == NativeOriginalRecruitArtCore.art(for: "Militia"))
}
