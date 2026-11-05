# codex-usage-card-windows

**在 Windows 版 Codex 桌面客户端的原侧栏内显示剩余额度。**

> 基于 [Lorie7813/codex-usage-card](https://github.com/Lorie7813/codex-usage-card) v0.9.4 制作的非官方 Windows 适配版。原额度读取、圆环界面与设计来自原项目；本仓库增加 Windows 安装、启动恢复、卸载与打包支持。原 MIT 许可和版权声明完整保留于 [LICENSE](LICENSE)。本项目与 OpenAI 及原作者没有官方关联。

## 功能

- 账号支持时，分别显示 **5 小时 / 每周剩余额度**，悬停查看重置时间。
- 保留原侧栏圆环位置和样式，不创建额外桌面边栏。
- Windows 登录后自动运行监视器；额度读取程序退出后自动恢复。
- 独立保存运行文件，不修改官方客户端安装文件。

## 下载安装

1. 在本仓库 **Releases** 页面下载 Windows ZIP 和 `SHA256SUMS.txt`，校验后完整解压。
2. 安装 [Node.js 24 或更高版本](https://nodejs.org/)，确认 `node --version` 可用。
3. 双击解压目录中的 **`install.cmd`**。若下载的是 **Code → Download ZIP** 源码包，请运行 **`scripts/install.cmd`**。
4. 保存工作，完全退出 Codex（包括托盘），再从原图标启动；也可使用桌面 **“Codex 额度卡”** 入口。

校验 ZIP：

```powershell
Get-FileHash .\CodexUsageCard-Windows-0.9.4.3.zip -Algorithm SHA256
```

安装目录为 `%USERPROFILE%\.codex\usage-card-windows`，登录任务名为 `Codex Usage Card Windows Embedded`。安装器会复制独立的 Node 运行文件。

## 启动说明

从原图标启动时，监视器可能在窗口尚未显示、进程启动不足 5 秒且没有已有会话的情况下自动重开一次，以启用本机连接。已显示或正在使用的会话会保留。如果错过这个阶段，请完全退出后使用桌面“Codex 额度卡”入口。

当前识别 Windows MSIX 包 `OpenAI.Codex`，其主进程可能名为 `ChatGPT.exe`。这不是 VS Code 扩展，也不在 SSH / WSL 远端运行。

## 状态与卸载

查看状态：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\usage-card-windows\manage.ps1" -Action status
```

卸载：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\usage-card-windows\manage.ps1" -Action uninstall
```

卸载移除工具任务、快捷方式和已知工具文件，保留官方客户端、账号和聊天。随后完全退出并重新打开客户端，以关闭调试端口。

## 要求与限制

- 已在一台 Windows 11 x64 设备验证；Windows 10、ARM64 和其他客户端发行方式未验证。
- 需要已登录的官方 Windows 客户端、可用的本机 Codex CLI、Node.js 24+，以及创建当前用户登录任务的权限。
- 本工具使用 **`127.0.0.1:39222` 调试接口**，其他本机程序可能访问。请勿转发此端口或对外开放。
- 仅通过本机 CLI 读取额度，不读取聊天数据库或导出登录令牌。未登录、网络异常或数据过期时可能显示 `—`。
- 应用更新不会直接覆盖独立安装目录，但未来内部接口变化仍可能导致不兼容，不能保证永久有效。
- 原版圆环占用侧栏空间，极小窗口与未来新布局未全面验证。安装包未做代码签名。

更多说明见 [SECURITY.md](SECURITY.md)。

## 源码与打包

Windows 程序集中在 `scripts/`。生成发布包：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-release.ps1
```

产物位于 `dist/`，仅包含运行必需文件和说明，不包含个人日志、账号、安装状态或 Node 二进制。发布时在 GitHub 的 **Releases → Draft a new release** 中上传 ZIP 与校验文件。

## 来源与许可

原项目：[Lorie7813/codex-usage-card](https://github.com/Lorie7813/codex-usage-card)。原额度读取、CLI app-server 连接、界面注入与圆环设计来自其 MIT 许可的 v0.9.4 发布包。Windows 安装、路径发现、登录监视、恢复与卸载逻辑为本适配版增加的部分。

使用的上游压缩包为 `CodexUsageCard-macOS-0.9.4.zip`，已核对 SHA-256：

```text
e41cbb00fd01b785eb0cac73a946115a35dd2d9a2410c196ec7287ce4b1737f8
```

上游原始压缩包不在本仓库内重复分发。原 MIT 许可和版权声明保留不变。
