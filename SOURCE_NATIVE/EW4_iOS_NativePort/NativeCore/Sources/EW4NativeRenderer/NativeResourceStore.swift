#if canImport(Foundation)
import Foundation
import EW4NativeCore

public final class NativeResourceStore: @unchecked Sendable {
    public let bundle: Bundle
    public let resourceRoot: URL

    public init(bundle: Bundle = .main) throws {
        self.bundle = bundle
        if let url = bundle.resourceURL?.appendingPathComponent("GameAssets/Resources"), FileManager.default.fileExists(atPath: url.path) {
            self.resourceRoot = url
        } else if let url = bundle.resourceURL {
            self.resourceRoot = url
        } else {
            throw CocoaError(.fileNoSuchFile)
        }
    }

    public func url(_ folder: String, _ file: String) -> URL {
        resourceRoot.appendingPathComponent(folder).appendingPathComponent(file)
    }
    public func battles() throws -> BattlesRuntimeFile { try ResourceLoader.decode(BattlesRuntimeFile.self, from: url("Data", "battles_runtime.json")) }
    public func worlds() throws -> WorldMapsFile { try ResourceLoader.decode(WorldMapsFile.self, from: url("Data", "worldmaps.json")) }
    public func animations() throws -> NativeAnimationManifest { try ResourceLoader.decode(NativeAnimationManifest.self, from: url("Data", "native_animation_core877.json")) }
    public func sprites() throws -> [String: SpriteManifestEntry] { try ResourceLoader.decode([String: SpriteManifestEntry].self, from: resourceRoot.appendingPathComponent("sprite_manifest.json")) }
    public func armyStats() throws -> ArmyStatsCatalog { try ResourceLoader.decode(ArmyStatsCatalog.self, from: url("Data", "army_stats.json")) }
    public func constructions() throws -> NativeConstructionCatalog { try ResourceLoader.decode(NativeConstructionCatalog.self, from: url("Data", "constructions.json")) }
    public func recruitCards() throws -> NativeRecruitCardCatalog { try ResourceLoader.decode(NativeRecruitCardCatalog.self, from: url("Data", "cards.json")) }
    public func buildCards() throws -> NativeBuildCardCatalog { try ResourceLoader.decode(NativeBuildCardCatalog.self, from: url("Data", "build_cards.json")) }
    public func installations() throws -> NativeInstallationCatalog { try ResourceLoader.decode(NativeInstallationCatalog.self, from: url("Data", "installations.json")) }
    public func items() throws -> NativeItemEffectCatalog { try ResourceLoader.decode(NativeItemEffectCatalog.self, from: url("Data", "items.json")) }
    public func playerGeneralOverrides() throws -> NativePlayerGeneralOverrides { try ResourceLoader.decode(NativePlayerGeneralOverrides.self, from: url("Data", "player_general_overrides.json")) }
    public func playerPrincessOverrides() throws -> NativePlayerPrincessOverrides { try ResourceLoader.decode(NativePlayerPrincessOverrides.self, from: url("Data", "player_princess_overrides.json")) }
    public func battleEvents() throws -> NativeBattleEventCatalogFile { try ResourceLoader.decode(NativeBattleEventCatalogFile.self, from: url("Data", "battle_native_triggers.json")) }
    public func battleTaverns() throws -> NativeJSONValue { try ResourceLoader.decode(NativeJSONValue.self, from: url("Data", "battle_taverns.json")) }
    public func battleItemStores() throws -> NativeJSONValue { try ResourceLoader.decode(NativeJSONValue.self, from: url("Data", "battle_itemstores.json")) }
    public func tutorials() throws -> NativeTutorialCatalog { try ResourceLoader.decode(NativeTutorialCatalog.self, from: url("Data", "native_tutorial_scripts.json")) }
    public func triggerTargets() throws -> NativeTriggerTargetCatalogFile { try ResourceLoader.decode(NativeTriggerTargetCatalogFile.self, from: url("Data", "native_trigger_targets.json")) }
    public func campaignTargets() throws -> NativeCampaignTargetManifestFile { try ResourceLoader.decode(NativeCampaignTargetManifestFile.self, from: url("Data", "native_campaign_targets.json")) }
    public func stringsCN() throws -> [String: String] { try ResourceLoader.decode([String: String].self, from: url("Data", "strings_cn.json")) }
    public func commanders() throws -> [Int: Commander] {
        let raw = try ResourceLoader.decode([String: Commander].self, from: url("Data", "commanders.json"))
        return Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    }
    public func portraitManifest() throws -> [String: String] { try ResourceLoader.decode([String: String].self, from: url("Data", "portrait_manifest.json")) }
    public func defMotion() throws -> DefMotionFile { DefMotionParser.parse(try String(contentsOf: url("Bile", "def_motion.xml"), encoding: .utf8)) }
    public func bile(resource: String) throws -> CompactBILE { try CompactBILE(data: Data(contentsOf: url("Bile", resource + ".bin")), textureXML: String(contentsOf: url("Bile", resource + ".xml"), encoding: .utf8)) }
    public func bileAtlasURL(resource: String) -> URL { url("Bile", resource + ".png") }

    public func spriteURL(manifestPath: String) -> URL {
        let prefix = "assets/sprites/"
        let relative = manifestPath.hasPrefix(prefix) ? String(manifestPath.dropFirst(prefix.count)) : manifestPath
        return url("Sprites", relative)
    }
}
#endif
