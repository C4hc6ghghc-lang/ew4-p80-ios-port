# P35 Final Native Presentation — 最终说明

这是从 P34 Final Visual Candidate 做的最后一轮 **PORT_ONLY 原生表现加固**。目标不是继续发明 UI，而是消掉现代 iPhone 上最容易让地图和兵模显得像 Web 移植的系统性问题，同时保持 568×320 原版逻辑坐标、native ref 锚点、LOD、兵模尺寸规则和战斗逻辑不变。原 APK/AAB 二进制仍不进入交付包。

本轮关键收口：

- **战场 HiDPI backing**：游戏仍在 568×320 逻辑坐标里绘制，但 Canvas backing store 按 `devicePixelRatio × 舞台缩放` 提升，向上取 0.5 档并最高 4×。地图、地形、建筑、兵模、国旗、HP 环、将领框不再由浏览器把 568×320 低分辨率整张硬放大。
- **兵模尺寸/锚点不乱改**：没有重写 `unitVisualZoom`，没有改 native ref、六边格中心或 P34 已闭环的 transport anchor/z-order。最后一轮只提升栅格采样质量，避免以“变清楚”为名再次制造尺寸和漂移问题。
- **触控坐标反变换**：battle pointer 不再使用 CSS transform 下可能不稳定的 `offsetX/offsetY`；统一用 `clientX/clientY -> getBoundingClientRect() -> 568×320` 反算逻辑坐标。HiDPI/CSS 缩放不会改变点兵、点格和 pinch anchor。
- **征服选国地图 HiDPI**：410×320 逻辑地图也使用同一高清 backing 原则，标记层逻辑位置不变。
- **iPhone/PWA 外壳去 Web 味**：用户可见标题/manifest 去掉 `Web Port v0.61`；补 standalone iOS 元数据，关闭长按选中/页面 overscroll，并移除舞台 Web 卡片式阴影。内部旧存档 key 保留，避免破坏迁移兼容。
- **地图/兵模资源完整性硬审计**：sprite/READY/terrain manifest 引用全部存在；161 个高风险 native-ref 精灵（运输船、HP、mark_unit、building）数值合法；877 个 READY 视觉合法；7407 个战场单位全部能解析到 READY 视觉。
- **P34/P33 视觉闭环全部继承**：Attack-end 命中提交、待死亡画面保留、结果 gate、运输船规则、StageIntro/Talk、0.2–1.0 相机、0.5 LOD、原生 layer order 均不回退。

最终自动验证：**122/122 PASS，连续 5 轮全部 122/122**；Service Worker CORE **1054/1054**；四个 P21+ 保护核心哈希全部 MATCH；预封包树内 APK/AAB=0，12 个嵌套 ZIP 内 APK/AAB=0。

“Final Native Presentation”的含义：当前本地代码/数据/原版证据能够解决的地图、兵模和移植感风险已做最后收口。构建环境仍未执行实体 iPhone 与原版的并排录屏，因此设备级 Safari/standalone 字体栅格、GPU 合成或极少数几像素主观差异只能算最终验收烟测，而不是已验证事实。
