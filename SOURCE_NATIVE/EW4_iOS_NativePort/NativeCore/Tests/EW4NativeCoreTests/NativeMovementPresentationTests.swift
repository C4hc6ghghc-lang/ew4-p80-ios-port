import Testing
@testable import EW4NativeCore

@Test func movementPresentationDurationMatchesP39Contract() {
    #expect(NativeMovementPresentationCore.durationMilliseconds(path: [HexCell(q: 0, r: 0)]) == 0)
    #expect(NativeMovementPresentationCore.durationMilliseconds(path: [HexCell(q: 0, r: 0), HexCell(q: 1, r: 0)]) == 220)
    #expect(NativeMovementPresentationCore.durationMilliseconds(path: (0...4).map { HexCell(q: $0, r: 0) }) == 600)
    #expect(NativeMovementPresentationCore.durationMilliseconds(path: (0...20).map { HexCell(q: $0, r: 0) }) == 1180)
    #expect(NativeMovementPresentationCore.durationMilliseconds(path: (0...4).map { HexCell(q: $0, r: 0) }, fastAI: true) == 80)
}

@Test func movementPresentationInterpolatesAlongAuthoredHexPath() throws {
    let path = [HexCell(q: 1, r: 2), HexCell(q: 2, r: 2), HexCell(q: 2, r: 3)]
    let duration = NativeMovementPresentationCore.durationMilliseconds(path: path)
    let start = try #require(NativeMovementPresentationCore.sample(path: path, elapsedMilliseconds: 0, durationMilliseconds: duration))
    #expect(start.point == NativeHexGeometry.cellCenter(path[0]))
    let mid = try #require(NativeMovementPresentationCore.sample(path: path, elapsedMilliseconds: duration * 0.5, durationMilliseconds: duration))
    #expect(mid.segmentIndex == 1)
    #expect(abs(mid.fraction) < 0.001)
    let end = try #require(NativeMovementPresentationCore.sample(path: path, elapsedMilliseconds: duration, durationMilliseconds: duration))
    #expect(end.completed)
    #expect(end.point == NativeHexGeometry.cellCenter(path.last!))
}
