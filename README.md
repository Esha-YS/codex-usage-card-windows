# codex-usage-card-windows

**在 Windows 版 Codex 桌面客户端的原侧栏内显示剩余额度。**

[![Windows](https://img.shields.io/badge/platform-Windows-0078D4)](#运行要求)
[![Node.js](https://img.shields.io/badge/Node.js-24%2B-339933)](https://nodejs.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Windows adaptation of [Lorie7813/codex-usage-card](https://github.com/Lorie7813/codex-usage-card), based on its verified v0.9.4 release. Unofficial and not affiliated with OpenAI.

> **原项目与原额度圆环设计： [Lorie7813 / codex-usage-card](https://github.com/Lorie7813/codex-usage-card)。本仓库基于它增加 Windows 安装、启动恢复、卸载和打包支持。** 原 MIT 许可和版权声明保留不变。

## 功能

- 在账号提供相应数据时，分别显示 **5 小时 / 每周剩余额度**。
- 保留原项目的侧栏位置、圆环外观和悬停提示，不增加额外桌面边栏。
- Windows 登录后自动运行监视器；额度读取进程退出后自动恢复。
- 独立保存运行文件，不修改客户端安装文件，不绑定某一版本的客户端路径。
- 提供专用启动入口、状态检查和卸载命令。

> 这是非官方内嵌工具，依赖客户端内部接口。应用更新不会直接覆盖本工具的独立目录，但未来接口变化仍可能导致不兼容，不能保证所有未来版本永久有效。

## 下载安装

1. 从本仓库的 **Releases** 页面下载 Windows ZIP 和 `SHA256SUMS.txt`，或使用 **Code → Download ZIP** 下载源码。
2. 校验 ZIP 后完整解压。不要在压缩包内直接运行安装器。
3. 安装 [Node.js 24 或更高版本](https://nodejs.org/)，重新打开终端，使 `node --version` 能找到它。
4. 双击解压目录中的 **`install.cmd`**，或在该目录运行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\manage.ps1 -Action install
   ```

5. 保存当前工作，完全退出 Codex（包括托盘图标），再使用原图标启动。首次验证也可以使用桌面 **“Codex 额度卡”** 入口，等待约 15 秒。

校验示例：

```powershell
Get-FileHash .\CodexUsageCard-Windows-0.9.4.3.zip -Algorithm SHA256
```

自定义 Node 路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\manage.ps1 -Action install -NodePath 'C:\Program Files\nodejs\node.exe'
```

## 启动与恢复机制

安装目录：`%USERPROFILE%\.codex\usage-card-windows`。登录任务：`Codex Usage Card Windows Embedded`。安装器会把 Node 运行文件复制到工具目录，减少对外部运行时缓存的依赖。

通过原图标启动时，监视器可能在**窗口尚未显示、进程启动不足 5 秒且没有已有会话**的情况下，自动重开一次，以启用仅限本机的连接。已显示或正在使用的会话会保留。如果监视器错过这个阶段，会等待下一次启动；请完全退出后使用桌面“Codex 额度卡”入口。

目前仅识别 Windows MSIX 包 `OpenAI.Codex`，其主进程可能名为 `ChatGPT.exe`。**这不是 VS Code 扩展，也不在 SSH / WSL 远端运行。** 其他发行方式未验证。

## 管理与卸载

查看状态：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\usage-card-windows\manage.ps1" -Action status
```

备用启动：双击桌面“Codex 额度卡”，或运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\usage-card-windows\manage.ps1" -Action start
```

卸载：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.codex\usage-card-windows\manage.ps1" -Action uninstall
```

卸载会移除本工具创建的登录任务、快捷方式和已知工具文件，保留官方应用、账号和聊天。随后完全退出并重新打开客户端，以关闭本机调试端口。工具副本的卸载不会卸载你单独安装的 Node。

## 运行要求

| 要求 | 说明 |
| --- | --- |
| 系统 | 已在 Windows 11 x64 单机环境验证；Windows 10 / ARM64 尚未验证 |
| 客户端 | 已安装、已登录的官方 Codex Windows MSIX 客户端，并有可用的 Codex CLI |
| 运行时 | Node.js 24+，安装前可通过 PATH 找到，或明确传入 `-NodePath` |
| 权限 | 当前用户需要能够创建登录计划任务；受管理设备可能限制该操作 |

## 隐私、安全与限制

- 额度通过本机 Codex CLI 的 `account/rateLimits/read` 读取；这里显示的是账号额度，不是对话上下文长度。
- 本工具不读取聊天数据库、不导出登录令牌，不包含独立遥测上报代码。
- 内嵌界面使用 `127.0.0.1:39222` 的 Chrome DevTools Protocol 调试接口。它权限较高，其他本机软件可能访问。**不要转发此端口，也不要把它开放到局域网或互联网。**
- 未登录、网络异常或额度数据过期时可能显示 `—`，恢复后继续尝试。
- 原版圆环占用侧栏空间。当前布局及模拟更新按钮已检查；极小窗口、未来新布局未作全面保证。
- 程序和安装包未做代码签名。审阅代码后再运行，不要为安装而关闭系统安全防护。

更多说明见 [SECURITY.md](SECURITY.md)。提交问题前请检查日志并去除用户名、本地路径、账号、会话 ID 和其他私人信息。

## 开发与打包

应用运行无需 npm 依赖。普通测试不会访问账号、启动客户端或安装计划任务：

```powershell
node --test .\test.cjs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\supervisor.ps1 -Check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check.ps1
```

已登录本机的真实额度测试需要明确启用：

```powershell
$env:CODEX_CARD_LIVE_TEST='1'
node --test .\test.cjs
Remove-Item Env:CODEX_CARD_LIVE_TEST
```

生成带 SHA-256 校验信息的发布包：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
```

构建产物位于 `dist/`；发布 ZIP 不含 Node 二进制、账号信息、日志、安装状态或开发者的本机目录。

仓库上传、版本更新和发布附件步骤见 [PUBLISHING.md](PUBLISHING.md)。

## 来源与许可证

原项目：[Lorie7813/codex-usage-card](https://github.com/Lorie7813/codex-usage-card)。额度读取和圆环界面来自其 MIT 许可的 v0.9.4 发布包，Windows 适配增加安装、后台恢复、路径发现和卸载逻辑。

原许可和版权声明完整保留于 [LICENSE](LICENSE)，来源和校验信息见 [NOTICE.md](NOTICE.md)。本项目是独立 Windows 适配版，不是原作者的官方 Windows 发布，也不是 OpenAI 官方插件。
