import Foundation

public struct NativeOriginalConquestScenario: Equatable, Sendable {
    public let index: Int
    public let textureYear: String
    public let location: String
    public let displayYear: String
    public let map: String
    public init(index: Int, textureYear: String, location: String, displayYear: String, map: String) {
        self.index = index; self.textureYear = textureYear; self.location = location; self.displayYear = displayYear; self.map = map
    }
}


public struct NativeOriginalCampaignLine: Equatable, Sendable {
    public let name: String
    public let hide: Int
    public let start: Int
    public let end: Int
    public let stars: Int
    public let countries: [String]
    public init(name: String, hide: Int, start: Int, end: Int, stars: Int, countries: [String]) {
        self.name = name; self.hide = hide; self.start = start; self.end = end; self.stars = stars; self.countries = countries
    }
    public var titleStringKey: String { "name_\(name)" }
}

public struct NativeCampaignCompleteContent: Equatable, Sendable {
    public let zone: Int
    public let reward: NativeCampaignCompletionReward
    public init(zone: Int, reward: NativeCampaignCompletionReward) { self.zone = zone; self.reward = reward }
}

public struct NativeConquestChallengeContent: Equatable, Sendable {
    public let prepared: NativeConquestVictoryPrepared
    public let homeButtonStringKey: String
    public init(prepared: NativeConquestVictoryPrepared, homeButtonStringKey: String) {
        self.prepared = prepared; self.homeButtonStringKey = homeButtonStringKey
    }
}

public struct NativeConquestSummaryContent: Equatable, Sendable {
    public let scenario: NativeOriginalConquestScenario
    public let result: NativeConquestAchievementResult
    public let round: Int
    public let collectedMedal: Int
    public init(scenario: NativeOriginalConquestScenario, result: NativeConquestAchievementResult, round: Int, collectedMedal: Int) {
        self.scenario = scenario; self.result = result; self.round = round; self.collectedMedal = collectedMedal
    }
}

/// Original-EW4 568h outer Campaign/Conquest geometry recovered from
/// `original_layout-568h.xml` plus the mature P39 568x320 placement contracts.
/// It intentionally contains no modern adaptive-layout rules.
public enum NativeOriginalOuterShellCore {
    public enum CampaignSelect {
        public static let screen = NativeRect(x: 0, y: 0, width: 568, height: 320)
        public static let zoneButtons: [NativeRect] = [
            NativeRect(x: 300, y: 118, width: 54, height: 62),
            NativeRect(x: 356, y: 70, width: 54, height: 62),
            NativeRect(x: 415, y: 140, width: 54, height: 62),
            NativeRect(x: 490, y: 95, width: 54, height: 62),
            NativeRect(x: 76, y: 103, width: 54, height: 62),
            NativeRect(x: 265, y: 38, width: 54, height: 62),
        ]
        public static let zoneButtonImages = [
            "button_choosebattlezone_france.png",
            "button_choosebattlezone_coalition.png",
            "button_choosebattlezone_holyroman.png",
            "button_choosebattlezone_east.png",
            "button_choosebattlezone_usa.png",
            "button_choosebattlezone_uk.png",
        ]
        public static let zoneNames = ["帝国雄鹰", "反法同盟", "神圣罗马帝国", "东方霸主", "美国的崛起", "日不落帝国"]
    }

    public enum CampaignInfo {
        public static let frame = NativeRect(x: 0, y: 0, width: 155, height: 83)
        public static let back = NativeRect(x: -9, y: -4, width: 173, height: 70)
        public static let arrow = NativeRect(x: 60, y: 56, width: 31, height: 22)
        public static let title = NativeRect(x: 0, y: 0, width: 139, height: 19)
        public static let age = NativeRect(x: 0, y: 21, width: 139, height: 25)
        public static let tips = NativeRect(x: 7, y: 25, width: 124, height: 25)
        public static let nations = NativeRect(x: 4, y: 34, width: 150, height: 15)
        public static let confirm = NativeRect(x: 110, y: 28, width: 31, height: 32)

        // Frozen `def_battleline.xml` rows, preserved by the mature P25 controller.
        public static let lines: [NativeOriginalCampaignLine] = [
            .init(name: "imperialeagle", hide: 0, start: 1793, end: 1820, stars: 10, countries: ["fra"]),
            .init(name: "coalition", hide: 0, start: 1792, end: 1815, stars: 10, countries: ["aus", "pru", "rus", "gbr"]),
            .init(name: "romanempire", hide: 0, start: 1807, end: 1822, stars: 10, countries: ["hre", "aus", "pru"]),
            .init(name: "eastern", hide: 0, start: 1798, end: 1820, stars: 10, countries: ["tur", "rus"]),
            .init(name: "america", hide: 0, start: 1775, end: 1822, stars: 10, countries: ["usa"]),
            .init(name: "neversets", hide: 1, start: 1775, end: 1814, stars: 10, countries: ["gbr"]),
        ]

        public static func line(zone: Int) -> NativeOriginalCampaignLine? {
            let index = zone - 1
            return lines.indices.contains(index) ? lines[index] : nil
        }

        /// P25 mature placement: anchor to the exact original campaign pin and clamp to 568x320.
        /// The original .so offset is unavailable, so this remains the best frozen mature placement contract.
        public static func screenFrame(zone: Int) -> NativeRect? {
            let index = zone - 1
            guard CampaignSelect.zoneButtons.indices.contains(index) else { return nil }
            let pin = CampaignSelect.zoneButtons[index]
            let x = min(413.0, max(0.0, (pin.origin.x + pin.size.width / 2.0 - 77.5).rounded()))
            let y = min(237.0, max(0.0, (pin.origin.y - 40.0).rounded()))
            return NativeRect(x: x, y: y, width: frame.size.width, height: frame.size.height)
        }

        public static func absolute(_ local: NativeRect, zone: Int) -> NativeRect? {
            guard let screen = screenFrame(zone: zone) else { return nil }
            return NativeRect(x: screen.origin.x + local.origin.x, y: screen.origin.y + local.origin.y, width: local.size.width, height: local.size.height)
        }

        public static func contains(_ point: NativePoint, zone: Int) -> Bool {
            guard let screen = screenFrame(zone: zone) else { return false }
            return point.x >= screen.origin.x && point.x <= screen.origin.x + screen.size.width &&
                point.y >= screen.origin.y && point.y <= screen.origin.y + screen.size.height
        }

        public static func confirmContains(_ point: NativePoint, zone: Int) -> Bool {
            guard let rect = absolute(confirm, zone: zone) else { return false }
            return point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width &&
                point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height
        }
    }

    public enum ConquestSelect {
        public static let screen = NativeRect(x: 0, y: 0, width: 568, height: 320)
        public static let cards: [NativeRect] = [
            NativeRect(x: 52, y: 37, width: 222, height: 83),
            NativeRect(x: 292, y: 37, width: 222, height: 83),
            NativeRect(x: 52, y: 132, width: 222, height: 83),
            NativeRect(x: 292, y: 132, width: 222, height: 83),
            NativeRect(x: 52, y: 227, width: 222, height: 83),
            NativeRect(x: 292, y: 227, width: 222, height: 83),
        ]
        public static let imagePosition = NativeRect(x: 15, y: 46, width: 48, height: 13)
        public static let europeYearX = 65.0
        public static let americaYearX = 78.0
        public static let split = NativeRect(x: 15, y: 61, width: 180, height: 2)
        public static let countries = NativeRect(x: 15, y: 62, width: 200, height: 15)
    }

    public enum CountrySelect {
        public static let frame = NativeRect(x: 0, y: 0, width: 234, height: 150)
        public static let screenFrame = NativeRect(x: 167, y: 85, width: 234, height: 150)
        public static let left = NativeRect(x: 17, y: 36, width: 85, height: 67)
        public static let right = NativeRect(x: 132, y: 36, width: 85, height: 67)
        public static let flagInCard = NativeRect(x: 30, y: 16, width: 25, height: 20)
        public static let nameBoardInCard = NativeRect(x: 0, y: 43, width: 85, height: 25)
        public static let nameInCard = NativeRect(x: 0, y: 45, width: 85, height: 20)
        public static let bottomLine = NativeRect(x: 0, y: 119, width: 234, height: 2)
        public static let bottomFlowerY = 125.0
        public static let closeButton = NativeRect(x: 217, y: -8, width: 25, height: 25)
        public static let confirmButton = NativeRect(x: 211, y: 127, width: 30, height: 30)
    }

    public enum CampaignList {
        public static let listBack = NativeRect(x: 442, y: 23, width: 150, height: 361)
        public static let list = NativeRect(x: 410, y: 23, width: 160, height: 275)
        public static let itemHeight = 45.0
        public static let itemInterval = 2.0
        public static let confirm = NativeRect(x: 468, y: 298, width: 80, height: 22)
        public static let intro = NativeRect(x: 42, y: 232, width: 345, height: 88)
        public static let introBack = NativeRect(x: 51, y: -6.8, width: 303, height: 105)
        public static let commander = NativeRect(x: 0, y: 0, width: 78, height: 78)
        public static let nameBoard = NativeRect(x: 0, y: 70, width: 70, height: 18)
        public static let content = NativeRect(x: 74, y: 3, width: 267, height: 82)
    }

    public enum ConquestList {
        public static let listBack = NativeRect(x: 442, y: 23, width: 160, height: 297)
        public static let list = NativeRect(x: 410, y: 23, width: 160, height: 275)
        public static let itemHeight = 45.0
        public static let itemInterval = 2.0
        public static let confirm = NativeRect(x: 468, y: 298, width: 80, height: 22)
    }

    public enum Complete {
        public static let frame = NativeRect(x: 0, y: 0, width: 346, height: 190)
        public static let screenFrame = NativeRect(x: 111, y: 65, width: 346, height: 190)
        public static let group = NativeRect(x: 0, y: 25, width: 346, height: 165)
        public enum Campaign {
            public static let picture = NativeRect(x: 2, y: 27, width: 343, height: 125)
            public static let awardBar = NativeRect(x: 0, y: 122, width: 346, height: 39)
            public static let awardText = NativeRect(x: 65, y: 136, width: 80, height: 15)
            public static let medal = NativeRect(x: 150, y: 134, width: 18, height: 21)
            public static let medalValue = NativeRect(x: 170, y: 137, width: 28, height: 15)
            public static let badge = NativeRect(x: 200, y: 134, width: 18, height: 21)
            public static let badgeValue = NativeRect(x: 220, y: 137, width: 28, height: 15)
            public static let score = NativeRect(x: 248, y: 134, width: 20, height: 22)
            public static let scoreValue = NativeRect(x: 270, y: 137, width: 35, height: 15)
            public static let ok = NativeRect(x: 317, y: 136, width: 31, height: 31)
        }
        public enum Challenge {
            public static let picture = NativeRect(x: 4, y: 25, width: 338, height: 95)
            public static let description = NativeRect(x: 0, y: 120, width: 346, height: 15)
            public static let asia = NativeRect(x: 40, y: 142, width: 100, height: 35)
            public static let home = NativeRect(x: 205, y: 142, width: 100, height: 35)
            public static let flowerY = 157.0
        }
        public enum Conquest {
            public static let battle = NativeRect(x: 8, y: 40, width: 221, height: 83)
            public static let archive = NativeRect(x: 237, y: 30, width: 104, height: 105)
            public static let ruleTitle = NativeRect(x: 250, y: 140, width: 80, height: 15)
            public static let years = NativeRect(x: 297, y: 166, width: 48, height: 15)
            public static let roundTitle = NativeRect(x: 18, y: 143, width: 80, height: 15)
            public static let roundValue = NativeRect(x: 18, y: 161, width: 80, height: 15)
            public static let medalTitle = NativeRect(x: 125, y: 155, width: 60, height: 15)
            public static let medal = NativeRect(x: 188, y: 153, width: 18, height: 21)
            public static let medalValue = NativeRect(x: 208, y: 156, width: 30, height: 15)
            public static let ok = NativeRect(x: 317, y: 161, width: 31, height: 31)
        }
    }

    public static let conquestScenarios: [NativeOriginalConquestScenario] = [
        .init(index: 1, textureYear: "1793", location: "europe", displayYear: "1798", map: "europe"),
        .init(index: 2, textureYear: "1775", location: "america", displayYear: "1775", map: "america"),
        .init(index: 3, textureYear: "1806", location: "europe", displayYear: "1806", map: "europe"),
        .init(index: 4, textureYear: "1809", location: "europe", displayYear: "1809", map: "europe"),
        .init(index: 5, textureYear: "1812", location: "america", displayYear: "1812", map: "america"),
        .init(index: 6, textureYear: "1815", location: "europe", displayYear: "1815", map: "europe"),
    ]

    public static func conquestScenario(file: String) -> NativeOriginalConquestScenario? {
        guard file.hasPrefix("conquest"), file.hasSuffix(".btl"),
              let index = Int(file.dropFirst("conquest".count).dropLast(".btl".count)) else { return nil }
        return conquestScenarios.first { $0.index == index }
    }

    public static func campaignComplete(zone: Int, reward: NativeCampaignCompletionReward) -> NativeCampaignCompleteContent {
        NativeCampaignCompleteContent(zone: max(1, min(6, zone)), reward: reward)
    }

    public static func conquestChallenge(_ prepared: NativeConquestVictoryPrepared, map: String) -> NativeConquestChallengeContent {
        NativeConquestChallengeContent(
            prepared: prepared,
            homeButtonStringKey: map.lowercased() == "america" ? "btn_chal_amer" : "btn_chal_euro"
        )
    }

    public static func conquestSummary(file: String, result: NativeConquestAchievementResult, round: Int, collectedMedal: Int) -> NativeConquestSummaryContent? {
        guard let scenario = conquestScenario(file: file) else { return nil }
        return NativeConquestSummaryContent(scenario: scenario, result: result, round: max(0, round), collectedMedal: max(0, collectedMedal))
    }
}


public enum NativeOriginalOuterSelectionAction: Equatable, Sendable {
    case campaignZone(Int)
    case conquestScenario(Int)
    case countryLeft
    case countryRight
    case countryClose
    case countryConfirm
    case listRow(Int)
    case listConfirm
}

public extension NativeOriginalOuterShellCore {
    static func campaignSelectionAction(at point: NativePoint) -> NativeOriginalOuterSelectionAction? {
        for (index, rect) in CampaignSelect.zoneButtons.enumerated() where rectContains(rect, point) {
            return .campaignZone(index + 1)
        }
        return nil
    }

    static func conquestSelectionAction(at point: NativePoint) -> NativeOriginalOuterSelectionAction? {
        for (index, rect) in ConquestSelect.cards.enumerated() where rectContains(rect, point) {
            return .conquestScenario(index + 1)
        }
        return nil
    }

    static func countrySelectionAction(at screenPoint: NativePoint) -> NativeOriginalOuterSelectionAction? {
        let local = NativePoint(
            x: screenPoint.x - CountrySelect.screenFrame.origin.x,
            y: screenPoint.y - CountrySelect.screenFrame.origin.y
        )
        if rectContains(CountrySelect.closeButton, local) { return .countryClose }
        if rectContains(CountrySelect.left, local) { return .countryLeft }
        if rectContains(CountrySelect.right, local) { return .countryRight }
        if rectContains(CountrySelect.confirmButton, local) { return .countryConfirm }
        return nil
    }

    static func campaignListAction(at point: NativePoint, firstVisibleRow: Int, rowCount: Int) -> NativeOriginalOuterSelectionAction? {
        if rectContains(CampaignList.confirm, point) { return .listConfirm }
        guard rectContains(CampaignList.list, point) else { return nil }
        let localY = point.y - CampaignList.list.origin.y
        let slot = Int(floor(localY / (CampaignList.itemHeight + CampaignList.itemInterval)))
        let row = firstVisibleRow + max(0, slot)
        return row < rowCount ? .listRow(row) : nil
    }

    static func conquestListAction(at point: NativePoint, firstVisibleRow: Int, rowCount: Int) -> NativeOriginalOuterSelectionAction? {
        if rectContains(ConquestList.confirm, point) { return .listConfirm }
        guard rectContains(ConquestList.list, point) else { return nil }
        let localY = point.y - ConquestList.list.origin.y
        let slot = Int(floor(localY / (ConquestList.itemHeight + ConquestList.itemInterval)))
        let row = firstVisibleRow + max(0, slot)
        return row < rowCount ? .listRow(row) : nil
    }
}

public enum NativeOriginalOuterCompletionAction: Equatable, Sendable {
    case campaignOK
    case challengeAsia
    case challengeHome
    case conquestOK
}

public extension NativeOriginalOuterShellCore {
    static func campaignCompleteAction(at local: NativePoint) -> NativeOriginalOuterCompletionAction? {
        rectContains(Complete.Campaign.ok, local) ? .campaignOK : nil
    }

    static func conquestChallengeAction(at local: NativePoint) -> NativeOriginalOuterCompletionAction? {
        if rectContains(Complete.Challenge.asia, local) { return .challengeAsia }
        if rectContains(Complete.Challenge.home, local) { return .challengeHome }
        return nil
    }

    static func conquestSummaryAction(at local: NativePoint) -> NativeOriginalOuterCompletionAction? {
        rectContains(Complete.Conquest.ok, local) ? .conquestOK : nil
    }

    private static func rectContains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width &&
        point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height
    }
}
