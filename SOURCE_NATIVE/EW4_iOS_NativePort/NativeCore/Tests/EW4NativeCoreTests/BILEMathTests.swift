import Testing
@testable import EW4NativeCore

@Test func affineMatchesJSMulOrder(){
 let p=Affine2D(a:1,b:2,c:3,d:4,tx:5,ty:6),m=Affine2D(a:7,b:8,c:9,d:10,tx:11,ty:12),r=p.multiplied(by:m)
 #expect(r == Affine2D(a:31,b:46,c:39,d:58,tx:52,ty:76))
}
@Test func defMotionSmallFixture(){
 let xml=#"<Root><Unit name="Militia 1" res="army_militia" x="-34" y="-47" dir="1"><Motion type="ready" name="ready1" index="0" dir="all"/><Motion type="attack" name="atk1" index="0" dir="all" speed="1" effect="militia 1"/></Unit></Root>"#
 let d=DefMotionParser.parse(xml); #expect(d.unitCount==1); #expect(d.motionCount==2); #expect(d.units["Militia 1"]?.x == -34); #expect(DefMotionParser.select(unit:d.units["Militia 1"]!,type:"attack")?.name == "atk1")
}
