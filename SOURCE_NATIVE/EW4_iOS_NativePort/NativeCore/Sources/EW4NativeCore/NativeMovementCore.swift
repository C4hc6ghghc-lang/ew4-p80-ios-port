import Foundation

public enum NativeMovementCore {
    private struct QueueEntry { let cell:HexCell; let cost:Int; let serial:Int }

    public static func reachable(start:HexCell,maxCost:Int,canEnter:(HexCell)->Bool,stepCost:(HexCell)->Int)->[HexCell:Int]{
        var result:[HexCell:Int]=[start:0],queue:[QueueEntry]=[.init(cell:start,cost:0,serial:0)],serial=1
        while !queue.isEmpty {
            queue.sort { $0.cost == $1.cost ? $0.serial < $1.serial : $0.cost < $1.cost }
            let current=queue.removeFirst();guard result[current.cell]==current.cost else{continue}
            for next in NativeHexGeometry.neighbors(of:current.cell) {
                guard canEnter(next) else{continue};let nextCost=current.cost+stepCost(next);guard nextCost<=maxCost else{continue}
                if let old=result[next],old<=nextCost{continue};result[next]=nextCost;queue.append(.init(cell:next,cost:nextCost,serial:serial));serial += 1
            }
        }
        result.removeValue(forKey:start);return result
    }

    public static func path(start:HexCell,goal:HexCell,maxCost:Int,canEnter:(HexCell)->Bool,stepCost:(HexCell)->Int)->[HexCell]{
        var costs:[HexCell:Int]=[start:0],previous:[HexCell:HexCell]=[:],queue:[QueueEntry]=[.init(cell:start,cost:0,serial:0)],serial=1
        while !queue.isEmpty {
            queue.sort { $0.cost == $1.cost ? $0.serial < $1.serial : $0.cost < $1.cost }
            let current=queue.removeFirst();guard costs[current.cell]==current.cost else{continue};if current.cell==goal{break}
            for next in NativeHexGeometry.neighbors(of:current.cell) {
                guard canEnter(next) else{continue};let nextCost=current.cost+stepCost(next);guard nextCost<=maxCost else{continue}
                if let old=costs[next],old<=nextCost{continue};costs[next]=nextCost;previous[next]=current.cell;queue.append(.init(cell:next,cost:nextCost,serial:serial));serial += 1
            }
        }
        guard costs[goal] != nil else{return[start,goal]};var reversed:[HexCell]=[];var cursor:HexCell?=goal
        while let cell=cursor {reversed.append(cell);if cell==start{break};cursor=previous[cell]}
        return reversed.reversed()
    }
}
