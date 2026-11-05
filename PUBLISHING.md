# 上传到 GitHub 与发布新版本

项目名称：`codex-usage-card-windows`。

## 网页上传

1. 登录 GitHub，确认右上角是准备发布项目的账号。
2. 右上角 **+ → New repository**，名称填 `codex-usage-card-windows`，选择 Public。
3. 创建仓库后，选择 **uploading an existing file**。也可以先创建 README，再用 **Add file → Upload files**。
4. 上传本项目根目录中的源码和说明文件。不要上传 `.git`、`dist`、日志、`node.exe`、`installation.json`、`auth.json` 或你电脑上已经安装的工具目录。
5. 填写提交说明，点击 **Commit changes**。

## 发布可下载安装包

1. 在本项目目录执行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\check.ps1
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
   ```

2. 在 GitHub 仓库中打开 **Releases → Draft a new release**。
3. 标签填写 `v0.9.4-windows.3`，目标分支 `main`；标题填写 `Codex Usage Card Windows 0.9.4.3`。
4. 将 `dist/CodexUsageCard-Windows-0.9.4.3.zip` 和 `dist/SHA256SUMS.txt` 作为附件上传。版本说明可依据 `CHANGELOG.md`，并保留“非官方 / 依赖内部接口 / 仅单机验证”的说明。
5. 此版本建议勾选 **Set as a pre-release**，然后发布。

## 后续修改

少量文字可以直接在 GitHub 打开文件，点击铅笔编辑并提交。代码变更应先下载到本地、修改并运行检查，再上传。

发布下一版本时同步修改 `package.json`、`manage.ps1`、`agent.cjs`、`build-release.ps1`、`README.md` 和 `CHANGELOG.md` 中的版本信息，重新生成 ZIP 和校验值，创建新的标签和 Release；不要覆盖已经发布版本的文件。

原项目的 MIT 许可和署名应始终保留。不要将个人账号、机器路径、日志或聊天内容提交到仓库。
