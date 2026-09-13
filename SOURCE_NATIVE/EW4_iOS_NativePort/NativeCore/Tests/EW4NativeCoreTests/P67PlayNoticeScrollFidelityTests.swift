import Foundation
import Testing
@testable import EW4NativeCore

@Test func p67PlayNoticeXMLAndFrozenContentAreComplete() throws {
    let xml = try String(contentsOf: TestResourcePaths.data("original_layout-568h.xml"), encoding: .utf8)
    let strings = try ResourceLoader.decode([String: String].self, from: TestResourcePaths.data("strings_cn.json"))
    #expect(xml.contains("<Layout id=\"form_playnotice\" type=\"user_window\" w=\"400\" h=\"225\""))
    #expect(xml.contains("id=\"group_conquest\" type=\"groupbox\" x=\"5\" y=\"33\" w=\"390\" h=\"186\" frame=\"common_lineframe_bold.png\""))
    #expect(xml.contains("type=\"HtmlBox\" font=\"font_text_1\" maxrows=\"999\" rowblank=\"20\" text=\"html_notice\" color=\"80,80,80,255\" scrollback=\"scrollbar_gray.png\" scrollbar=\"scrollbar_darkgray.png\""))
    #expect(NativeOriginalPlayNoticeCore.lines(from: strings["html_notice"] ?? "").count == 24)
}

@Test func p67PlayNoticeGeometryAndScrollMetricsMatchOriginalContract() {
    #expect(NativeOriginalFormGeometryCore.Tutorial.playNoticeFrame == NativeRect(x:84,y:47,width:400,height:225))
    #expect(NativeOriginalFormGeometryCore.Tutorial.playNoticeViewport == NativeRect(x:89,y:80,width:390,height:186))
    #expect(NativeOriginalPlayNoticeCore.rowSpacing == 20)
    #expect(NativeOriginalPlayNoticeCore.viewportHeight == 186)
    #expect(NativeOriginalPlayNoticeCore.contentHeight(lineCount:24) == 480)
    #expect(NativeOriginalPlayNoticeCore.maxScroll(lineCount:24) == 294)
    #expect(NativeOriginalPlayNoticeCore.clampedScroll(-10,lineCount:24) == 0)
    #expect(NativeOriginalPlayNoticeCore.clampedScroll(500,lineCount:24) == 294)
}

@Test func p67RendererUsesClippedScrollableNoticeAndCloseOnlyDismissal() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalTutorialScene.swift"), encoding: .utf8)
    #expect(source.contains("SKCropNode()"))
    #expect(source.contains("scrollbar_gray.png"))
    #expect(source.contains("scrollbar_darkgray.png"))
    #expect(source.contains("NativeOriginalPlayNoticeCore.lines"))
    #expect(source.contains("draggingNoticeContent"))
    #expect(source.contains("draggingNoticeScrollbar"))
    #expect(source.contains("if contains(noticeCloseRect,p){noticeVisible=false"))
    #expect(!source.contains("prefix(11)"))
    #expect(!source.contains("if noticeVisible{noticeVisible=false"))
    let spriteRoot = TestResourcePaths.resources.appendingPathComponent("Sprites/image_ui_hd", isDirectory:true)
    #expect(FileManager.default.fileExists(atPath:spriteRoot.appendingPathComponent("scrollbar_gray.png").path))
    #expect(FileManager.default.fileExists(atPath:spriteRoot.appendingPathComponent("scrollbar_darkgray.png").path))
    #expect(FileManager.default.fileExists(atPath:spriteRoot.appendingPathComponent("common_lineframe_bold.png").path))
}
