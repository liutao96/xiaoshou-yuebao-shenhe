# 销售月报审核 Skill 发布说明

# 销售月报审核 Skill 发布说明

## 1.3.1 - 2026-07-09

- 更新脚本新增私有 GitHub 仓库支持：可通过 `-GithubToken` 或 `GITHUB_TOKEN` 读取版本清单和下载发布包。
- 配置说明补充私有仓库 token 边界：不要把 token 发到聊天区或写进 Skill 包。

## 1.3.0 - 2026-07-09

- 新增正式更新脚本：`scripts/Update-XiaoshouYuebaoSkill.ps1` 支持备份、下载、SHA256 校验、解压覆盖和更新日志。
- 新增发布打包脚本：`scripts/Build-XiaoshouYuebaoSkillRelease.ps1` 用于重新打包 zip、计算 SHA256、更新 `latest-version.json`。
- 版本清单支持后续接入 GitHub Releases：`latest-version.json` 可配置 `zip_url`、`manifest_url`、`sha256`。

## 1.2.0 - 2026-07-09

- 新增多应用 / 多 profile 权限探测：销售月报读取中遇到当前应用、bot 或默认 profile 无权限时，先遍历本机已配置 profile 做只读尝试。
- 新增版本与更新提示：部长电脑或分享包环境可通过 `VERSION.json` 与 `latest-version.json` 判断是否有新版。
- 明确多 profile 探测只适用于读取月报原文、表格、附件信息等只读操作，写入和高风险操作不得自动跨 profile 尝试。
