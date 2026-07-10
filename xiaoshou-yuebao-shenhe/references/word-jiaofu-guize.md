# Word 正式交付规则

## 目的

销售月报审核不是只给 Codex 或技术人员看。部长、主管、业务人员、老板助理更常用 Word 文档流转、保存和打印。

因此正式初审、深度审核、C/D 打回整改、复审结果，默认不能只生成 Markdown。Markdown 是可追溯底稿，Word 是业务流转正式版。

## 默认双交付

以下场景默认同时生成两份：

1. Markdown 底稿：用于版本追踪、继续复审、复制到飞书或二次编辑。
2. Word 文档：用于部长、主管、业务人员保存、转发、打印和正式流转。

必须双交付的场景：

- 部长或管理者只贴飞书链接发起正式初审；
- 正式初审；
- 完整 14 模块报告；
- 深度经营诊断；
- C 类 / D 类主管整改；
- 复审结论需要留档；
- 用户说“给主管、给部门、给老板、留档、正式版、业务人员看”。

## 文件命名

Markdown：

```text
outputs/feishu_monthly_audit/YYYY-MM_部门或小组_销售月报AI初审报告.md
```

Word：

```text
outputs/feishu_monthly_audit/YYYY-MM_部门或小组_销售月报AI初审报告.docx
```

如果是复审：

```text
outputs/feishu_monthly_audit/YYYY-MM_部门或小组_销售月报AI复审结果.md
outputs/feishu_monthly_audit/YYYY-MM_部门或小组_销售月报AI复审结果.docx
```

## 聊天区展示顺序

聊天区给报告路径时，Word 放在前面，Markdown 放在后面：

```text
完整报告已生成：
- Word 正式版：...
- Markdown 底稿：...
```

不能只展示 Markdown 路径，除非 Word 生成失败。

## Word 生成失败时

如果当前环境缺少文档处理能力，或 Word 生成失败：

1. 不阻断审核结论；
2. 交付 Markdown 底稿；
3. 在聊天区明确说明“Word 正式版生成失败/当前环境缺少文档处理能力”；
4. 说明下一步：可在有 Word 生成能力的 Codex 环境中用 Markdown 底稿转换，或安装/启用文档处理能力后重试。

## 不允许

- 不允许正式初审只生成 `.md`，然后让业务人员自己找软件打开。
- 不允许把“Markdown 报告已生成”当作部长端完整交付。
- 不允许 Word 只包含简化摘要而 Markdown 才有完整 14 模块；Word 必须包含完整报告主体。
- 不允许在聊天区只贴 Markdown 路径，不提示 Word 是否生成。
