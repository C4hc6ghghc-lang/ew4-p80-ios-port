import Foundation

/// Exact geometry recovered from `original_layout-568h.xml`, expressed in the
/// game's existing y-down logical coordinate system. The outer Talk placement
/// uses the mature P39 568×320 adaptation rather than the legacy XML y=450.
public enum NativeOriginalFormGeometryCore {
    public enum Achievement {
        public static let championButton = NativeRect(x: 15, y: 31, width: 49, height: 32)
        public static let rankingButton = NativeRect(x: 80, y: 31, width: 49, height: 32)
        public static let stageStarIcon = NativeRect(x: 193, y: 37, width: 20, height: 20)
        public static let stageStarText = NativeRect(x: 218, y: 38, width: 90, height: 18)
        public static let militaryGroup = NativeRect(x: 327, y: 28, width: 120, height: 38)
        public static let nobilityGroup = NativeRect(x: 448, y: 28, width: 120, height: 38)
        public static let continentOrigins = [75.0, 230.0, 385.0]
        public static let generalList = NativeRect(x: 23, y: 223, width: 522, height: 78)
        public static let generalItemWidth = 58.5
        public static let generalInterval = 6.0
        public static let backButton = NativeRect(x: 0, y: 275, width: 45, height: 45)
        public static let claimFrame = NativeRect(x: 184, y: 110, width: 200, height: 100)
        public static let claimOK = NativeRect(x: 341, y: 173, width: 31, height: 31)
    }
    /// `form_recruitunit` from `original_layout-568h.xml`.  The outer screen
    /// placement preserves the already-shipped Native P55/P59 adaptation; all
    /// content rectangles below are exact XML-local geometry translated into
    /// that screen frame by the renderer.
    public enum Recruit {
        public static let frame = NativeRect(x: 0, y: 0, width: 441, height: 185)
        public static let screenFrame = NativeRect(x: 63.5, y: 66, width: 441, height: 185)
        public static let closeButton = NativeRect(x: 487, y: 58, width: 25, height: 25)
        public static let okButton = NativeRect(x: 462, y: 214, width: 31, height: 31)
        public static let list = NativeRect(x: 2, y: 37, width: 440, height: 65)
        public static let listItemWidth = 72.0
        public static let listInterval = 1.0
        public static let infoGrid = NativeRect(x: 2, y: 109, width: 152, height: 72)
        public static let infoColumns = 4
        public static let infoRowHeight = 24.0
        public static let description = NativeRect(x: 155, y: 109, width: 284, height: 72)
    }

    public enum Defense {
        public static let frame = NativeRect(x: 0, y: 0, width: 300, height: 184)
        public static let screenFrame = NativeRect(x: 134, y: 68, width: 300, height: 184)
        public static let closeButton = NativeRect(x: 417, y: 60, width: 25, height: 25)
        public static let okButton = NativeRect(x: 391, y: 215, width: 31, height: 31)
        public static let list = NativeRect(x: 2, y: 30, width: 298, height: 65)
        public static let itemWidth = 72.0
        public static let interval = 3.0
        // Mature P39 card content contract: transparent 72x65 cell, a centered
        // 42x35 object-fit image, 11px name row, then a 12px resource row.
        public static let itemImage = NativeRect(x: 15, y: 1, width: 42, height: 35)
        public static let itemName = NativeRect(x: 2, y: 36, width: 68, height: 11)
        public static let itemCost = NativeRect(x: 2, y: 47, width: 68, height: 12)
        public static let description = NativeRect(x: 2, y: 98, width: 296, height: 84)
        public static let descriptionTitle = NativeRect(x: 0, y: 1, width: 296, height: 16)
        public static let descriptionText = NativeRect(x: 2, y: 19, width: 292, height: 63)

        public static func itemRect(index: Int) -> NativeRect {
            NativeRect(
                x: screenFrame.origin.x + list.origin.x + Double(index) * (itemWidth + interval),
                y: screenFrame.origin.y + list.origin.y,
                width: itemWidth,
                height: list.size.height
            )
        }

        public static let descriptionScreen = NativeRect(
            x: screenFrame.origin.x + description.origin.x,
            y: screenFrame.origin.y + description.origin.y,
            width: description.size.width,
            height: description.size.height
        )
    }

    public enum UseItem {
        public static let frame = NativeRect(x: 0, y: 0, width: 280, height: 175)
        public static let screenFrame = NativeRect(x: 144, y: 72, width: 280, height: 175)
        public static let closeButton = NativeRect(x: 407, y: 64, width: 25, height: 25)
        public static let okButton = NativeRect(x: 381, y: 210, width: 31, height: 31)
        public static let list = NativeRect(x: 9, y: 35, width: 269, height: 45)
        public static let itemSize = NativeSize(width: 45, height: 45)
        public static let interval = 9.0
        public static let description = NativeRect(x: 2, y: 88, width: 275, height: 84)
        public static let descriptionTitle = NativeRect(x: 0, y: 1, width: 275, height: 16)
        public static let descriptionText = NativeRect(x: 3, y: 19, width: 269, height: 63)

        public static func itemRect(index: Int) -> NativeRect {
            NativeRect(
                x: screenFrame.origin.x + list.origin.x + Double(index) * (itemSize.width + interval),
                y: screenFrame.origin.y + list.origin.y,
                width: itemSize.width,
                height: itemSize.height
            )
        }

        public static let descriptionScreen = NativeRect(
            x: screenFrame.origin.x + description.origin.x,
            y: screenFrame.origin.y + description.origin.y,
            width: description.size.width,
            height: description.size.height
        )
    }


    public enum DeployItem {
        public static let frame = NativeRect(x: 0, y: 0, width: 353, height: 261)
        public static let screenFrame = NativeRect(x: 108, y: 30, width: 353, height: 261)
        public static let closeButton = NativeRect(x: 444, y: 22, width: 25, height: 25)
        public static let generalGroup = NativeRect(x: 113, y: 61, width: 78, height: 119)
        public static let prevButton = NativeRect(x: 113, y: 61, width: 38, height: 20)
        public static let nextButton = NativeRect(x: 153, y: 61, width: 38, height: 20)
        public static let commander = NativeRect(x: 113, y: 82, width: 78, height: 98)
        public static let commanderPortrait = NativeRect(x: 116, y: 82, width: 72, height: 72)
        public static let commanderName = NativeRect(x: 113, y: 154, width: 78, height: 20)

        public static let levelGroup = NativeRect(x: 197, y: 61, width: 110, height: 52)
        public static let militaryRank = NativeRect(x: 212, y: 66, width: 38, height: 23)
        public static let nobilityRank = NativeRect(x: 266, y: 66, width: 38, height: 23)
        public static let hpMarker = NativeRect(x: 208, y: 96, width: 15, height: 13.5)
        public static let hpText = NativeRect(x: 219, y: 98, width: 30, height: 15)
        public static let recoverMarker = NativeRect(x: 262, y: 93, width: 17.5, height: 17.5)
        public static let recoverText = NativeRect(x: 274, y: 98, width: 30, height: 15)

        public static let equipmentGroup = NativeRect(x: 196, y: 111, width: 110, height: 74)
        public static let equipmentTitle = NativeRect(x: 196, y: 115, width: 110, height: 20)
        public static let equipmentSlots = [
            NativeRect(x: 201, y: 136, width: 45, height: 45),
            NativeRect(x: 256, y: 136, width: 45, height: 45),
        ]

        public static let descriptionGroup = NativeRect(x: 313, y: 61, width: 142, height: 120)
        public static let descriptionTitle = NativeRect(x: 313, y: 62, width: 142, height: 18)
        public static let descriptionText = NativeRect(x: 317, y: 81, width: 135, height: 96)
        public static let equipButton = NativeRect(x: 323, y: 162, width: 55, height: 21)

        public static let split = NativeRect(x: 108, y: 185, width: 353, height: 1)
        public static let itemsGroup = NativeRect(x: 112, y: 189, width: 344, height: 99)
        public static let itemGrid = NativeRect(x: 114, y: 191, width: 342, height: 95)
        public static let itemSize = 45.0
        public static let itemGap = 3.0
        public static let itemColumns = 7
        public static let itemRows = 4
        public static let scrollbarTrack = NativeRect(x: 452, y: 191, width: 4, height: 95)

        public static func itemRect(index: Int, scroll: Double) -> NativeRect {
            let col = index % itemColumns, row = index / itemColumns
            return NativeRect(
                x: itemGrid.origin.x + Double(col) * (itemSize + itemGap),
                y: itemGrid.origin.y + Double(row) * (itemSize + itemGap) - scroll,
                width: itemSize,
                height: itemSize
            )
        }

        public static var contentHeight: Double { Double(itemRows) * itemSize + Double(itemRows - 1) * itemGap }
        public static var maxScroll: Double { max(0, contentHeight - itemGrid.size.height) }
        public static func clampedScroll(_ value: Double) -> Double { min(max(0, value), maxScroll) }
        public static var thumbHeight: Double {
            guard contentHeight > itemGrid.size.height else { return itemGrid.size.height }
            return max(12, itemGrid.size.height * itemGrid.size.height / contentHeight)
        }
        public static func thumbOffset(scroll: Double) -> Double {
            guard maxScroll > 0 else { return 0 }
            return (itemGrid.size.height - thumbHeight) * clampedScroll(scroll) / maxScroll
        }
    }

    public enum Tavern {
        public static let frame = NativeRect(x: 0, y: 0, width: 300, height: 275)
        public static let screenFrame = NativeRect(x: 134, y: 22.5, width: 300, height: 275)
        public static let closeButton = NativeRect(x: 417, y: 15.5, width: 25, height: 25)
        public static let rowHeight: Double = 55
        public static let rowTop: Double = 52.5

        public static func row(_ index: Int) -> NativeRect {
            NativeRect(x: 134, y: rowTop + Double(index) * rowHeight, width: 300, height: rowHeight)
        }
        public static func portrait(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 5, y: r.origin.y + 2, width: 50, height: 50)
        }
        public static func info(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 33, y: r.origin.y + 3, width: 24, height: 24)
        }
        public static func nameBoard(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 60, y: r.origin.y + 5, width: 75, height: 15)
        }
        public static func militaryRank(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 65, y: r.origin.y + 24, width: 33, height: 22)
        }
        public static func nobilityRank(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 104, y: r.origin.y + 24, width: 33, height: 22)
        }
        public static func costGroup(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 139, y: r.origin.y + 3, width: 75, height: 49)
        }
        public static func recruitButton(_ index: Int) -> NativeRect {
            let r = row(index)
            return NativeRect(x: r.origin.x + 216, y: r.origin.y + 8, width: 80, height: 40)
        }
        public static func costIcon(_ index: Int, row costRow: Int) -> NativeRect {
            let group = costGroup(index)
            let ys = [4.0, 20.0, 34.0]
            let sizes = [12.0, 11.0, 11.0]
            let i = min(max(0, costRow), 2)
            return NativeRect(x: group.origin.x + (i == 0 ? 8 : 5), y: group.origin.y + ys[i], width: sizes[i], height: sizes[i])
        }
        public static func costText(_ index: Int, row costRow: Int) -> NativeRect {
            let group = costGroup(index)
            let ys = [5.0, 20.0, 35.0]
            let i = min(max(0, costRow), 2)
            return NativeRect(x: group.origin.x + 27, y: group.origin.y + ys[i], width: 48, height: 15)
        }
    }

    public enum GeneralUpgrade {
        public static let frame = NativeRect(x: 0, y: 0, width: 325, height: 185)
        public static let screenFrame = NativeRect(x: 121.5, y: 67.5, width: 325, height: 185)
        public static let closeButton = NativeRect(x: 430.5, y: 59.5, width: 25, height: 25)
        // `tcmder` is declared 156x196 in the XML, but its recovered commander
        // widget footprint is the same 78x98 logical card used by adjacent forms.
        public static let commander = NativeRect(x: 126.5, y: 99.5, width: 78, height: 98)
        public static let militaryGroup = NativeRect(x: 207.5, y: 100.5, width: 235, height: 47)
        public static let nobilityGroup = NativeRect(x: 207.5, y: 150.5, width: 235, height: 47)
        public static let fullGroup = NativeRect(x: 207.5, y: 200.5, width: 235, height: 47)
        public static let militaryButton = NativeRect(x: 363.5, y: 109.5, width: 75, height: 30)
        public static let nobilityButton = NativeRect(x: 363.5, y: 159.5, width: 75, height: 30)
        public static let allButton = NativeRect(x: 363.5, y: 209.5, width: 75, height: 30)
        public static let bottomPattern = NativeRect(x: 149.5, y: 215.5, width: 143, height: 26)
    }

    public enum Tutorial {
        public static let frame = NativeRect(x: 0, y: 0, width: 250, height: 200)
        public static let screenFrame = NativeRect(x: 159, y: 60, width: 250, height: 200)
        public static let basicButton = NativeRect(x: 212, y: 100, width: 145, height: 40)
        public static let classicButton = NativeRect(x: 212, y: 145, width: 145, height: 40)
        public static let noticeButton = NativeRect(x: 212, y: 190, width: 145, height: 40)
        public static let playNoticeFrame = NativeRect(x: 84, y: 47, width: 400, height: 225)
        public static let playNoticeViewport = NativeRect(x: 89, y: 80, width: 390, height: 186)
        public static let playNoticeScrollbarTrack = NativeRect(x: 475, y: 80, width: 4, height: 186)
        public static let playNoticeCloseButton = NativeRect(x: 458, y: 38, width: 25, height: 25)
    }

    public enum Regroup {
        public static let previewGroup = NativeRect(x: 8, y: 37, width: 146, height: 120)
        public static let previewTitle = NativeRect(x: 8, y: 37, width: 146, height: 26)
        public static let previewMilitary = NativeRect(x: 18, y: 69, width: 34, height: 18)
        public static let previewNobility = NativeRect(x: 88, y: 69, width: 34, height: 18)
        public static let previewHPMarker = NativeRect(x: 59, y: 69, width: 30, height: 27)
        public static let previewHPText = NativeRect(x: 45, y: 84, width: 40, height: 15)
        public static let previewRecoverMarker = NativeRect(x: 126, y: 67, width: 35, height: 35)
        public static let previewRecoverText = NativeRect(x: 113, y: 84, width: 40, height: 15)
        public static let previewGridFrame = NativeRect(x: 8, y: 101, width: 146, height: 56)
        public static let previewGridCells = [
            NativeRect(x: 8, y: 101, width: 73, height: 28),
            NativeRect(x: 81, y: 101, width: 73, height: 28),
            NativeRect(x: 8, y: 129, width: 73, height: 28),
            NativeRect(x: 81, y: 129, width: 73, height: 28),
        ]
        public static let previewGridSplit = NativeRect(x: 8, y: 128.5, width: 146, height: 1)

        public static let sourceCommander = NativeRect(x: 160, y: 37, width: 78, height: 98)
        public static let arrow = NativeRect(x: 242, y: 48, width: 84, height: 82)
        public static let targetCommander = NativeRect(x: 331, y: 37, width: 78, height: 98)
        public static let regroupButton = NativeRect(x: 243, y: 100, width: 83, height: 35)

        public static let equipmentGroup = NativeRect(x: 415, y: 37, width: 146, height: 120)
        public static let equipmentTitle = NativeRect(x: 415, y: 37, width: 146, height: 26)
        public static let equipmentList = NativeRect(x: 437, y: 88, width: 100, height: 45)
        public static let equipmentSlots = [
            NativeRect(x: 437, y: 88, width: 45, height: 45),
            NativeRect(x: 492, y: 88, width: 45, height: 45),
        ]
        public static let equipmentTopPattern = NativeRect(x: 449.5, y: 67, width: 77, height: 23)
        public static let equipmentBottomPattern = NativeRect(x: 449.5, y: 153, width: 77, height: 23)
        public static let equipmentTopSplit = NativeRect(x: 415, y: 81, width: 146, height: 1)
        public static let equipmentBottomSplit = NativeRect(x: 415, y: 138, width: 146, height: 1)

        public static let notice = NativeRect(x: 0, y: 164, width: 568, height: 15)
        public static let middleLine = NativeRect(x: 0, y: 180, width: 568, height: 2)
        public static let generalList = NativeRect(x: 24, y: 190, width: 550, height: 98)
        public static let lowerLine = NativeRect(x: 0, y: 295, width: 568, height: 2)
        public static let bottomPattern = NativeRect(x: 212.5, y: 303, width: 143, height: 26)
        public static let bottomBoldLine = NativeRect(x: 0, y: 316, width: 568, height: 4)
    }

    public enum RegroupConfirm {
        public static let frame = NativeRect(x: 0, y: 0, width: 320, height: 222)
        public static let screenFrame = NativeRect(x: 124, y: 49, width: 320, height: 222)
        public static let tips = NativeRect(x: 124, y: 79, width: 320, height: 15)
        public static let info = NativeRect(x: 124, y: 96, width: 320, height: 15)
        public static let board = NativeRect(x: 124, y: 114, width: 320, height: 107)
        public static let topSplit = NativeRect(x: 124, y: 113, width: 320, height: 2)
        public static let bottomSplit = NativeRect(x: 124, y: 221, width: 320, height: 2)
        public static let commander = NativeRect(x: 174, y: 119, width: 78, height: 98)
        public static let commanderPortrait = NativeRect(x: 177, y: 119, width: 72, height: 72)
        public static let commanderName = NativeRect(x: 174, y: 191, width: 78, height: 13)
        public static let commanderGrowth = NativeRect(x: 174, y: 204, width: 78, height: 13)
        public static let equipment = NativeRect(x: 261, y: 119, width: 132, height: 98)
        public static let equipmentTitle = NativeRect(x: 261, y: 119, width: 132, height: 20)
        public static let equipmentList = NativeRect(x: 277, y: 155, width: 100, height: 45)
        public static let equipmentSlots = [
            NativeRect(x: 277, y: 155, width: 45, height: 45),
            NativeRect(x: 332, y: 155, width: 45, height: 45),
        ]
        public static let equipmentTopPattern = NativeRect(x: 288.5, y: 141, width: 77, height: 23)
        public static let equipmentBottomPattern = NativeRect(x: 288.5, y: 191, width: 77, height: 23)
        public static let equipmentTopSplit = NativeRect(x: 261, y: 153, width: 132, height: 1)
        public static let equipmentBottomSplit = NativeRect(x: 261, y: 201, width: 132, height: 1)
        public static let confirmButton = NativeRect(x: 174, y: 231, width: 75, height: 30)
        public static let cancelButton = NativeRect(x: 319, y: 231, width: 75, height: 30)
    }

    public enum StageIntro {
        public static let frame = NativeRect(x: 0, y: 0, width: 360, height: 219)
        public static let screenFrame = NativeRect(x: 104, y: 50, width: 360, height: 219)
        public static let closeButton = NativeRect(x: 343, y: -8, width: 25, height: 25)
        public static let commander = NativeRect(x: 2, y: 30, width: 78, height: 98)
        public static let description = NativeRect(x: 83, y: 30, width: 275, height: 98)
        public static let descriptionText = NativeRect(x: 86, y: 33, width: 269, height: 92)
        public static let victory = NativeRect(x: 0, y: 130, width: 180, height: 60)
        public static let bestVictory = NativeRect(x: 180, y: 130, width: 180, height: 60)
        public static let ornamentY = 195.0
    }

    public enum Talk {
        public static let size = NativeSize(width: 325, height: 83)
        public static let leftFrame = NativeRect(x: 0, y: 225, width: 325, height: 83)
        public static let rightFrame = NativeRect(x: 236, y: 225, width: 325, height: 83)
        public static let portraitLeft = NativeRect(x: 10, y: 7, width: 78, height: 78)
        public static let portraitRight = NativeRect(x: 237, y: 7, width: 78, height: 78)
        public static let contentLeft = NativeRect(x: 88, y: 7, width: 220, height: 76)
        public static let contentRight = NativeRect(x: 17, y: 7, width: 220, height: 76)
        public static let systemContent = NativeRect(x: 18, y: 14, width: 286, height: 56)
        public static let nameInContent = NativeRect(x: 4, y: 1, width: 214, height: 18)
        public static let textInContent = NativeRect(x: 2, y: 20, width: 216, height: 66)
        public static let nextLeft = NativeRect(x: 310, y: 71, width: 8, height: 7)
        public static let nextRight = NativeRect(x: 7, y: 71, width: 8, height: 7)
    }

    public enum Pause {
        public static let frame = NativeRect(x: 0, y: 0, width: 166, height: 272)
        public static let screenFrame = NativeRect(x: 201, y: 24, width: 166, height: 272)
        public static let closeButton = NativeRect(x: 149, y: -8, width: 25, height: 25)
        public static let hudButton = NativeRect(x: 535, y: 2, width: 27, height: 27)
        public static let turnWord = NativePoint(x: 50, y: 35)
        public static let turnValue = NativeRect(x: 85, y: 36, width: 35, height: 15)
        public static let saveButton = NativeRect(x: 42, y: 65, width: 83, height: 35)
        public static let optionButton = NativeRect(x: 42, y: 115, width: 83, height: 35)
        public static let restartButton = NativeRect(x: 42, y: 165, width: 83, height: 35)
        public static let exitButton = NativeRect(x: 42, y: 215, width: 83, height: 35)
        public static let separatorY = [58.0, 108.0, 158.0, 208.0]
    }

    public enum RoundTurn {
        public static let frame = NativeRect(x: 0, y: 0, width: 320, height: 175)
        public static let screenFrame = NativeRect(x: 124, y: 72, width: 320, height: 175)
        public static let closeButton = NativeRect(x: 303, y: -8, width: 25, height: 25)
        public static let verticalLines = [
            NativeRect(x: 106, y: 28, width: 1, height: 63),
            NativeRect(x: 213, y: 28, width: 1, height: 63),
        ]
        public static let horizontalLines = [
            NativeRect(x: 3, y: 91, width: 314, height: 1),
            NativeRect(x: 3, y: 100, width: 314, height: 1),
            NativeRect(x: 3, y: 167, width: 314, height: 1),
        ]
        public static let economyHeader = NativeRect(x: 4, y: 30, width: 100, height: 16)
        public static let roundHeader = NativeRect(x: 111, y: 30, width: 97, height: 16)
        public static let foodHeader = NativeRect(x: 217, y: 30, width: 100, height: 16)
        public static let moneyIcon = NativeRect(x: 28, y: 50, width: 20, height: 20)
        public static let moneyValue = NativePoint(x: 55, y: 55)
        public static let industryIcon = NativeRect(x: 28, y: 70, width: 20, height: 20)
        public static let industryValue = NativePoint(x: 55, y: 75)
        public static let roundValue = NativeRect(x: 111, y: 59, width: 50, height: 16)
        public static let starBoard = NativeRect(x: 162, y: 28, width: 28, height: 62)
        public static let bestValue = NativePoint(x: 190, y: 39)
        public static let winValue = NativePoint(x: 190, y: 69)
        public static let foodAddIcon = NativeRect(x: 240, y: 50, width: 20, height: 20)
        public static let foodAddValue = NativePoint(x: 270, y: 55)
        public static let foodDelIcon = NativeRect(x: 240, y: 70, width: 20, height: 20)
        public static let foodDelValue = NativePoint(x: 270, y: 75)
        public static let generals = NativeRect(x: 11, y: 105, width: 299, height: 59)
    }

    public enum Victory {
        public static let frame = NativeRect(x: 0, y: 0, width: 346, height: 210)
        public static let screenFrame = NativeRect(x: 111, y: 55, width: 346, height: 210)
        public static let battleName = NativeRect(x: 2, y: 27, width: 240, height: 20)
        public static let roundLabel = NativeRect(x: 240, y: 27, width: 65, height: 20)
        public static let roundValue = NativeRect(x: 240, y: 59, width: 57, height: 20)
        public static let starLevel = NativeRect(x: 295, y: 27, width: 51, height: 63)
        public static let stars = NativeRect(x: 85, y: 47, width: 75, height: 15)
        public static let awardLabel = NativeRect(x: 12, y: 70, width: 50, height: 15)
        public static let awardMedal = NativeRect(x: 67, y: 69, width: 12, height: 12)
        public static let awardValue = NativeRect(x: 80, y: 71, width: 40, height: 15)
        public static let gainLabel = NativeRect(x: 90, y: 70, width: 85, height: 15)
        public static let gainMedal = NativeRect(x: 182, y: 69, width: 12, height: 12)
        public static let gainValue = NativeRect(x: 195, y: 71, width: 40, height: 15)
        public static let generals = NativeRect(x: 13, y: 95, width: 320, height: 59)
        public static let continueButton = NativeRect(x: 40, y: 165, width: 70, height: 35)
        public static let exitButton = NativeRect(x: 235, y: 165, width: 70, height: 35)
        public static let ornamentY = 172.0
    }

    public enum Failure {
        public static let frame = NativeRect(x: 0, y: 0, width: 151, height: 184)
        public static let screenFrame = NativeRect(x: 208.5, y: 68, width: 151, height: 184)
        public static let common = NativeRect(x: 33, y: 58, width: 85, height: 67)
        public static let flag = NativeRect(x: 63, y: 74, width: 25, height: 20)
        public static let countryName = NativeRect(x: 33, y: 105, width: 85, height: 20)
        public static let okButton = NativeRect(x: 60, y: 151, width: 30, height: 30)
        public static let ornamentY = 160.0
    }

    public enum VictoryText {
        public static let backdrop = NativeRect(x: 0, y: 104, width: 568, height: 70)
        public static let word = NativeRect(x: 108, y: 130, width: 351, height: 61)
        public static let durationMilliseconds = 4500.0
    }

    public enum Save {
        public static let frame = NativeRect(x: 0, y: 0, width: 352, height: 235)
        public static let screenFrame = NativeRect(x: 108, y: 42, width: 352, height: 235)
        public static let closeButton = NativeRect(x: 335, y: -8, width: 25, height: 25)
        public static let autosaveColumn = NativeRect(x: 119, y: 31, width: 114, height: 201)
        public static let autosaveSlot = NativeRect(x: 119, y: 88, width: 114, height: 87)
        public static let manualSlots: [NativeRect] = [
            NativeRect(x: 4, y: 31, width: 114, height: 67),
            NativeRect(x: 4, y: 98, width: 114, height: 67),
            NativeRect(x: 4, y: 165, width: 114, height: 67),
            NativeRect(x: 235, y: 31, width: 114, height: 67),
            NativeRect(x: 235, y: 98, width: 114, height: 67),
            NativeRect(x: 235, y: 165, width: 114, height: 67),
        ]
        public static let manualDate = NativeRect(x: 0, y: 25, width: 114, height: 30)
        public static let manualOK = NativeRect(x: 83, y: 36, width: 30, height: 30)
        public static let autosaveDate = NativeRect(x: 0, y: 30, width: 114, height: 0)
        public static let autosaveOK = NativeRect(x: 83, y: 57, width: 30, height: 30)
    }

    public static func centeredFrame(size: NativeSize) -> NativeRect {
        NativeRect(
            x: (EW4LogicalSpace.width - size.width) / 2,
            y: (EW4LogicalSpace.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }
}
