import Foundation

public struct NativeUnitPresentationSpec: Sendable {
    public let unitIndex: Int
    public let animationUnitName: String
    public let readyAssetID: String
    public let resource: String
    public let motionName: String
    public let worldPoint: NativePoint
    public let drawOrigin: NativeDrawOrigin
    public let phaseOffsetMilliseconds: Double
}

public struct NativeObjectPresentationSpec: Sendable {
    public let objectIndex: Int
    public let spriteKey: String
    public let spriteFile: String
    public let worldPoint: NativePoint
    public let drawX: Double
    public let drawY: Double
    public let width: Double
    public let height: Double
}

public enum NativeBuildingVisualResolver {
    private static let eastCodes: Set<String> = ["rus", "tur", "per"]

    public static func spriteKey(constructionType: String?, level rawLevel: Int, q: Int, r: Int, countryCode: String) -> String? {
        let level = max(1, rawLevel)
        let style = eastCodes.contains(countryCode) ? "east" : "west"
        switch constructionType {
        case "city": return "city_\(style)_lv\(min(7, level)).png"
        case "industry": return "factory_\(style)_lv\(min(4, level)).png"
        case "stable": return "stable_\(style)_lv\(min(3, level)).png"
        case "port": return "port_\(min(4, level)).png"
        case "farmland": return "farm_\(1 + (q + r) % 4)_lv\(min(3, level)).png"
        default: return nil
        }
    }

    public static func spriteKey(object: BattleObject, countryCode: String) -> String? {
        spriteKey(constructionType: object.constructionType, level: object.level, q: object.q, r: object.r, countryCode: countryCode)
    }

    public static func spriteKey(object: NativeBattleObjectState, countryCode: String) -> String? {
        spriteKey(constructionType: object.constructionType, level: object.level, q: object.q, r: object.r, countryCode: countryCode)
    }

    public static func specialMarkerKey(object: BattleObject) -> String? {
        switch object.extra {
        case 1: return "marker_trade.png"
        case 2: return "marker_shop.png"
        case 3: return "marker_bar.png"
        default: return nil
        }
    }
}

public enum NativeBattlePresentationBuilder {
    public static func unitSpec(unit: BattleUnit, countryCode: String, manifest: NativeAnimationManifest) -> NativeUnitPresentationSpec? {
        guard let name = NativeUnitVisualResolver.animationUnitName(unit: unit, countryCode: countryCode, manifest: manifest),
              let animationUnit = manifest.units[name],
              let ready = NativeUnitVisualResolver.readyMotion(for: name, manifest: manifest),
              let asset = manifest.assets[ready.asset] else { return nil }
        let p = NativeHexGeometry.cellCenter(HexCell(q: unit.q, r: unit.r))
        let origin = NativeAnimationTiming.compactDrawOrigin(unit: animationUnit, worldPoint: p, unitZoom: 1)
        let duration = max(1, NativeAnimationTiming.rawDurationMilliseconds(asset))
        let phase = Double((unit.index * 97) % max(1, Int(duration)))
        return .init(unitIndex: unit.index, animationUnitName: name, readyAssetID: ready.asset, resource: asset.resource, motionName: asset.motionName, worldPoint: p, drawOrigin: origin, phaseOffsetMilliseconds: phase)
    }

    public static func objectSpec(object: BattleObject, countryCode: String, sprites: [String: SpriteManifestEntry]) -> NativeObjectPresentationSpec? {
        guard let key = NativeBuildingVisualResolver.spriteKey(object: object, countryCode: countryCode), let sprite = sprites[key] else { return nil }
        let p = NativeHexGeometry.cellCenter(HexCell(q: object.q, r: object.r))
        let scale = 0.5
        return .init(objectIndex: object.index, spriteKey: key, spriteFile: sprite.file, worldPoint: p, drawX: p.x - sprite.refx * scale, drawY: p.y - sprite.refy * scale, width: sprite.w * scale, height: sprite.h * scale)
    }
    public static func unitSpec(
        unit: NativeBattleUnitState,
        countryCode: String,
        readyDirection: String? = nil,
        manifest: NativeAnimationManifest
    ) -> NativeUnitPresentationSpec? {
        guard let name = NativeUnitVisualResolver.animationUnitName(unit: unit, countryCode: countryCode, manifest: manifest),
              let animationUnit = manifest.units[name],
              let ready = NativeUnitVisualResolver.readyMotion(for: name, direction: readyDirection, manifest: manifest),
              let asset = manifest.assets[ready.asset] else { return nil }
        let p = NativeHexGeometry.cellCenter(unit.cell)
        let origin = NativeAnimationTiming.compactDrawOrigin(unit: animationUnit, worldPoint: p, unitZoom: 1)
        let duration = max(1, NativeAnimationTiming.rawDurationMilliseconds(asset))
        let phase = Double((unit.index * 97) % max(1, Int(duration)))
        return .init(unitIndex: unit.index, animationUnitName: name, readyAssetID: ready.asset, resource: asset.resource, motionName: asset.motionName, worldPoint: p, drawOrigin: origin, phaseOffsetMilliseconds: phase)
    }

    public static func objectSpec(object: NativeBattleObjectState, countryCode: String, sprites: [String: SpriteManifestEntry]) -> NativeObjectPresentationSpec? {
        guard let key = NativeBuildingVisualResolver.spriteKey(object: object, countryCode: countryCode), let sprite = sprites[key] else { return nil }
        let p = NativeHexGeometry.cellCenter(object.cell)
        let scale = 0.5
        return .init(objectIndex: object.index, spriteKey: key, spriteFile: sprite.file, worldPoint: p, drawX: p.x - sprite.refx * scale, drawY: p.y - sprite.refy * scale, width: sprite.w * scale, height: sprite.h * scale)
    }

}
