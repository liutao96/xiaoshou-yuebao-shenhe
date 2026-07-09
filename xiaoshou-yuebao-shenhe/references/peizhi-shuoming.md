# 销售月报AI智能体配置说明_V1.1_口径过渡版

## 一、配置目标
建立一个“销售月报 AI 审核智能体”，实现一个入口自动分流：
- 通过：输出老板一页纸正式版；
- 补充小问题后通过：输出轻量补充清单 + 老板一页纸草稿；
- 打回整改：输出主管整改版；
- 重做月报：输出重做通知 + 主管整改版；
- 整改后上传：自动进入复审；
- 重做后上传：自动进入重做复核。

## 二、GPT 说明区放什么
复制《GPT说明区_销售月报审核官_V1.1_口径过渡版.md》的正文到 GPT Instructions/说明区。

说明区只放总控规则，不放全部长规则。别往 8000 字符的小笼子里塞企业管理宇宙。

## 三、知识区上传什么
只上传 V1.1 最终版文件：
1. 销售月报AI审核SOP_完整版_V1.1_口径过渡版.md
2. 销售月报业务口径与评分规则_V1.1_口径过渡版.md
3. 销售月报输出模板库_V1.1_口径过渡版.md
4. 销售月报复审整改提交模板库_V1.1_口径过渡版.md
5. 销售月报AI智能体配置说明_V1.1_口径过渡版.md
6. 销售小组月报标准版模板_AI适配美化版_V1.1_口径过渡版.docx
7. 销售月报模板与AI审核工具包_V1.1_口径过渡版.xlsx

不要上传旧版本规则文件，也不要上传 zip 包作为知识文件。

## 四、每一步参考哪个文件
| 流程 | 参考文件 |
|---|---|
| 首次初审 / A/B/C/D 分流 | 销售月报AI审核SOP_完整版_V1.1_口径过渡版.md |
| 判断当前主口径、净成交额、回款、GSV、开票、发货 | 销售月报业务口径与评分规则_V1.1_口径过渡版.md |
| 评分、打回、最高分限制 | 销售月报业务口径与评分规则_V1.1_口径过渡版.md |
| 输出老板一页纸、主管整改版、重做通知 | 销售月报输出模板库_V1.1_口径过渡版.md |
| 整改后复审 / 重做后复核 | 销售月报复审整改提交模板库_V1.1_口径过渡版.md |
| 部门填报 Word 模板 | 销售小组月报标准版模板_AI适配美化版_V1.1_口径过渡版.docx |
| 补充表格和复审材料包 | 销售月报模板与AI审核工具包_V1.1_口径过渡版.xlsx |

## 五、建议开启能力
开启 Code Interpreter / Data Analysis，方便读取 Word、Excel、生成表格和老板一页纸。

## 六、测试入口话术
首次审核：
请按销售月报 AI 审核一体化流程，审核我上传的月报，并根据结果自动分流输出。

整改后复审：
直接上传复审材料包即可。如果要加一句话，可写：
请按销售月报 AI 审核一体化流程，对这份整改后月报进行复审。

重做后复核：
请按销售月报 AI 审核一体化流程，对这份重做后月报进行复核，先检查上次重做问题是否解决，再重新分流。

## 七、正式使用建议
- 批量初筛可以一次发 3-5 个小组。
- 正式初审建议一个小组一个会话。
- 整改后复审必须一个小组一个会话或一个完整复审材料包。
- 一个部门 + 一个月份 = 一个独立会话，最稳。

## 八、版本更新提示

分享给部长或其他同事使用时，发布包里必须包含 `VERSION.json`。刘涛每次更新 Skill 后，同时更新发布目录里的 `latest-version.json` 和最新 zip 包。

部长电脑或新电脑使用时，如果能访问 `latest-version.json`，先比较本机 `VERSION.json`：

- 本机版本低于 `latest-version.json`：先提示“销售月报审核 Skill 有新版本”，建议更新后再做正式审核。
- 无法访问 `latest-version.json`：不阻断普通审核，但正式批量审核或首次配置时，提醒用户向刘涛确认是否为最新分享包。
- 用户明确要求旧版继续时，可以继续，但要在风险说明里标注“使用旧版 Skill，可能缺少最新规则”。

仅凭已经发出去的旧 zip，无法自动知道刘涛后来又更新了；要实现更新提醒，至少需要让使用者的电脑能访问一个稳定的最新版本清单，例如发布目录里的 `latest-version.json` 或后续放到飞书共享目录的同名文件。

## 九、正式更新脚本

从 V1.3.0 开始，发布包内包含：

- `scripts/Update-XiaoshouYuebaoSkill.ps1`：部长或同事电脑上的一键更新脚本。
- `scripts/Build-XiaoshouYuebaoSkillRelease.ps1`：刘涛本机发布新版时使用的打包脚本。

部长电脑更新示例：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "liutao96/xiaoshou-yuebao-shenhe"
```

如果已经拿到了固定清单地址，也可以用：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -ManifestUrl "https://api.github.com/repos/liutao96/xiaoshou-yuebao-shenhe/contents/release/latest-version.json?ref=main"
```

如果仓库是私有仓库，部长电脑需要先配置只读 GitHub Token，不要把 Token 发在聊天里，也不要写进 Skill 包：

```powershell
$env:GITHUB_TOKEN="你的只读 GitHub Token"
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Update-XiaoshouYuebaoSkill.ps1" -GithubRepo "liutao96/xiaoshou-yuebao-shenhe"
```

更新脚本会执行：读取远端版本清单、比较本机版本、下载 zip、校验 SHA256、备份旧版到 `$HOME\.codex\skill-backups`、解压覆盖、写日志到 `$HOME\.codex\logs`。更新完成后需要重启 Codex / Claude Code 才能加载新 Skill。

刘涛本机发布新版示例：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\skills\xiaoshou-yuebao-shenhe\scripts\Build-XiaoshouYuebaoSkillRelease.ps1" -ZipUrl "https://raw.githubusercontent.com/liutao96/xiaoshou-yuebao-shenhe/main/release/xiaoshou-yuebao-shenhe.zip" -ManifestUrl "https://api.github.com/repos/liutao96/xiaoshou-yuebao-shenhe/contents/release/latest-version.json?ref=main" -GithubRepo "liutao96/xiaoshou-yuebao-shenhe"
```

正式建议用 GitHub Releases 发布 `xiaoshou-yuebao-shenhe.zip`，同时把 `release/latest-version.json` 放在仓库里。版本检查优先走 GitHub Contents API，避免 raw 文件缓存导致旧版本误判。
