# 销售月报审核 Skill - GitHub 发布说明

## 推荐仓库结构

```text
repo-root/
  xiaoshou-yuebao-shenhe/
    SKILL.md
    VERSION.json
    RELEASE_NOTES.md
    agents/
    assets/
    references/
    scripts/
  release/
    latest-version.json
```

zip 包建议通过 GitHub Releases 发布为资产：

```text
https://github.com/<owner>/<repo>/releases/download/v1.3.0/xiaoshou-yuebao-shenhe.zip
```

版本清单建议走 GitHub Contents API：

```text
https://api.github.com/repos/<owner>/<repo>/contents/release/latest-version.json?ref=main
```

## 刘涛本机发布新版

1. 修改 `C:\Users\刘涛\.codex\skills\xiaoshou-yuebao-shenhe` 下的 Skill 文件。
2. 更新 `VERSION.json` 和 `RELEASE_NOTES.md`。
3. 运行打包脚本：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Build-XiaoshouYuebaoSkillRelease.ps1" -ReleaseDir "D:\projects\AI月报审计\outputs\skill_release" -ZipUrl "https://github.com/<owner>/<repo>/releases/download/v1.3.1/xiaoshou-yuebao-shenhe.zip" -ManifestUrl "https://api.github.com/repos/<owner>/<repo>/contents/release/latest-version.json?ref=main" -GithubRepo "<owner>/<repo>"
```

4. 提交仓库中的 `xiaoshou-yuebao-shenhe/` 和 `release/latest-version.json`。
5. 创建 GitHub Release，例如 `v1.3.0`，上传 `outputs/skill_release/xiaoshou-yuebao-shenhe.zip`。

## 部长电脑更新

检查是否有新版：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "<owner>/<repo>" -CheckOnly
```

确认更新：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "<owner>/<repo>"
```

无人值守更新：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "<owner>/<repo>" -Yes
```

## 更新脚本做什么

- 读取本机 `VERSION.json`。
- 读取 GitHub 上的 `release/latest-version.json`。
- 发现新版后下载 GitHub Release 里的 zip。
- 校验 SHA256。
- 备份旧版到 `$HOME\.codex\skill-backups`。
- 解压覆盖 `$HOME\.codex\skills\xiaoshou-yuebao-shenhe`。
- 写日志到 `$HOME\.codex\logs`。
- 提醒重启 Codex / Claude Code。

## 注意

- 旧版 zip 如果没有更新脚本，就不会自动提示更新；至少要先安装一次 V1.3.1 或更新后的包。
- 如果仓库是私有 GitHub，部长电脑需要能访问该仓库；否则更新脚本无法下载最新版。
- 私有仓库建议给使用者配置只读 `GITHUB_TOKEN` 环境变量，不要把 token 发到聊天区或写进 Skill 包。
- 不要把真实月报、真实客户数据、密钥、token、cookie 放进公开仓库。
