# Zotero 知网学位论文元数据修复（大学 / 日期）

修复 Zotero 从 **知网检索结果页批量保存学位论文** 时丢失「大学（学位授予单位）」和「日期（授予年度）」的问题。

- 适用：Zotero 7+、中文知网（kns.cnki.net）、Chrome / Edge 的 Zotero Connector
- 现象：批量勾选保存后，条目类型是「学位论文」，但「大学」「日期」为空；单篇打开详情页再保存有时正常
- 不适用：知网全文下载被「拼图校验」拦截（见下文「PDF 下载」）

## 原理

Zotero 抓知网分三层，问题出在第二层：

1. **译者（Translator）**：`CNKI.js` 负责把页面转成 Zotero 条目
2. **连接器（Zotero Connector）**：保存动作由浏览器扩展执行，扩展会**缓存译者代码**
3. **Zotero 客户端**：连接器从客户端取译者代码，再把条目写入数据库

批量保存时，译者对每条记录重新请求详情页（`requestDocument`，只取 HTML、不执行 JS）。学位论文的详情页里：

- 「网络出版时间」是 `2022-02-16—2022-03-15` 这样的区间，无法解析成日期
- 「学位授予单位」在详情页的 `.top-tip` 里，是 JS 渲染的，静态 HTML 里没有
- 真正的授予年度和学校在知网的 **EndNote 导出接口**（`GetExport`）里，字段是 `%D` 和 `%I`

批量路径拿不到这些运行时字段，于是「大学」「日期」为空。

另外，**检索结果行本身**已经带有这些信息：

| 信息 | 结果行选择器 |
|---|---|
| 日期 | `td.date` |
| 大学 | `td.source a`（部分页面）或 `td.unit a` |
| 导出 ID | `input.cbItem` 的 `value` |

## 修复内容

基于 [l0o0/translators_CN](https://github.com/l0o0/translators_CN) 的 `CNKI.js`（2026-09-29）做增量修改：

1. `getSearchResults` 批量收集每行的 `date`、`university`、`exportId`
2. `doWeb` / `scrape` / `scrapeMain` 把行数据传入抓取流程
3. 字段缺失时，用行数据兜底（`td.source a` 或 `td.unit a`）
4. 新增 `getEndNoteFields`：直接解析 EndNote 的 `%D` / `%I`，不依赖嵌套导入译者
5. 详情页取不到 `dbname/filename` 时，URL 改存真实页面地址
6. `#ndate` 区间取首个日期作为兜底；接口没返回日期时不覆盖已有值
7. 写入 `PatchDebug` 到 Extra，便于验证补丁是否生效（`endnote-ok` / `endnote-null`）

完整改动见 `CNKI.js.original` 与 `CNKI.js` 的 diff。

## 安装

### 一键脚本

1. 完全退出 Zotero
2. 运行对应脚本：
   - macOS：`bash install-macos.sh`
   - Windows：右键 `install-windows.ps1` → 使用 PowerShell 运行
   - Linux：`bash install-linux.sh`
3. 启动 Zotero
4. 在浏览器点击 Zotero 连接器 → 设置 → 高级 → **Reset Translators**
5. 刷新知网检索页，批量保存 2 篇学位论文验证

脚本会先备份原文件为 `CNKI.js.bak-时间戳`，并自动更新 `lastUpdated`。

### 手动安装

1. Zotero → 设置 → 高级 → 文件和文件夹，找到「数据存储位置」
2. 进入 `translators/`，备份 `CNKI.js`
3. 用本仓库的 `CNKI.js` 覆盖
4. 重启 Zotero
5. 连接器 → 设置 → 高级 → **Reset Translators**

## 验证

新抓的学位论文应满足：

- 条目类型：学位论文
- 「大学」有值（如：四川师范大学）
- 「日期」有年份
- 「学位类型」为硕士/博士
- Extra 中有 `PatchDebug: endnote-ok`（或 `endnote-null`）
- 条目下有 PDF 附件

## 常见问题

### 改了文件为什么没生效？

连接器有独立缓存。必须 **重启 Zotero + Reset Translators**，只改文件不够。

### 为什么单篇抓正常、批量抓缺字段？

单篇抓取使用浏览器里已渲染的 DOM（有 `.top-tip`）；批量抓取是 HTTP 请求静态 HTML。补丁正是为批量路径补上结果行数据和 EndNote 解析。

### PDF 不自动下载了？

先看知网返回的是不是「拼图校验-中国知网」。连续下载过多会触发滑块验证，连接器无法自动完成：

1. 手动打开一篇论文，点「PDF下载」，完成拼图
2. 降低批量速度，一次少抓几篇

### 译者更新后修复失效？

Zotero 或茉莉花更新译者会覆盖 `CNKI.js`。重新运行安装脚本即可。脚本会把 `lastUpdated` 改为安装时间。

### 需要安装茉莉花吗？

不需要。问题是 `CNKI.js`，与茉莉花无关；但茉莉花可能触发译者更新并覆盖补丁。

## 回滚

把 `translators/CNKI.js.bak-时间戳` 改名回 `CNKI.js`，重启 Zotero，再 Reset Translators。

## 许可与来源

- 原始译者：[l0o0/translators_CN](https://github.com/l0o0/translators_CN)，AGPL-3.0
- 本项目为衍生修改，同样以 AGPL-3.0 发布，见 `LICENSE`
- 与 Zotero、知网官方无关

## English summary

Patch for Zotero's CNKI translator: when batch-saving theses from CNKI search results, "University" and "Date" are empty because the batch path fetches static HTML. This patch reads those fields from the result rows and the CNKI EndNote export (`%D` / `%I`), with fallbacks. After installing, restart Zotero and click **Reset Translators** in the Zotero Connector.
