# 销售月报审核 Skill

这是刘涛用于销售月报 AI 审核的 Codex Skill 发布仓库。

## 内容

- `xiaoshou-yuebao-shenhe/`：Skill 源目录。
- `release/latest-version.json`：远端版本清单，供更新脚本检查最新版。
- `release/xiaoshou-yuebao-shenhe.zip`：当前发布包。
- `GitHub发布说明.md`：发布和更新流程说明。

## 安装 / 更新

部长或同事电脑已安装本 Skill 后，可检查更新：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "<owner>/<repo>" -CheckOnly
```

确认更新：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "<owner>/<repo>"
```

## 注意

这个仓库建议保持私有。不要提交真实月报、客户数据、密钥、Token、Cookie 或数据库连接信息。
