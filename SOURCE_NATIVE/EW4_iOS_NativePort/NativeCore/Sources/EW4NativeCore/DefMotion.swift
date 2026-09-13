import Foundation

public struct DefMotionEntry: Equatable, Sendable { public let type,name:String; public let index:Int; public let direction:String; public let speed:Double; public let effect:String? }
public struct DefMotionUnit: Equatable, Sendable { public let name,resource:String; public let x,y:Double; public let direction:String?; public let motions:[DefMotionEntry] }
public struct DefMotionFile: Sendable { public let units:[String:DefMotionUnit]; public let unitOrder:[String]; public var unitCount:Int{unitOrder.count}; public var motionCount:Int{unitOrder.reduce(0){$0+(units[$1]?.motions.count ?? 0)}} }

public enum DefMotionParser {
    public static func parse(_ text:String)->DefMotionFile{
        let ns=text as NSString; guard let ure=try? NSRegularExpression(pattern:#"<Unit\b([^>]*)>([\s\S]*?)</Unit>"#), let mre=try? NSRegularExpression(pattern:#"<Motion\b([^>]*)/?>"#) else{return .init(units:[:],unitOrder:[])}
        var units:[String:DefMotionUnit]=[:], order:[String]=[]
        for um in ure.matches(in:text,range:NSRange(location:0,length:ns.length)){
            let ua=attrs(ns.substring(with:um.range(at:1))), body=ns.substring(with:um.range(at:2)); let bns=body as NSString; var motions:[DefMotionEntry]=[]
            for mm in mre.matches(in:body,range:NSRange(location:0,length:bns.length)){let a=attrs(bns.substring(with:mm.range(at:1)));motions.append(.init(type:a["type"] ?? "",name:a["name"] ?? "",index:Int(a["index"] ?? "0") ?? 0,direction:a["dir"] ?? "all",speed:Double(a["speed"] ?? "1") ?? 1,effect:a["effect"]))}
            let u=DefMotionUnit(name:ua["name"] ?? "",resource:ua["res"] ?? "",x:Double(ua["x"] ?? "0") ?? 0,y:Double(ua["y"] ?? "0") ?? 0,direction:ua["dir"],motions:motions); if !u.name.isEmpty{units[u.name]=u;order.append(u.name)}
        }
        return .init(units:units,unitOrder:order)
    }
    public static func select(unit:DefMotionUnit,type:String,index:Int=0,direction:String="all")->DefMotionEntry?{let matches=unit.motions.filter{$0.type==type&&$0.index==index};if let e=matches.first(where:{$0.direction==direction}){return e};if direction=="all",matches.count==1{return matches[0]};return matches.first(where:{$0.direction=="all"})}
    private static func attrs(_ text:String)->[String:String]{guard let re=try? NSRegularExpression(pattern:#"([A-Za-z_][\w:-]*)=\"([^\"]*)\""#)else{return[:]};let ns=text as NSString;var out:[String:String]=[:];for m in re.matches(in:text,range:NSRange(location:0,length:ns.length)){out[ns.substring(with:m.range(at:1))]=ns.substring(with:m.range(at:2))};return out}
}
