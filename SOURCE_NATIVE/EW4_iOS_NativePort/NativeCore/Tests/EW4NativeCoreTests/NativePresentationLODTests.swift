import Testing
@testable import EW4NativeCore

@Test func nativePresentationLODFrozen() {
    #expect(NativePresentationLODCore.tacticalVisible(cameraZoom: 0.5))
    #expect(!NativePresentationLODCore.tacticalVisible(cameraZoom: 0.49))
    #expect(NativePresentationLODCore.strategicVisible(cameraZoom: 0.49))
    #expect(NativePresentationLODCore.unitVisualZoom(cameraZoom: 1) == 1)
    #expect(NativePresentationLODCore.unitVisualZoom(cameraZoom: 0.5) == 0.76)
    #expect(abs(NativePresentationLODCore.tacticalContainerScale(cameraZoom: 0.5) - 1.52) < 0.000001)
    #expect(abs(NativePresentationLODCore.strategicContainerScale(cameraZoom: 0.25) - 4) < 0.000001)
}
