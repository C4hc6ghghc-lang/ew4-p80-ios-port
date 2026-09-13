# P80 黑屏修复：1.0.1（81）

旧版在 iPhone、iPad 模拟器上均复现全黑。修复版已在两种设备上通过主菜单显示、战役入口和征服入口的实际点击测试，并人工检查全屏截图。之前仅凭进程仍在运行判定启动通过，验证不足，不能证明画面正常；本次已补上画面及交互验收。

## 修复内容

- 将 SwiftUI 的 SpriteView 场景承载改为持久的原生 SKView，通过 presentScene 显式挂载及切换场景，避免停留在初始空场景。
- 资源路径严格定位到应用包的 GameAssets/Resources，检查关键启动资源；删除掩盖缺失目录的回退路径。
- 启动失败会显示错误与重试按钮，同时输出启动阶段日志。日志已确认资源初始化、showMainMenu、主菜单创建及 scene attached=true 均执行成功。
- 保留原资源包。1,751 个文件的大小和 SHA-256 均与用户提供的原生项目一致。

对照测试表明问题位于启动/场景显示链，未发现本次打包遗漏原生资源。没有把包体积作为黑屏诊断依据，也没有通过添加无用资源扩大 IPA。

## 安装

请使用 `EW4-P80-1.0.1-81-unsigned.ipa`，版本 1.0.1（81），iPhoneOS arm64，iOS 15 及以上，支持 iPhone、iPad 横屏。此交付包未签名，需要重新导入你原先使用的签名工具，以有效签名安装。旧文件名 EW4-P80-unsigned.ipa 和下载 ZIP 也已更新为本次修复版，避免误装旧版。

大小：31,197,103 字节（31.20 MB，约 29.75 MiB）。

SHA-256：`ec9a8c55909249dc60d93de55361de122e32c1badd4d4dc72f1f8c7b2514bbd6`

## 验证记录

- 设备构建：[34749328311](https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port/actions/runs/34749328311)，应用源码 bf48f652f34ea1f9e1ba8961d1bbfd83a80e2e24。
- 全屏界面测试：[34749688951](https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port/actions/runs/34749688951)，测试源码 11a4c307d117d588f319829a0abe96757cfce018；与上述 IPA 的应用源码和资源相同。
- 对照运行：[34749282171](https://github.com/C4hc6ghghc-lang/ew4-p80-ios-port/actions/runs/34749282171)，baseline 分支因复现全黑而预期失败，fixed 分支通过。
- iPhone 16 Pro、iPad Pro 11-inch（M4），均为 iOS 18.5 模拟器；截图和阶段日志位于 visual-validation。
- 126 个 JS 回归测试文件、286 项 Swift Testing、9 项 XCTest 通过；设备 IPA 结构与全部原生资源哈希检查通过。

尚未验证实体设备签名安装及完整战役/征服对局，不能把菜单通过等同于所有玩法均已验收。

## 关于体积

最初约 31 MB 的 IPA 解压后约 50.5 MB，其中原生资源约 45.6 MB。用户 ZIP 还包含参考 Web 工程、重复资产、测试及审计资料，因此源 ZIP 大小不能直接等同 IPA。体积核查详见 IPA体积核查.md；1,751 个文件齐全只说明没有漏掉所提供的原生资源，不证明该移植覆盖官方游戏的所有内容。

此 P80 项目与《皇帝的凯旋》APK 分开；本次没有加入另一个 mod 请求中的无限资源或将领规则修改。
