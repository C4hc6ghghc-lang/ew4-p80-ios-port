# P34 Final Visual Candidate — 简短说明

这是从 P33 Visual Timing Polish WIP 一次性收尾后的 **PORT_ONLY 最终候选检查点**。原 APK/AAB 二进制仍不进入交付包。

本轮完成的最后收口：

- StageIntro：恢复空标题 `user_window` 顶部原生窗体带；胜利/最佳回合数字按 180px 组宽居中；底部 `pattern_stage_intro.png` 从错误的 126×18 拉伸恢复为 HD 资源对应的约 31.5×18 逻辑尺寸并居中。
- Talk：头像恢复 78×78 逻辑尺寸（x=10 到内容 x=88 正好闭合）；右侧对话内容镜像到 x=17；保留 `board_dialog_ex.png`；对话箭头按 HD 0.5 标尺恢复。
- 运输船：把生产规则单点化——原始 `function=12` 的 Armored Carrier 使用 `transportship2`，其他登陆运输使用 `transportship1`；两图继续保留各自 native ref，并按当前航段围绕 ref 镜像。
- 低倍地图：删除 Web 自创的城市/港口文字最小 6px 下限，文字和建筑一起按世界空间缩放；不新增任何猜测式 LOD 阈值。
- 战斗时序：继承并锁定 P33 的 authored Attack-end 命中提交、待死亡兵模保留、胜负结果等待表现提交。
- 触控：保留已逆向的 0.2–1.0、0.5 LOD、15px tap slop、40px pinch 门槛和 stationary-finger anchor；只保留中断清理，不发明惯性。

“最终候选”的含义：本地代码/数据/原版证据能够闭环的视觉与交互项已经收口。物理 iPhone 与原版并排录屏仍可发现 Safari 字体栅格、设备合成或少量像素观感差异，但这不再作为一个未实现的代码功能挂账。
