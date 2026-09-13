# P33 Visual Timing Polish WIP — 简短说明

这是 P32 Visual Polish WIP 之后继续收紧的一轮**视觉/交互时序检查点**，仍然不是“最终视觉完全复刻版”。原版 APK/AAB 二进制不包含在交付包中。

## 本轮新增
- **攻击命中时序**：伤害/RNG/反击资格仍由模拟层立即算出，但 HP 弧、伤害数字、死亡提示和兵模消失改到原版 authored `Attack` 动作结束的 impact 时点再提交；不再出现弹道/攻击动作尚未命中而血量/死亡画面抢先更新，也不再错误等完整 `Attack -> Reload -> Finish` 链结束才命中。
- **死亡与胜负画面**：逻辑已死亡但尚在等待 impact 的单位继续保留在画面中；胜负检查延迟到该次表现提交后，避免结果面板抢在命中反馈前出现。
- **存档隔离**：新的 `presentationHp` / pending-impact 等字段全部采用不可枚举运行时字段；冻结的 `battle_save_core.js` 未修改。
- **运输船方向**：保留原版 `transportship1/2` 图片与 native ref 锚点，只围绕 ref 做左右镜像；移动过程中按当前路径段更新朝向；两个源图各自的自然朝向分别保留。
- **StageIntro / Talk**：去掉原版布局中不存在的 Web 标题字；对话板改回提取的 `board_dialog_ex.png`，继续减少 Web 自制边框感。
- **触控稳定性**：补 `lostpointercapture` / window blur 的手势状态清理，防止 iOS 中断手势后拖拽/双指状态卡死；原版缩放范围、0.5 LOD 分界、tap slop、无 fling 规则不改。
- **PWA 缓存**：更新缓存代号，防止主屏幕版本继续读取 P32 旧 JS/CSS/资源。

## 明确没有乱改的部分
- 不改战斗伤害数值、RNG、AI 决策质量/行动数、玩家 MOD、战役成长、存档 schema。
- 不凭感觉给地图文字/建筑发明新的低倍 LOD：当前原 APK 证据能证明 0.2–1.0 与 0.5 分界，但不能证明某个“城市名淡出阈值”。因此保持原生数学，留给真机画面裁决。
- `transportship1/2` **每种装备组合到底由原版选择哪一张**仍未完全逆向证明；本轮只修已能证明的锚点/方向表现。

## 当前验证
- 全量 JS regression：**119/119 PASS**。
- 连续 5 次全量回归：**5/5 均为 119/119 PASS**。
- Service Worker CORE：**1054/1054 present**。
- P21+ 保护哈希保持：`battle_save_core.js` = `4858c7f862dac736d3624b8e64567af1484382b63bd8482aa544cd3204272dc2`。

## 下一轮最值钱的目标
1. iPhone 真机录屏裁决攻击 impact、反击、死亡消失、胜负面板的最后几十/几百毫秒。
2. 真机核 `transportship1/2` 的选择规则、锚点、旗/将领框/HP 环遮挡。
3. StageIntro / Talk 的字体基线、头像位置、`board_dialog_ex` extend/9-slice 语义继续收紧。
4. 低倍地形/建筑与手指 pinch 的“观感”仅在有原版录屏/真机对照后继续改，不造规则。

外部充值、广告、多人联网、平台排行等仍刻意不做。
