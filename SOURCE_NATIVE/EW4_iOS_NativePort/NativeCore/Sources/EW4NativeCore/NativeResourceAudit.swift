import Foundation

public struct NativeResourceAuditReport: Codable, Sendable {
    public var battleCount:Int
    public var worldCount:Int
    public var europeSize:String
    public var animationUnitCount:Int
    public var animationAssetCount:Int
    public var animationFPS:Int
    public var defMotionUnitCount:Int
    public var defMotionMotionCount:Int
    public var bileResourceCount:Int
    public var bileDecoded:Int
    public var battleUnitCount:Int
    public var battleUnitVisualResolved:Int
    public var battleObjectCount:Int
    public var battleObjectSpriteEligible:Int
    public var battleObjectSpriteResolved:Int
    public var errors:[String]
    public var passed:Bool { errors.isEmpty && battleCount == 101 && animationUnitCount == 877 && worldCount == 2 && defMotionUnitCount == 877 && bileDecoded > 0 && battleUnitVisualResolved == battleUnitCount && battleObjectSpriteResolved == battleObjectSpriteEligible }
}

public enum NativeResourceAuditor {
    public static func audit(resourceRoot:URL)throws->NativeResourceAuditReport{
        let data=resourceRoot.appendingPathComponent("Data"), bile=resourceRoot.appendingPathComponent("Bile")
        let battles=try ResourceLoader.decode(BattlesRuntimeFile.self,from:data.appendingPathComponent("battles_runtime.json"))
        let worlds=try ResourceLoader.decode(WorldMapsFile.self,from:data.appendingPathComponent("worldmaps.json"))
        let anim=try ResourceLoader.decode(NativeAnimationManifest.self,from:data.appendingPathComponent("native_animation_core877.json"))
        let dmText=try String(contentsOf:bile.appendingPathComponent("def_motion.xml"),encoding:.utf8);let dm=DefMotionParser.parse(dmText)
        let fm=FileManager.default;let bins=(try? fm.contentsOfDirectory(at:bile,includingPropertiesForKeys:nil).filter{$0.pathExtension=="bin"}) ?? []
        var errors:[String]=[],decoded=0
        for bin in bins.sorted(by:{$0.lastPathComponent<$1.lastPathComponent}){
            let stem=bin.deletingPathExtension().lastPathComponent, xml=bile.appendingPathComponent(stem+".xml")
            guard fm.fileExists(atPath:xml.path) else{errors.append("missing texture xml: \(stem)");continue}
            do{_ = try CompactBILE(data:Data(contentsOf:bin),textureXML:String(contentsOf:xml,encoding:.utf8));decoded += 1}catch{errors.append("BILE \(stem): \(error)")}
        }
        if battles.count != battles.battles.count { errors.append("battle count header mismatch") }
        if anim.unitCount != anim.units.count { errors.append("animation unit count mismatch") }
        if anim.uniqueAssetCount != anim.assets.count { errors.append("animation asset count mismatch") }
        for (name,w) in worlds.worlds where w.cells.count != w.width*w.height { errors.append("world \(name) cell count mismatch") }

        let spriteURL = resourceRoot.appendingPathComponent("sprite_manifest.json")
        let sprites = try ResourceLoader.decode([String: SpriteManifestEntry].self, from: spriteURL)
        var battleUnitCount = 0
        var visualResolved = 0
        var objectCount = 0
        var objectEligible = 0
        var objectResolved = 0
        for battle in battles.battles {
            for unit in battle.units {
                battleUnitCount += 1
                let code = battle.countries.first(where: { $0.index == unit.owner })?.code ?? "fra"
                if NativeUnitVisualResolver.animationUnitName(unit: unit, countryCode: code, manifest: anim) != nil { visualResolved += 1 }
            }
            for object in battle.objects {
                objectCount += 1
                let code = battle.countries.first(where: { $0.index == object.owner })?.code ?? "fra"
                if let key = NativeBuildingVisualResolver.spriteKey(object: object, countryCode: code) {
                    objectEligible += 1
                    if sprites[key] != nil { objectResolved += 1 }
                }
            }
        }
        if visualResolved != battleUnitCount { errors.append("battle-unit visual resolution \(visualResolved)/\(battleUnitCount)") }
        if objectResolved != objectEligible { errors.append("battle-object sprite resolution \(objectResolved)/\(objectEligible)") }
        if let conquest = battles.battles.first(where: { $0.file == "conquest1.btl" }) {
            let ledgers = CountryTurnCore.buildLedgers(conquest, mode: .conquest, playerOwner: 3)
            if ledgers[3] != CountryResources(money: 50, industry: 70, food: 500) { errors.append("conquest Russia ledger mismatch") }
            if CountryTurnCore.relation(conquest, 0, 1, mode: .conquest, playerOwner: 0) != .hostile { errors.append("conquest relation mismatch") }
            if CountryTurnCore.relation(conquest, 0, 14, mode: .conquest, playerOwner: 0) != .neutral { errors.append("conquest neutral mismatch") }
        } else { errors.append("conquest1 missing") }
        if let cph = battles.battles.first(where: { $0.file == "campaign2_06.btl" }) {
            if CountryTurnCore.relation(cph, 0, 1, mode: .campaign, playerOwner: 0) != .hostile { errors.append("campaign player hostility mismatch") }
            if CountryTurnCore.relation(cph, 1, 8, mode: .campaign, playerOwner: 0) != .ally { errors.append("campaign enemy bloc mismatch") }
        } else { errors.append("campaign2_06 missing") }
        let eu=worlds.worlds["europe"]
        return .init(battleCount:battles.battles.count,worldCount:worlds.worlds.count,europeSize:eu.map{"\($0.width)x\($0.height)"} ?? "missing",animationUnitCount:anim.units.count,animationAssetCount:anim.assets.count,animationFPS:anim.fps,defMotionUnitCount:dm.unitCount,defMotionMotionCount:dm.motionCount,bileResourceCount:bins.count,bileDecoded:decoded,battleUnitCount:battleUnitCount,battleUnitVisualResolved:visualResolved,battleObjectCount:objectCount,battleObjectSpriteEligible:objectEligible,battleObjectSpriteResolved:objectResolved,errors:errors)
    }
}
