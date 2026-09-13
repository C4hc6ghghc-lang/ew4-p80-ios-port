# 欧陆战争4 P80：云端 IPA 构建包

这是你提供的原版逆向移植项目，与《皇帝的凯旋1.20》APK 分开处理。
本包保留原 ZIP 中全部文件的内容，只添加 GitHub Actions 工作流、Git 属性和本说明。
未在此项目加入前一个项目要求的无限资源或取消将领限制。

## 当前状态

这仍是源码构建包，不是已编译 IPA。
本机重新执行：26 项 IPA 静态预检通过，1751 个原生资源哈希符合清单；6 项 Xcode 候选静态检查通过。
交接包中的 Swift 测试记录属于历史记录，不代表本次已用 Apple SDK 构建或真机测试。

## Windows 用户操作

1. 解压本包。在 GitHub 创建一个空的私有仓库，并用 GitHub Desktop 将解压后的 EW4-P80-cloud-build 文件夹作为仓库内容提交、发布。不要仅把这个 ZIP 上传到仓库。
2. 仓库根目录必须能看到 BUILD_FROM_CODEX_MAC.sh、SOURCE_NATIVE、SOURCE_LEAN 和隐藏目录 .github；不要再套一层目录。已有 .gitignore 时确保源代码和 Resources 被提交。
3. 打开仓库的 Actions 页面，选择 Build EW4 P80 unsigned IPA，点击 Run workflow。工作流只允许手动启动。
4. 成功后，在该次运行的 Artifacts 中下载 EW4-P80-unsigned-IPA，解压得到 EW4NativePort-unsigned.ipa。
5. 若失败，下载 EW4-P80-build-diagnostics，将日志交回继续修复。首次 Apple SDK 编译可能暴露之前静态检查发现不了的问题。

构建脚本沿用原项目流程：源文件哈希检查、126 个 JS 回归文件、动态战场检查、Swift 测试和资源审计、Xcode 编译、IPA 内容验证。
目标配置：iOS 15+、iPhone 和 iPad、横屏、设备 arm64。实际兼容性仍需构建后真机验证。
构建过程不需要 Apple 签名证书；产物未签名，安装前需要你使用自己的签名方式处理。不要将证书或密码提交到仓库。
云端任务最长 60 分钟；构建产物保留 7 天。私有仓库的 macOS 构建会使用 GitHub Actions 额度，是否产生费用取决于账户额度和计费设置。

## 参考

- GitHub 托管构建机器：https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job
- 下载构建产物：https://docs.github.com/en/actions/tutorials/store-and-share-data
- Actions 额度：https://docs.github.com/en/billing/concepts/product-billing/github-actions

尚未上传到任何仓库，也尚未启动云端任务。
