---
name: weekly-report-generation
description: 周报生成与索引维护规范。用于在依赖数据准备完成后，按周期生成周报并维护索引。
---

# 周报生成与索引维护规范

## 1. 目的

基于统计周期、事故报告与组件源数据生成标准化周报 Markdown，并同步维护周报索引，保证周期、指标与事故信息一致。

## 2. 标准来源

- 若仓库根目录存在 `README.md`，以其为口径补充来源；若不存在，以当前文档和同目录模板为准。
- 本执行流程以当前文档为准，不依赖外部全局 skill 目录。
- 周报结构与字段以 `templates/weekly-report-template.md` 为准。
- 事故相关数据优先从 `reports/incidents/annual/<year>.md` 自动提取。
- 周报统计周期固定为：`上周六 -> 本周五`（7 天，含首尾）。
- 附录资源明细优先从 `<data_root>/ecs`、`<data_root>/rds`、`<data_root>/redis`、`<data_root>/mongodb`、`<data_root>/slb`、`<data_root>/cdn`、`<data_root>/eip` 自动生成，并补充组件级建议与改进措施。
- ECS 优先消费 `<data_root>/ecs/ecs-metrics.summary.<week_start>.<week_end>.json` 汇总文件；若存在该文件，周报附录直接展示全量实例，而不是单实例样本。
- ECS/RDS/Redis/MongoDB/SLB/CDN/EIP 等组件数据不仅要有资源清单，还要尽量把该组件当前周报口径需要展示的关键指标完整拉回；如果只拿到资产列表但关键指标仍大面积 `no_data` / `/`，不应视为本周数据准备完成。
- `4.1 接口与流量` 优先从 `<nginx_root>/nginx-traffic.<week_start>.<week_end>.snapshot-*.json` 读取。
- `3. 交付质量与变更风险` 中的发布与证书字段，可优先从 `<data_root>/k8s`、`<data_root>/certificates` 对应结果中提取。
- `3. 交付质量与变更风险` 不应再依赖人工补 `weekly-input` 才能产出；若目录中存在 `k8s-release-metrics.*` 与 `certificate-expiry.*`，应优先自动回填发布次数、发布成功率、回滚次数、CFR 与证书到期提醒。
- 证书数据必须覆盖阿里云 SSL证书管理 V2.0 的“正式证书 / 个人测试证书 / 上传证书”三个标签页；上传证书常承载自有证书，不能因正式证书数量为 0 就写“无有效证书”。
- CDN 附录展示剩余占比时，既要兼容 `package_remaining_ratio`，也要兼容仅提供数值字段 `package_remaining_ratio_percent` 的结果。
- 若未显式传入 `--input`，脚本应自动尝试加载 `data/weekly/weekly-input.<week_start>.<week_end>.json`；该文件只承载有效告警等补充字段，不作为云资源核心指标来源。
- SLB、EIP、证书等报告日快照类资源允许匹配 `week_end + 1 day` 的快照，适配周六生成上周周报的执行习惯。
- Redis 内存类指标若来源字段为 bytes，例如 `used_memory_bytes`，展示前必须换算为 MB/GB，不能把原始 bytes 直接标成 MB。
- 周报正文禁止出现“本次以某日快照代理本周”“报告日数据代理本周”之类表述；若必须说明来源，只能写入源 JSON 的 `notes`，不能进入周报正文。

## 3. 适用场景

- 新增某周运行周报。
- 修正周报周期（起止日期）或指标值后重生成。
- 周报索引存在重复周期、旧周期残留或链接错误时清理。

## 4. 输入与输出

输入：
- 必填周期：`--week-start <YYYY-MM-DD>` + `--week-end <YYYY-MM-DD>`
- 可选补充输入：`data/weekly/weekly-input.<week_start>.<week_end>.json`
- 可选云厂商：`provider`（默认 `aliyun`）

说明：
- 周报脚本可直接按周期生成；但更适合先准备好本周期依赖数据，再进入生成阶段。
- 组件指标目录通过 `--data-root` 显式指定，可抽象记为 `<data_root>`。
- Nginx 结构化指标目录通过 `--nginx-root` 显式指定，可抽象记为 `<nginx_root>`。
- `data/weekly/weekly-input.<week_start>.<week_end>.json` 仅作为可选补充输入，用于填充暂未自动采集的数据，例如告警事件、摘要说明、风险与下周重点等。
- 若本周期所有结构化来源已齐备，优先直接生成，不应先要求创建 `weekly-input`。
- 若补充输入与目录内结构化结果同时存在，显式提供的字段优先，缺失字段再由目录结果补齐。
- 核心可用率默认根据事故报告中的 `开始修复处理时间 -> 恢复时间` 自动计算；若未专门声明影响层级，默认仅计入“平台业务可用率”。
- 可靠性效率指标默认从事故报告自动计算：MTTD 使用 `发生时间 -> 检测时间`，MTTA 使用 `检测时间 -> 首次响应时间`，MTTR 使用 `开始修复处理时间 -> 恢复时间`，MTBF 使用相邻事故发生时间间隔；若本周期内无相邻事故，则展示截至周期结束距离上次故障的无故障间隔。
- 当用户明确要求“用生成周报当天的组件数据当作本周数据”时，可以接受使用报告日采集到的组件数据生成当周组件文件，但相关来源说明只能写在对应组件 JSON 的 `notes` 中，不能进入周报正文、`report_highlights` 或补充输入摘要。
- 若周报所需阿里云数据尚未准备完成，周报 skill 应先明确数据拉取范围：默认从深圳开始检查，但必须继续补查其他可见地域；该顺序属于周报数据准备规则，而不是阿里云拉取 skill 的全局默认行为。
- 调用阿里云数据拉取流程时，应要求使用项目内 `.codex/skills/aliyun-metrics`，并按“真实来源、范围完整、口径一致、证据可追溯”的完成标准验收。
- 周报场景下，阿里云数据应尽量与上一周期同口径：服务集合、地域范围、资源分页、关键展示指标和输出文件类型都应对齐；新增或减少资源需要有控制台证据。

输出：
- `reports/weekly/<year>/<year>-W<week>.md`
- `reports/weekly/index.md`

可选后续发布：
- 当用户要求同步到钉钉文档时，更适合在本地 Markdown 与索引更新完成后，再调用通用 `dingtalk-docs` skill 上传对应 `.md` 文件。
- 具体上传到哪个目录，不由本 skill 固化；目录选择由当前业务场景决定。
- 周报场景下，调用 `dingtalk-docs` 时通常会把目标目录明确为 `平台运行情况`，再由该 skill 负责在钉钉里定位并上传。

## 5. 参考步骤

1. 可先确认统计周期是否满足“周开始=周六、周结束=周五”；若生成阶段性快照，可结合 `--allow-partial-week` 使用。
2. 生成周报前，更适合先确认本周期依赖数据已经准备完成。
   - 事故数据：`reports/incidents/annual/<year>.md`
   - 组件指标：`<data_root>/ecs`、`<data_root>/rds`、`<data_root>/redis`、`<data_root>/mongodb`、`<data_root>/slb`、`<data_root>/cdn`、`<data_root>/eip`
   - 交付与证书：`<data_root>/k8s`、`<data_root>/certificates`
   - 流量指标：`<nginx_root>/nginx-traffic.<week_start>.<week_end>.snapshot-*.json`
   - 补充输入：`data/weekly/weekly-input.<week_start>.<week_end>.json`
   - 若本步需要调用阿里云数据拉取流程补数据，周报场景下应先从深圳开始，再补充其他可见地域；最终口径不能退化成只统计深圳。
   - 调用 `aliyun-metrics` 前，应先读取上一周期同类 JSON，整理本周期采集清单：服务、地域、实例/资源 ID、关键指标字段、输出文件命名。
   - 调用 `aliyun-metrics` 时，应显式传入同一 `time_window`、同一 `snapshot_date`、完整 `region_scope`、`metric_scope=all`，并启用严格一致性要求。
   - 阿里云数据必须来自当前浏览器中阿里云控制台页面或页面网络请求；不能用旧数据、模板占位符、经验估算或周报正文反推本期指标。
   - 每个阿里云输出文件应包含采集来源或证据字段，例如 `collection.source_type`、`collection.request_evidence`、`collection.collected_regions`、`collection_status` 或等价信息。
   - 若 ECS/SLB/EIP 属于跨地域资源，本步应先确认数据已覆盖深圳之外的可见地域，避免漏掉青岛等非主地域资产。
   - 若 ECS 仅落出实例清单但 CPU / 内存 / 磁盘 / 连接数等关键展示指标未回填，应继续通过阿里云控制台页面请求补抓监控接口，再生成周报；不能直接接受“全量实例 + 指标全空白”为正式周报口径。
   - 若其他组件也出现“资源已发现但展示指标未回填”的情况，同样应优先补齐结构化源数据，再生成周报，而不是把大量 `/` 直接带入正式周报。
   - 若任一服务的 `collection_status` 为 `partial`、`incomplete`、`failed`，或无法证明来源真实、范围完整、口径一致，应先补抓或在反馈中明确阻塞，不应直接生成正式周报。
   - 证书 JSON 中若 `collection.visited_tabs` 或等价 `notes` 未能证明已检查上传证书页，且资源中心/概览显示存在 SSL 证书，应先回到 `aliyun-metrics` 补抓上传证书后再生成周报。
   - 若本周期资源数量相对上一周期突变，应优先核对地域、分页、过滤条件和权限是否变化；确认后再把变化写入周报。
   - 若 Nginx 峰值明显异常，本步应先检查该峰值是否来自下载、静态资源、更新包或其他不应计入 4.1 的接口；确认后先修正口径再生成周报。
3. 执行生成命令：

   以下命令默认在项目仓库根目录执行。

```bash
python3 .codex/skills/weekly-report-generation/scripts/generate_weekly_report.py --week-start 2026-03-21 --week-end 2026-03-27 --data-root <data_root> --nginx-root <nginx_root>
```

若存在标准补充输入文件 `data/weekly/weekly-input.2026-03-21.2026-03-27.json`，且未显式提供 `--input`，脚本会自动加载该文件。显式 `--input` 仍然优先。

如需补充人工字段：

```bash
python3 .codex/skills/weekly-report-generation/scripts/generate_weekly_report.py --week-start 2026-03-21 --week-end 2026-03-27 --input data/weekly/<input-file>.json --data-root <data_root> --nginx-root <nginx_root>
```

阶段性快照命令：

```bash
python3 .codex/skills/weekly-report-generation/scripts/generate_weekly_report.py --week-start 2026-03-28 --week-end 2026-03-31 --allow-partial-week --data-root <data_root> --nginx-root <nginx_root>
```

4. 若同一年多周数据有变更，可按时间顺序逐个重生成。
5. 可再核对周报正文与索引是否同步更新。
   - 尤其检查附录是否已经按组件生成，而不是继续沿用手工汇总表。
   - 正文不维护“云资源运行情况”汇总表和“资源热点”聚合区块；资源观察以下沉后的组件章节为准。
   - 同时检查每个组件是否已输出“重点观察”和“建议与改进措施”。
   - 周报成文中不展示源数据文件路径；数据文件路径只在执行反馈或排障场景中说明。
6. 校验时可优先关注本次新生成的周报文件；如需全量校验，再扩展到全仓范围。

模板校验要求：
- 对本次新周报，可优先做单文件模板校验。
- 若执行 `python3 .codex/skills/weekly-report-generation/scripts/validate_weekly_templates.py --scope weekly` 失败，仍可继续分析本次结果，但更适合在反馈中说明原因。

单文件校验示例：

```bash
python3 .codex/skills/weekly-report-generation/scripts/validate_weekly_templates.py --scope weekly --reports-dir reports
```

全量校验命令：

```bash
python3 .codex/skills/weekly-report-generation/scripts/validate_weekly_templates.py --scope weekly
```

## 6. 建议核对项

- 周报文件名周期、命令行周期、正文标题周期一致。
- 周期为 7 天，且满足“上周六到本周五”。
- 生成前已尽量刷新周报周期内的 data，各组件 JSON 较好地覆盖到本次统计结束日。
- 阿里云数据已按项目内 `aliyun-metrics` 的严格口径完成：真实来源、范围完整、同周统一时间窗、跨周同口径、证据可追溯。
- `services` 含 `ecs` 时，更适合采用全量实例口径（跨地域、跨分页、全实例）；若仅有单实例样本，可在反馈中说明其适用范围。
- 若 ECS 已拉全量数据，周报附录通常会优先消费 `ecs-metrics.summary.<week_start>.<week_end>.json`，并展示全量实例。
- 若 ECS 汇总文件中的关键监控指标仍大面积 `no_data`，应优先视为拉取不完整，而不是周报模板问题。
- 资源类组件只要已经进入周报附录，就应优先保证“资源发现 + 关键展示指标”同时完整；除确实不存在该指标或页面不可得外，不应接受整列长期空白。
- 若 `4.1` 已读取 `<nginx_root>` 下的结构化结果，更适合明确该统计口径，例如是否排除 WebSocket、下载类接口，以及响应时间是否只统计成功请求。
- 若 `4.1` 的峰值接口不属于业务 API，应先回到 Nginx 分析步骤扩展排除前缀，再重算结构化结果，而不是在周报正文里解释异常值。
- 可用率已按事故报告中的 `开始修复处理时间 -> 恢复时间` 自动计算，并正确裁剪到周 / 月 / 年统计窗口。
- 如果同一时段内存在多个事故，已按时间区间合并后再扣减可用率，避免重复计算不可用时长。
- 若使用补充 JSON，其中的发布、告警、接口 SLA 等字段已按本周期最新源数据同步更新。
- 若 `ops_release` 已更新，其来源更适合参考阿里云 K8S 控制台统计结果，而不是人工回忆。
- 若 `monitoring_security.cert_expiry` 已更新，其来源更适合参考阿里云数字证书管理服务中的较新证书有效期信息。
- 证书摘要应优先使用结构化 JSON 的 `report_compatibility.suggested_summary` 或 `overview.suggested_summary`；当摘要缺失时，应从 `certificates[]` 中按 `status_code/type/not_after/expires_on/remaining_days_ui/notice_status` 重新计算有效证书、过期证书、最早到期与未开启提醒数量。
- 若存在 `k8s`、`certificates`、`cdn` 结构化结果，生成后不应再出现这几项“未填写”或剩余占比为空白的情况；若出现，优先视为数据接线或字段兼容问题。
- 若周六生成上周周报，SLB、EIP、证书快照可使用周五或周六采集文件，但报告正文不展示“用某日快照代理本周”。
- Redis 内存展示单位已完成换算，`used_memory_bytes` 这类 bytes 字段不应以原始数值直接显示为 MB。
- “核心可用率”已体现本周、本月、本年度三个维度。
- 可靠性效率指标包含 MTTD、MTTA、MTTR、MTBF，并已根据事故报告时间字段自动计算。
- 交付质量与变更风险包含发布次数、发布成功率、回滚次数、CFR。
- 索引中同一周报文件仅保留一条有效周期记录。
- 同一指标不在多个主模块重复展示（附录仅保留明细）。
- 附录中的 ECS、RDS、Redis、MongoDB、SLB、CDN、EIP 组件分段，通常会来自 `--data-root` 指定目录下已拉取的 JSON。
- 周报正文和附录中不应出现 `data/...` 源文件路径。
- 周报正文不展示阿里云采集证据路径；证据只用于本地校验和执行反馈。
- 如果组件文件使用报告日数据作为本周来源，更适合在对应 JSON 中留下明确 `notes` 说明，而这些来源说明通常不直接进入周报正文。
- 统计周期之外的旧数据或未刷新数据，更适合作为补充说明而不是直接当作当周正式口径。
- 附录中的组件建议更适合由真实指标触发，而不是固定套话。
- 故障数、MTTR 与当周输入数据口径一致。
- 事故明细中的事故编号与本地事故报告一致。

## 8. 约束与边界

- 一般不建议手工直接编辑 `reports/weekly/index.md` 来修正数据。
- 一般不建议绕过源数据，直接把周报正文作为最终来源。
- 若 ECS 只有样本数据而非全量视图，更适合作为阶段性结果，而不是正式周报交付口径。
- 若阿里云数据无法满足“真实、一致、完整、可追溯”，更适合暂停正式周报生成并补齐数据，而不是用旧数据或空指标凑齐。
- 本 skill 负责周报本地 Markdown 与索引产物，不负责固化钉钉目录名。
- 若需要同步钉钉，更适合在本地周报生成成功后，再把“上传哪个文件到哪个目录”的决定交给调用方或后续发布步骤。
- 若已发现结构化来源与模板字段不兼容，优先修正 skill 脚本或模板兼容逻辑，不建议在周报 Markdown 中做一次性人工补丁。

## 9. 完成后反馈

至少反馈：
- 使用的统计周期。
- 更新的补充输入文件路径（若有）。
- 生成的周报路径与索引路径。
- 本次修正的周期或指标项（若有）。
