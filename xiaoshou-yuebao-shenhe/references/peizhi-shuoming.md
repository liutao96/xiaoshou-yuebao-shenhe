# 销售月报审核 Skill 配置与分发说明

## 一、配置目标
建立一个“销售月报 AI 审核智能体”，实现一个入口自动分流：
- 通过：输出完整主报告，并额外单独生成老板一页纸正式版；
- 补充小问题后通过：输出完整主报告，并在报告前部放“补充小问题清单 / 部长重点看”；
- 打回整改：输出完整主报告，并在报告前部放“主管整改版 / 部长重点看”；
- 重做月报：输出完整主报告，并在报告前部放“重做通知 / 部长重点看”和主管整改要求；
- 整改后上传：自动进入复审；
- 重做后上传：自动进入重做复核。

## 二、GPT 说明区放什么
在 Codex 中直接安装当前 Skill 包即可，不需要把旧版总控说明复制到另一个 GPT 的 Instructions。

## 三、Skill 包含什么
Skill 只包含销售月报审核规则、初审/复审/14 模块流程、评分分流、报告生成和更新脚本。
业务人员不需要上传模板；部长只需发送飞书月报链接。用户提交实际 Word/Excel 月报时，Skill 直接读取实际材料。
Skill 不内置月报填报模板或条件化补充工具包，避免把补充表误当成审核前置材料。

## 四、部长实际怎么使用

部长不需要学习命令，也不需要打开规则补丁库。安装并重启 Codex 后，按下面三类话术使用即可。

首次审核：

```text
审核这个月报：<飞书月报链接>
```

也可以只发送飞书月报链接，Skill 会自动按销售月报审核入口处理。

整改后复审：

```text
这是修改后的月报，请做复核：<飞书月报链接>
```

如果 Codex 找不到上次 AI 初审报告，再补上次初审报告或主管整改版。

发现 Skill 判断不对：

```text
这里不对，达人组不需要销售回款，这个不应该扣分，以后遇到达人组按这个口径处理。
```

Codex 必须先修正当前报告，再判断是否要沉淀规则补丁。只要部长已经具备“销售月报审核规则补丁库”的编辑权限，满足规则补丁条件时默认自动写入，不需要部长再填反馈表或每次确认。

写入规则补丁后，Codex 要在聊天区告诉部长两件事：

1. 当前报告已经按部长口径修正。
2. 已沉淀几条规则补丁，以及状态是 `待确认` 还是 `已生效`。

纯粹改措辞、格式、语气，不改变审核判断的，不写入规则补丁库。

## 五、每一步参考哪个文件
| 流程 | 参考文件 |
|---|---|
| 首次初审 / A/B/C/D 分流 | `shenhe-sop.md` |
| 判断当前主口径和关键销售数据 | `pingfen-guize.md` |
| 评分、打回、最高分限制 | `pingfen-guize.md` |
| 输出老板一页纸、主管整改版、重做通知和部长重点看章节 | `shuchu-muban.md`、`jiaofu-xingtai.md` |
| 整改后复审 / 重做后复核 | `fushen-jianhua-rukou.md`、`fushen-zhenggai.md` |
| 规则补丁读取和部长纠错沉淀 | `guize-buding-ku.md` |
| 正式审核报告 | Word + Markdown，按审核结果生成 |

## 六、建议开启能力
开启 Code Interpreter / Data Analysis，方便读取 Word、Excel、生成表格和老板一页纸。

## 七、测试入口话术
首次审核：
请按销售月报 AI 审核一体化流程，审核我上传的月报，并根据结果自动分流输出。

整改后复审：
直接上传复审材料包即可。如果要加一句话，可写：
请按销售月报 AI 审核一体化流程，对这份整改后月报进行复审。

重做后复核：
请按销售月报 AI 审核一体化流程，对这份重做后月报进行复核，先检查上次重做问题是否解决，再重新分流。

## 八、正式使用建议
- 批量初筛可以一次发 3-5 个小组。
- 正式初审建议一个小组一个会话。
- 整改后复审必须一个小组一个会话或一个完整复审材料包。
- 一个部门 + 一个月份 = 一个独立会话，最稳。

## 九、版本更新提示

分享给部长或其他同事使用时，发布包里必须包含 `VERSION.json`。刘涛每次更新 Skill 后，同时更新发布目录里的 `latest-version.json` 和最新 zip 包。

调用销售月报审核 Skill 后，第一步必须检查云端版本。版本检查优先级高于读取飞书月报、读取规则、复审对照、评分和生成老板一页纸。

部长电脑或新电脑使用时，如果能访问 `latest-version.json`，先比较本机 `VERSION.json`：

- 本机版本低于 `latest-version.json`：先提示“销售月报审核 Skill 有新版本”，正式审核、复审、老板一页纸生成默认暂停，先更新后再继续。
- 无法访问 `latest-version.json`：可以继续做材料读取或试审，但正式结论必须标注“本次未能确认 Skill 是否最新，可能缺少云端新规则”；正式批量审核、部长首次配置、复审通过、老板一页纸生成场景，优先让用户先解决更新检查问题。
- 用户明确要求旧版继续时，可以继续，但要在风险说明里标注“使用旧版 Skill，可能缺少最新规则，本次结论不作为最新规则下的正式终版”。

仅凭已经发出去的旧 zip，无法自动知道刘涛后来又更新了；要实现更新提醒，至少需要让使用者的电脑能访问一个稳定的最新版本清单，例如发布目录里的 `latest-version.json` 或后续放到飞书共享目录的同名文件。

## 十、正式更新脚本

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
