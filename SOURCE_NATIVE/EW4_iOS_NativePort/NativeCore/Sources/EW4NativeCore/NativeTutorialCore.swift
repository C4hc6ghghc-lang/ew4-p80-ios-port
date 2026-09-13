import Foundation

public struct NativeTutorialCatalog: Decodable, Equatable, Sendable {
    public let format: String
    public let mapWidth: Int
    public let scripts: [String: NativeTutorialScript]
}

public struct NativeTutorialScript: Decodable, Equatable, Sendable {
    public let source: String
    public let sha256: String
    public let commandCount: Int
    public let commands: [NativeTutorialCommand]
}

public struct NativeTutorialCommand: Decodable, Equatable, Sendable {
    public let name: String
    public let id: Int?
    public let x: Int?
    public let y: Int?
    public let w: Int?
    public let h: Int?
    public let row: Int?
    public let string: String?
}

public enum NativeTutorialWait: Equatable, Sendable {
    case touch
    case area(Int)
    case ui(name: String, row: Int?)
    case action
}

public enum NativeTutorialEffect: Equatable, Sendable {
    case seed(Int)
    case showText(Int)
    case hideText
    case drawUIRect(NativeTutorialCommand)
    case drawWorldRect(NativeTutorialCommand, HexCell?)
    case clearRect
    case moveToArea(HexCell?)
    case selectArea(HexCell?)
    case unselectArea(HexCell?)
    case unknown(NativeTutorialCommand)
    case exit
}

public struct NativeTutorialRunner: Equatable, Sendable {
    public private(set) var commands: [NativeTutorialCommand]
    public private(set) var programCounter: Int = 0
    public private(set) var wait: NativeTutorialWait?
    public private(set) var done = false
    public private(set) var seed = 0
    public private(set) var lastCommand: NativeTutorialCommand?
    public let mapWidth: Int

    public init(commands: [NativeTutorialCommand], mapWidth: Int = 79) {
        self.commands = commands
        self.mapWidth = max(1, mapWidth)
    }

    public mutating func start() -> [NativeTutorialEffect] { pump() }

    public mutating func notifyTouch() -> [NativeTutorialEffect] {
        guard wait == .touch else { return [] }
        return resolveWait()
    }

    public mutating func notifyArea(_ id: Int) -> [NativeTutorialEffect] {
        guard wait == .area(id) else { return [] }
        return resolveWait()
    }

    public mutating func notifyArea(q: Int, r: Int) -> [NativeTutorialEffect] {
        notifyArea(q + mapWidth * r)
    }

    public mutating func notifyUI(_ name: String, row: Int? = nil) -> [NativeTutorialEffect] {
        guard case .ui(let expected, let expectedRow) = wait, expected == name else { return [] }
        if let expectedRow, expectedRow != row { return [] }
        return resolveWait()
    }

    public mutating func notifyAction() -> [NativeTutorialEffect] {
        guard wait == .action else { return [] }
        return resolveWait()
    }

    public func areaCell(_ id: Int?) -> HexCell? {
        guard let id, id >= 0 else { return nil }
        return HexCell(q: id % mapWidth, r: id / mapWidth)
    }

    private mutating func resolveWait() -> [NativeTutorialEffect] {
        wait = nil
        programCounter += 1
        return pump()
    }

    private mutating func pump() -> [NativeTutorialEffect] {
        var effects: [NativeTutorialEffect] = []
        while !done && wait == nil && programCounter < commands.count {
            let command = commands[programCounter]
            lastCommand = command
            let name = command.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch name {
            case "wait touch": wait = .touch; return effects
            case "wait area": wait = .area(command.id ?? -1); return effects
            case "wait ui": wait = .ui(name: command.string ?? "", row: command.row); return effects
            case "wait action": wait = .action; return effects
            case "rand seed": seed = command.id ?? 0; effects.append(.seed(seed))
            case "show text": effects.append(.showText(command.id ?? 0))
            case "hide text": effects.append(.hideText)
            case "draw ui rect": effects.append(.drawUIRect(command))
            case "draw rect": effects.append(.drawWorldRect(command, areaCell(command.id)))
            case "clear rect": effects.append(.clearRect)
            case "moveto area": effects.append(.moveToArea(areaCell(command.id)))
            case "sel area": effects.append(.selectArea(areaCell(command.id)))
            case "unsel area": effects.append(.unselectArea(areaCell(command.id)))
            case "exit": done = true; effects.append(.exit); return effects
            default: effects.append(.unknown(command))
            }
            programCounter += 1
        }
        if !done && programCounter >= commands.count {
            done = true
            effects.append(.exit)
        }
        return effects
    }
}
