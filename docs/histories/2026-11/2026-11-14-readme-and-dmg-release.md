## 2026-11-14 | 任务：重写 README 并发布 DMG

**Links:** https://github.com/FinnKyo/AI-Dict/releases/tag/v1.0.0

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.2.1 / Xcode 27.0 (27A266a)`

### 用户请求

用 AI-Dict 的介绍重写 README；把本地项目打包成 DMG，并上传到 GitHub 仓库。

### 变更

- 重写 `README.md`（英文）和 `README_ZH.md`（中文）。内容包括：
  - 功能、安装（含未公证 App 的打开方法）、OpenRouter Key 与模型设置、权限、默认快捷键；
  - 从源码构建，以及用 `Easydict-debug.local.xcconfig` 让调试版权限持续有效；
  - Easydict GPL-3.0 致谢。
- App 版本从 Easydict 的 2.27.0 (70) 改为 1.0.0 (1)。
- 新增 `scripts/build-dmg.sh`：Release 通用二进制，临时签名，关闭 hardened runtime
  （否则临时签名下无法加载内嵌框架）；去掉调试符号，生成 `dist/AI-Dict-<version>.dmg`。
  `dist/` 已加入 `.gitignore`。

### 设计意图

公开 DMG 使用临时签名而不是开发证书：开发证书签名会在 App 中嵌入证书持有人的邮箱，
而且在其他 Mac 上同样不被 Gatekeeper 信任，与临时签名没有区别。

### 验证

- `scripts/build-dmg.sh`：成功，生成 22 MB DMG，`hdiutil verify` 通过。
- 挂载 DMG：包含 `AI-Dict.app` 和 `Applications` 快捷方式。App 为 x86_64 + arm64 通用二进制，
  签名校验通过，从 DMG 启动后正常运行；包内不含个人信息。

### 受影响文件

- `README.md`
- `README_ZH.md`
- `scripts/build-dmg.sh`
- `.gitignore`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- App 未经 Apple 公证；需要 Developer ID 证书和公证才能消除首次打开时的安全提示。
