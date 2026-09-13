import Foundation
import Testing
@testable import EW4NativeCore

@Test func visualResolverNationalThenGeneric() throws {
    let json = #"{"format":"x","unit_count":2,"unique_asset_count":1,"fps":24,"motion_count":1,"units":{"Line Infantry fra 1":{"resource":"army_lineinfantry","native_anchor":{"x":-1,"y":-2},"dir":"1","motions":[{"type":"ready","index":0,"direction":"all","asset":"a","speed":1,"effect":null}]},"Privateer":{"resource":"army_ship","native_anchor":{"x":0,"y":0},"dir":"1","motions":[]}},"assets":{"a":{"resource":"army_lineinfantry","motion_name":"r","motion_type":"ready","motion_index":0,"direction":"all","frame_count":1,"fps":24,"motion_speed_attr":1,"representative_unit":"Line Infantry fra 1","compact_only":true}}}"#
    let manifest = try JSONDecoder().decode(NativeAnimationManifest.self, from: Data(json.utf8))
    let infantry = BattleUnit(index: 1, q: 2, r: 3, armyID: 1, armyName: "Line Infantry", grade: 0, hp: 10, maxHP: 10, commanderID: nil, owner: 0)
    #expect(NativeUnitVisualResolver.animationUnitName(unit: infantry, countryCode: "fra", manifest: manifest) == "Line Infantry fra 1")
    #expect(NativeUnitVisualResolver.readyMotion(for: "Line Infantry fra 1", manifest: manifest)?.asset == "a")
}

@Test func compactOriginMatchesRecoveredContract() throws {
    let json = #"{"resource":"army_militia","native_anchor":{"x":-34,"y":-47},"dir":"1","motions":[]}"#
    let unit = try JSONDecoder().decode(NativeAnimationUnit.self, from: Data(json.utf8))
    #expect(NativeAnimationTiming.compactDrawOrigin(unit: unit, worldPoint: .init(x:450,y:350), unitZoom: 1) == NativeDrawOrigin(x:433,y:326.5,scale:0.5))
    #expect(NativeAnimationTiming.compactDrawOrigin(unit: unit, worldPoint: .init(x:450,y:350), unitZoom: 2) == NativeDrawOrigin(x:416,y:303,scale:1))
}
