import Foundation

public enum BILEError: Error, CustomStringConvertible {
    case invalidMagic, missingChunk(String), outOfBounds, recordStartsMismatch, missingItem(String)
    public var description: String {
        switch self { case .invalidMagic: return "not BILE"; case .missingChunk(let s): return "\(s) missing"; case .outOfBounds: return "binary read out of bounds"; case .recordStartsMismatch: return "BILE record starts mismatch"; case .missingItem(let s): return "motion item not found: \(s)" }
    }
}

public struct Affine2D: Equatable, Sendable {
    public var a,b,c,d,tx,ty: Double
    public static let identity = Affine2D(a:1,b:0,c:0,d:1,tx:0,ty:0)
    public func multiplied(by m: Affine2D) -> Affine2D {
        Affine2D(a:a*m.a+c*m.b, b:b*m.a+d*m.b, c:a*m.c+c*m.d, d:b*m.c+d*m.d, tx:a*m.tx+c*m.ty+tx, ty:b*m.tx+d*m.ty+ty)
    }
    public func transform(x: Double, y: Double) -> NativePoint { .init(x:a*x+c*y+tx, y:b*x+d*y+ty) }
}

public struct BILEImageInfo: Equatable, Sendable { public let x,y,w,h,refx,refy: Double }
public struct BILEItem: Sendable { public let index: Int; public let name: String; public let refx, refy: Double; public let type: UInt32; public let frames,layers,frameRecords,indexRecords: Int }
public struct BILEPrimitive: Sendable { public let name: String; public let transform: Affine2D; public let alpha: Double; public let image: BILEImageInfo }
private struct BILEChunk { let offset: Int; let size: Int }
private struct BILEKeyframe { let bmr:(UInt16,UInt16,UInt16,UInt16); let bxd:(UInt32,UInt32) }

public final class CompactBILE: @unchecked Sendable {
    public let version: UInt32
    public let headerSize: Int
    public let chunkCount: Int
    public let fps: Double
    public let items: [BILEItem]
    public let images: [String:BILEImageInfo]
    public let nameToItem: [String:Int]
    private let data: Data
    private let chunks: [String:BILEChunk]
    private let stringStart: Int, stringEnd: Int
    private let bele, bxdi, bmrf, byal: [Int]
    private let layerStart, frameStart, indexStart: [Int]

    public init(data: Data, textureXML: String = "") throws {
        self.data = data
        guard data.count >= 20, String(bytes: data[0..<4], encoding: .ascii) == "BILE" else { throw BILEError.invalidMagic }
        version = try Self.u32(data,4)
        headerSize = Int(try Self.u16(data,12))
        chunkCount = Int(try Self.u16(data,14))
        fps = Double(try Self.f32(data,16))
        var found: [String:BILEChunk] = [:]
        var off = headerSize
        for _ in 0..<chunkCount {
            guard off+8 <= data.count else { throw BILEError.outOfBounds }
            let tag = String(bytes:data[off..<off+4], encoding:.ascii) ?? "????"
            let size = Int(try Self.u32(data,off+4))
            guard size > 0, off+size <= data.count else { throw BILEError.outOfBounds }
            found[tag] = .init(offset:off,size:size); off += size
        }
        chunks = found
        guard let brts = found["BRTS"] else { throw BILEError.missingChunk("BRTS") }
        stringStart = brts.offset+12; stringEnd = brts.offset+brts.size
        guard let bmti = found["BMTI"] else { throw BILEError.missingChunk("BMTI") }
        let itemCount = Int(try Self.u32(data,bmti.offset+8)), itemBase=bmti.offset+16
        var built:[BILEItem]=[]; var names:[String:Int]=[:]
        for i in 0..<itemCount {
            let o=itemBase+i*56
            let nameOffset=Int(try Self.u32(data,o+4))
            let name=try Self.readCString(data, start:stringStart+nameOffset, end:stringEnd)
            let item=BILEItem(index:i,name:name,refx:Double(try Self.f32(data,o+8)),refy:Double(try Self.f32(data,o+12)),type:try Self.u32(data,o+24),frames:Int(try Self.u32(data,o+28)),layers:Int(try Self.u32(data,o+32)),frameRecords:Int(try Self.u32(data,o+36)),indexRecords:Int(try Self.u32(data,o+40)))
            built.append(item); names[name]=i
        }
        items=built; nameToItem=names
        bele = try Self.recordOffsets(data, found, "BELE", 44)
        bxdi = try Self.recordOffsets(data, found, "BXDI", 8)
        bmrf = try Self.recordOffsets(data, found, "BMRF", 8)
        byal = try Self.recordOffsets(data, found, "BYAL", 8)
        var ls:[Int]=[],fs:[Int]=[],xs:[Int]=[]; var aa=0,bb=0,cc=0
        for item in built { ls.append(aa);fs.append(bb);xs.append(cc);aa += item.layers;bb += item.frameRecords;cc += item.indexRecords }
        guard aa==byal.count, bb==bmrf.count, cc==bxdi.count else { throw BILEError.recordStartsMismatch }
        layerStart=ls;frameStart=fs;indexStart=xs
        images=Self.parseTextureXML(textureXML)
    }

    private static func bytes<T: FixedWidthInteger>(_ data: Data, _ offset:Int, as:T.Type) throws -> T {
        guard offset >= 0, offset+MemoryLayout<T>.size <= data.count else { throw BILEError.outOfBounds }
        return data.withUnsafeBytes { raw in raw.loadUnaligned(fromByteOffset: offset, as:T.self) }.littleEndian
    }
    private static func u16(_ d:Data,_ o:Int)throws->UInt16{try bytes(d,o,as:UInt16.self)}
    private static func u32(_ d:Data,_ o:Int)throws->UInt32{try bytes(d,o,as:UInt32.self)}
    private static func f32(_ d:Data,_ o:Int)throws->Float{ Float(bitPattern: try u32(d,o)) }
    private static func readCString(_ d:Data,start:Int,end:Int)throws->String { guard start>=0,start<end,end<=d.count else{throw BILEError.outOfBounds}; var e=start; while e<end && d[e] != 0 { e += 1 }; return String(decoding:d[start..<e],as:UTF8.self) }
    private static func recordOffsets(_ d:Data,_ chunks:[String:BILEChunk],_ tag:String,_ size:Int)throws->[Int]{ guard let c=chunks[tag] else{throw BILEError.missingChunk(tag)};let n=Int(try u32(d,c.offset+8)),s=c.offset+16;return (0..<n).map{s+$0*size} }

    public static func parseTextureXML(_ text:String) -> [String:BILEImageInfo] {
        guard let re = try? NSRegularExpression(pattern:#"<Image\b([^>]*)/?>"#) else { return [:] }
        let ns=text as NSString; var out:[String:BILEImageInfo]=[:]
        for m in re.matches(in:text, range:NSRange(location:0,length:ns.length)) {
            let attrsText=ns.substring(with:m.range(at:1)); let a=parseAttributes(attrsText)
            var name=a["name"] ?? ""; if name.hasSuffix(".png") { name=String(name.dropLast(4)) }; if name.isEmpty { continue }
            
            let x = Double(a["x"] ?? "0") ?? 0
            let y = Double(a["y"] ?? "0") ?? 0
            let w = Double(a["w"] ?? "0") ?? 0
            let h = Double(a["h"] ?? "0") ?? 0
            let refx = Double(a["refx"] ?? "0") ?? 0
            let refy = Double(a["refy"] ?? "0") ?? 0
            out[name] = BILEImageInfo(x: x, y: y, w: w, h: h, refx: refx, refy: refy)
        }
        return out
    }
    private static func parseAttributes(_ text:String)->[String:String]{ guard let re=try? NSRegularExpression(pattern:#"([A-Za-z_][\w:-]*)=\"([^\"]*)\""#) else{return[:]}; let ns=text as NSString; var out:[String:String]=[:]; for m in re.matches(in:text,range:NSRange(location:0,length:ns.length)){out[ns.substring(with:m.range(at:1))]=ns.substring(with:m.range(at:2))}; return out }

    private func layerKeyframes(_ itemIndex:Int)throws->[[BILEKeyframe]] {
        let item=items[itemIndex],ls=layerStart[itemIndex],fs=frameStart[itemIndex],xs=indexStart[itemIndex]
        var fc=fs,xc=xs,out:[[BILEKeyframe]]=[]
        for li in 0..<item.layers {
            let n=Int(try Self.u32(data,byal[ls+li])); var layer:[BILEKeyframe]=[]
            for k in 0..<n { let bo=bmrf[fc+k],xo=bxdi[xc+k]; layer.append(.init(bmr:(try Self.u16(data,bo),try Self.u16(data,bo+2),try Self.u16(data,bo+4),try Self.u16(data,bo+6)),bxd:(try Self.u32(data,xo),try Self.u32(data,xo+4)))) }
            out.append(layer);fc += n;xc += n
        }
        return out
    }
    private func beleValues(_ idx:Int)throws->[Double]{let o=bele[idx];return try stride(from:0,to:28,by:4).map{Double(try Self.f32(data,o+$0))}}
    private func keyAt(_ itemIndex:Int,_ layerIndex:Int,_ frame:Int)throws->(bmr:(UInt16,UInt16,UInt16,UInt16),bxd:(UInt32,UInt32),M:Affine2D,alpha:Double){
        let kfs=try layerKeyframes(itemIndex)[layerIndex]; var ci=0
        for i in kfs.indices { if Int(kfs[i].bmr.0)<=frame { ci=i } else { break } }
        let cur=kfs[ci]; var vals=try beleValues(Int(cur.bxd.0))
        if ci+1<kfs.count,cur.bmr.1==1 { let nxt=kfs[ci+1]; if nxt.bmr.0>cur.bmr.0,nxt.bxd.1==cur.bxd.1 { let t=Double(frame-Int(cur.bmr.0))/Double(Int(nxt.bmr.0)-Int(cur.bmr.0)); let nv=try beleValues(Int(nxt.bxd.0)); vals=zip(vals,nv).map{$0*(1-t)+$1*t} } }
        return(cur.bmr,cur.bxd,.init(a:vals[0],b:vals[1],c:vals[2],d:vals[3],tx:vals[4],ty:vals[5]),vals[6])
    }

    public func flatten(itemIndex:Int, frame:Int, parent:Affine2D = .identity, alpha:Double = 1) throws -> [BILEPrimitive] {
        var active=Set<Int>(), out:[BILEPrimitive]=[]
        try flattenInto(itemIndex:itemIndex,frame:frame,parent:parent,alpha:alpha,active:&active,out:&out)
        return out
    }
    private func flattenInto(itemIndex:Int,frame:Int,parent:Affine2D,alpha:Double,active:inout Set<Int>,out:inout[BILEPrimitive])throws{
        guard itemIndex>=0,itemIndex<items.count,!active.contains(itemIndex) else{return}; let item=items[itemIndex]
        if item.type==1 { if let info=images[item.name] { out.append(.init(name:item.name,transform:parent,alpha:alpha,image:info)) }; return }
        active.insert(itemIndex); defer{active.remove(itemIndex)}
        let f=max(0,min(frame,max(0,item.frames-1)))
        for li in 0..<item.layers { let rec=try keyAt(itemIndex,li,f); let ref=rec.bxd.1; if ref==0xffffffff {continue}; let childIndex=Int(ref); guard childIndex<items.count else{continue}; let child=items[childIndex]; let childFrame=child.type==1 ? 0 : max(0,min(f-Int(rec.bmr.0),max(0,child.frames-1))); try flattenInto(itemIndex:childIndex,frame:childFrame,parent:parent.multiplied(by:rec.M),alpha:alpha*rec.alpha,active:&active,out:&out) }
    }

    public func itemIndex(named name: String) throws -> Int {
        guard let index = nameToItem[name] else { throw BILEError.missingItem(name) }
        return index
    }

    public func frameBounds(itemIndex: Int, frame: Int) throws -> NativeRect {
        let primitives = try flatten(itemIndex: itemIndex, frame: frame)
        guard !primitives.isEmpty else { return NativeRect(x: 0, y: 0, width: 0, height: 0) }

        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity

        for primitive in primitives {
            let corners: [(Double, Double)] = [
                (0, 0),
                (primitive.image.w, 0),
                (0, primitive.image.h),
                (primitive.image.w, primitive.image.h)
            ]
            for (x, y) in corners {
                let point = primitive.transform.transform(x: x, y: y)
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)
            }
        }
        return NativeRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
