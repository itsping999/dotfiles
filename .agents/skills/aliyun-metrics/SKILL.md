---
name: aliyun-metrics
description: 阿里云统一数据拉取 skill。复用当前已登录控制台会话，按调用参数显式传入地域、时间范围和输出目录，拉取 ECS/RDS/Redis/MongoDB/K8S/SLB/CDN/EIP/SMS/Voice/Email/Certificate 数据。
---

# 云平台（默认阿里云）统一数据拉取规范

## 1. 目的

这个 skill 的目标是：
- 单一 skill 即可独立完成云资源数据拉取。
- 调用方显式传入地域范围、时间范围与输出目录，skill 不做默认推断。
- 在权限允许范围内尽量扩大指标覆盖（`metric_scope=all`）。
- 同一统计窗口、同一服务、同一地域范围下，每次拉取的数据口径必须一致。
- 输出只能来自当前已登录阿里云控制台页面或页面网络请求中的真实数据，不能估算、编造或手填云资源指标。
- 输出到调用方指定目录，供后续分析流程复用。

## 2. 标准来源

- 若仓库根目录存在 `README.md`，以其目录口径补充来源；若不存在，以当前文档与 `templates/` 为准。
- 默认云厂商为阿里云；若调用方指定其他厂商，保持同一流程并替换控制台入口、指标命名和输出目录中的 `provider`。
- 复用当前已登录的真实控制台会话，不切换到干净浏览器 profile。
- 地域范围由调用方通过 `region_scope` 显式指定；skill 不做默认地域推断。
- 采集优先使用浏览器中阿里云控制台真实页面触发的网络请求；用户明确要求从网页请求获取时，禁止改用 OpenAPI、SDK 或离线缓存。
- 历史输出文件只能用于比对字段完整性和口径漂移，不能作为本次真实数据来源。

## 3. 调用参数契约

建议由调用方显式提供：

```json
{
  "provider": "aliyun",
  "services": [
    "ecs",
    "rds",
    "redis",
    "mongodb",
    "k8s",
    "slb",
    "cdn",
    "eip",
    "sms",
    "voice",
    "email",
    "certificates"
  ],
  "time_window": {
    "start": "YYYY-MM-DD HH:MM:SS",
    "end": "YYYY-MM-DD HH:MM:SS",
    "timezone": "Asia/Shanghai",
    "snapshot_date": "YYYY-MM-DD"
  },
  "region_scope": {
    "regions": ["cn-shenzhen", "cn-hangzhou"],
    "cross_region": true
  },
  "output": {
    "root_dir": "<data_root>"
  },
  "metric_scope": "all",
  "metric_profile": {
    "default_level": "all",
    "service_overrides": {
      "ecs": "all",
      "rds": "extended"
    }
  },
  "aggregation_policy": {
    "priority": ["Average", "Value", "Maximum", "Minimum"]
  },
  "failure_policy": {
    "mode": "partial_success",
    "continue_on_service_error": true
  },
  "consistency_policy": {
    "mode": "strict",
    "require_request_evidence": true,
    "forbid_synthetic_values": true,
    "require_same_scope_as_previous_week": true
  }
}
```

参数建议：
- `time_window.start/end/timezone` 通常应明确提供。
- `time_window.snapshot_date` 更适合在快照型任务中提供。
- `region_scope.regions` 建议至少包含一个明确地域。
- `output.root_dir` 建议由调用方显式指定。
- `metric_scope` 支持 `core|extended|all`，默认 `all`。
- `metric_profile` 由调用方指定，用于覆盖服务级指标档位（可选）。
- `aggregation_policy.priority` 由调用方指定聚合优先级（可选）。
- `failure_policy` 由调用方指定失败处理策略（可选）。
- `consistency_policy` 用于约束同周/跨周拉取的一致性，周报场景建议使用 `strict`。
- `services` 通常至少包含一个服务。

最小调用样例（单服务）：

```json
{
  "provider": "aliyun",
  "services": ["ecs"],
  "time_window": {
    "start": "2026-04-04 00:00:00",
    "end": "2026-04-10 23:59:59",
    "timezone": "Asia/Shanghai"
  },
  "region_scope": {
    "regions": ["cn-shenzhen"],
    "cross_region": false
  },
  "output": {
    "root_dir": "<data_root>"
  },
  "metric_scope": "all",
  "metric_profile": {
    "default_level": "all"
  },
  "aggregation_policy": {
    "priority": ["Average", "Value", "Maximum", "Minimum"]
  },
  "failure_policy": {
    "mode": "partial_success",
    "continue_on_service_error": true
  },
  "consistency_policy": {
    "mode": "strict",
    "require_request_evidence": true,
    "forbid_synthetic_values": true
  }
}
```

多服务调用样例：

```json
{
  "provider": "aliyun",
  "services": ["ecs","rds","redis","mongodb","slb","cdn","eip","k8s","certificates"],
  "time_window": {
    "start": "2026-04-04 00:00:00",
    "end": "2026-04-10 23:59:59",
    "timezone": "Asia/Shanghai"
  },
  "region_scope": {
    "regions": ["cn-shenzhen", "cn-hangzhou"],
    "cross_region": true
  },
  "output": {
    "root_dir": "<data_root>"
  },
  "metric_scope": "all",
  "metric_profile": {
    "default_level": "all"
  },
  "aggregation_policy": {
    "priority": ["Average", "Value", "Maximum", "Minimum"]
  },
  "failure_policy": {
    "mode": "partial_success",
    "continue_on_service_error": true
  },
  "consistency_policy": {
    "mode": "strict",
    "require_request_evidence": true,
    "forbid_synthetic_values": true,
    "require_same_scope_as_previous_week": true
  }
}
```

## 4. 服务路由与输出

统一 skill 通过 `services` 路由到对应服务执行步骤，并套用对应模板：

- `ecs`
  - 模板：`templates/ecs-metrics.summary.template.json`
  - 输出：`<data_root>/ecs/ecs-metrics.summary.<start>.<end>.json`
- `rds`
  - 模板：`templates/rds-metrics.template.json`
  - 输出：`<data_root>/rds/rds-metrics.<region>.<engine>.<start>.<end>.json`
- `redis`
  - 模板：`templates/redis-metrics.template.json`
  - 输出：`<data_root>/redis/redis-metrics.<region>.<instance-slug>.<start>.<end>.json`
- `mongodb`
  - 模板：`templates/mongodb-metrics.template.json`
  - 输出：`<data_root>/mongodb/mongodb-metrics.<region>.<instance-slug>.<start>.<end>.json`
- `k8s`
  - 模板：`templates/k8s-release-metrics.template.json`
  - 输出：`<data_root>/k8s/k8s-release-metrics.<scope>.<start>.<end>.json`
- `slb`
  - 模板：`templates/slb-metrics.template.json`
  - 输出：`<data_root>/slb/slb-metrics.<scope>.<date>.json`
- `cdn`
  - 模板：`templates/cdn-usage.template.json`
  - 输出：`<data_root>/cdn/cdn-usage.<scope>.<start>.<end>.json`
- `eip`
  - 模板：`templates/eip-load.template.json`
  - 输出：`<data_root>/eip/eip-load.<region>.<date>.json`
- `sms`
  - 模板：`templates/sms-usage.template.json`
  - 输出：`<data_root>/sms/sms-usage.<scope>.<start>.<end>.json`
- `voice`
  - 模板：`templates/voice-usage.template.json`
  - 输出：`<data_root>/voice/voice-usage.<region>.<start>.<end>.json`
- `email`
  - 模板：`templates/email-usage.template.json`
  - 输出：`<data_root>/email/email-usage.<region>.<start>.<end>.json`
- `certificates`
  - 模板：`templates/certificate-expiry.template.json`
  - 输出：`<data_root>/certificates/certificate-expiry.<scope>.<date>.json`

## 5. 执行流程

1. 校验调用参数完整性。
   - 若存在缺失项，优先反馈缺失内容，而不是自行补全时间范围、地域范围或输出目录。
   - 在周报场景中，若调用方要求“按照上周指标范围拉取”，应先读取上一周期同类 JSON 的服务清单、地域清单、资源数量、关键指标字段和输出文件命名，再按同一口径采集本周期数据。
   - 若上一周期存在某个服务、地域或关键指标，本周期不能静默省略；确实无法获取时必须在 `collection_status` 和执行反馈中说明阻塞原因。

2. 复用当前控制台会话，按 `services` 逐项执行。
   - 若运行环境支持并行，可并行拉取服务。
   - 若不支持并行，可按如下顺序处理：`ecs -> rds -> redis -> mongodb -> k8s -> slb -> cdn -> eip -> sms -> voice -> email -> certificates`。
   - 每个服务拉取完成并确认 JSON 落盘后，可关闭该服务对应的浏览器标签页，再进入下一个服务，以减少标签页堆积和会话混淆。
   - 对 `ecs`、`slb`、`eip` 这类明显具有跨地域属性的资源，应严格按调用方给定的 `region_scope` 执行；若 `cross_region=true`，应继续补查其余目标地域并合并结果，不能在首个地域命中后提前结束。
   - 控制台存在分页时必须逐页拉取到最后一页；不能只取当前可见页、首屏、默认 10 条或搜索结果页。
   - 跨地域资源应记录实际访问过的地域、每个地域发现的资源数，以及被排除地域的原因。

3. 每个服务都遵循同一覆盖策略。
   - 默认使用 `metric_scope`，若定义了 `metric_profile.service_overrides` 则按服务覆盖。
   - `core`：只拉核心指标。
   - `extended`：核心 + 常用扩展指标。
   - `all`：核心 + 扩展 + 当前页面/API 可见的其余可访问指标，并在 `metric_coverage.extended_metrics_unavailable` 标注不可用项。
   - 指标查询必须使用调用参数中的 `time_window`；若控制台页面只能提供快照，应把 `snapshot_date` 写入 `time_window` 和 `collection.evidence`，并避免把快照冒充为完整周期曲线。

4. 结果归一化。
   - 无样本：`no_data`
   - 不支持或权限受限：`unavailable`
   - 聚合优先级由 `aggregation_policy.priority` 指定；未指定时再使用 `Average -> Value -> Maximum -> Minimum`。
   - 对资源类服务，不能只保存资源发现结果就结束；若目标模板需要展示 CPU、内存、磁盘、连接数、利用率、剩余量等关键指标，应继续追到页面或接口里可稳定获取的监控值，并一起写回结果。
   - 禁止把旧周期值、示例模板值、页面占位符、`placeholder`、人工推测值写成真实指标。
   - 若某个指标确实不可得，只能写 `no_data`、`unavailable` 或带原因的 `status`，不能补一个看起来合理的数字。

5. 写入 JSON 并校验格式。
   - 优先执行 `jq empty <file>`；若无 `jq`，使用等价 JSON 解析校验。
   - 每个输出文件应包含可审计来源信息，例如 `collection.source_type`、`collection.console_url`、`collection.request_evidence`、`collection.collected_regions`、`collection.page_size/page_number` 或等价字段。
   - 若保存了原始网络请求或响应，应把证据文件路径放在本地执行反馈中；JSON 内可记录文件名、请求类型、接口名和采集时间，避免把敏感请求头、Cookie、Token 写入报告数据。

6. 结果交付。
   - 返回已拉取服务清单、输出文件列表、覆盖情况摘要、失败项与原因。
   - 失败处理遵循 `failure_policy`（例如 `partial_success` 或 `fail_fast`）。

7. 一致性复核。
   - 同一次执行内，所有服务使用同一 `time_window.start/end/timezone`，快照类服务使用同一 `snapshot_date`。
   - 与上一周期对齐时，服务集合、地域集合、资源发现范围、分页范围和关键指标字段应保持一致。
   - 同一资源的唯一标识以云产品实例 ID 为准，名称只作为展示字段；不能用名称去重后丢失同名资源。
   - 结果文件生成前后若资源数量突变，应回到控制台核对是否因为地域、分页、过滤条件、搜索条件或权限变化导致。
   - 若无法达到一致口径，应停止声称“完整完成”，并返回 `incomplete`、缺失范围和下一步补抓动作。

## 5.1 真实性与一致性硬性规则

- 必须真实：数据来自当前登录阿里云控制台页面、控制台触发的网络响应或可见页面文本；不能从记忆、旧报告、旧 JSON、模板或主观经验生成本周云资源指标。
- 必须可追溯：每个服务输出都要能说明“从哪个控制台页面或哪个网络请求拿到”，并记录采集时间、地域、实例范围和请求/页面口径。
- 必须口径一致：同一周报周期内，各服务使用同一统计窗口；跨周复用时，应保持与上一周相同的服务、地域、分页和关键字段口径。
- 必须全量：ECS、SLB、EIP 等跨地域资源要覆盖全部目标地域和全部分页；RDS、Redis、MongoDB 等实例型资源要覆盖目标地域内所有可见实例。
- 必须区分状态：`ok` 表示真实拿到数据；`no_data` 表示真实请求无样本；`unavailable` 表示页面/API 不支持或权限不可用；`incomplete` 表示本轮还没拉完整。
- 必须拒绝污染：发现 `placeholder`、示例值、上一周期日期、报告正文复制值、手工估算值，应视为校验失败。
- 必须反馈缺口：任何服务、地域、实例、分页或关键指标未完成，都要在执行反馈和 JSON 的状态字段中明确列出，不能只给出“已拉取”。

建议每个结果文件补充以下元数据；模板没有字段时也应按相近结构写入：

```json
{
  "collection_status": "complete|partial|incomplete|failed",
  "collection": {
    "source_type": ["console_network_response"],
    "console_url": "https://*.console.aliyun.com/...",
    "collected_at": "YYYY-MM-DDTHH:MM:SS+08:00",
    "collected_regions": ["cn-shenzhen"],
    "request_evidence": [
      {
        "service": "ecs",
        "api_or_page": "DescribeInstances",
        "method": "browser_network",
        "captured_at": "YYYY-MM-DDTHH:MM:SS+08:00",
        "evidence_file": "ecs-list-cn-shenzhen.response.network-response"
      }
    ],
    "filters": {
      "time_window": "invocation.time_window",
      "region_scope": "invocation.region_scope",
      "page_size": 100,
      "sort": "stable_or_console_default"
    }
  },
  "consistency_check": {
    "mode": "strict",
    "scope_matches_invocation": true,
    "same_scope_as_previous_period": true,
    "missing_services": [],
    "missing_regions": [],
    "missing_instances": [],
    "missing_metrics": [],
    "notes": []
  }
}
```

### 结果判定参考

- `services` 中每个服务都至少有一个对应输出文件。
- 每个输出文件都可被 JSON 解析。
- 若 `metric_scope=all`，输出中包含 `metric_coverage` 并标注可用/不可用指标。
- 若部分服务失败，结果中宜包含失败服务列表与原因，而不是静默跳过。
- 对 `ecs`、`rds`、`redis`、`mongodb`、`slb`、`cdn`、`eip` 这类将直接进入周报附录的资源型服务，若本周期只拿到资源清单但关键展示指标仍大面积缺失，不应判定为“成功完成”，而应继续补抓相关监控请求或在结果中明确标注为未完成。
- 若输出文件缺少来源证据、存在模板占位符、统计窗口不一致、地域口径不一致、分页未完成或资源数量与控制台不一致，不应判定为“成功完成”。

## 6. 数据准备场景约束

- 在统一统计窗口场景中，通常会显式传入一致的 `time_window`，例如：
  - `time_window.start = <week_start> 00:00:00`
  - `time_window.end = <week_end> 23:59:59`
  - `time_window.timezone = Asia/Shanghai`
- `k8s` 与 `certificates` 结果更适合作为结构化数据产物落盘，供后续流程按需消费。
- 周报数据准备场景中，建议先读取上一周同服务输出文件，建立本次采集清单：
  - 服务集合：上一周进入周报的服务本周都要采集。
  - 地域集合：上一周出现的地域本周都要检查，同时按调用方要求补查新增可见地域。
  - 资源集合：上一周存在的实例 ID、SLB ID、EIP IP、证书 ID 等本周应核对是否仍存在；消失时记录状态变化来源。
  - 指标集合：上一周已能展示的关键指标，本周应保持同名字段输出。
  - 输出集合：上一周有对应 JSON 的服务，本周应生成同类文件，除非控制台证实资源已删除或权限变化。
- 周报调用侧要求“先深圳再其他地域”时，执行顺序可以先访问深圳，但最终完成判定必须以所有目标地域完成为准。

## 7. 建议核对项

- `time_window` 来自调用参数，而不是页面默认值。
- `region_scope` 来自调用参数，而不是 skill 默认值或页面默认地域。
- 输出目录来自调用参数 `output.root_dir`，而不是 skill 内的固定路径。
- 每个结果都能追溯到本次浏览器控制台请求或页面证据，而不是旧文件或人工录入。
- 同一执行批次内，所有周期型服务的 `time_window` 完全一致。
- 本周期服务/地域/实例/关键指标口径与上一周期对齐；新增或减少都有控制台证据。
- 分页已拉到底，列表过滤条件已清空或与上一周期一致。
- `services` 包含 `ecs` 时，更适合按账号可见范围进行全量拉取（跨地域、跨分页、全实例），以保持与调用目标一致。
- `services` 包含 `ecs` 时，完整结果不仅包括全量实例清单，还应尽量补齐 `CPUUtilization`、`memory_usedutilization`、`diskusage_utilization`、`concurrentConnections` 等周报展示需要的关键监控指标；若首轮只拿到实例列表，应继续从 ECS 控制台概览页或实例页请求中补抓 `DescribeMetricLast` 等监控接口。
- `services` 包含 `slb` 或 `eip` 时，更适合按账号可见范围做跨地域盘点，避免只覆盖主地域而漏掉青岛等其他地域资源。
- `metric_scope=all` 时，结果中已尽量扩大指标范围并记录不可用指标。
- 指标覆盖档位与调用方给定的 `metric_profile` 保持一致（如有覆盖规则）。
- 聚合顺序与调用方给定的 `aggregation_policy` 保持一致。
- 失败处理方式与调用方给定的 `failure_policy` 保持一致。
- 地域型资源已适度覆盖首选地域之外的可见地域。
- 输出路径与服务路由一致，JSON 可以通过结构校验。
- K8S 与证书数据已落盘并可作为后续处理输入。
- 每个服务执行结束后，如已不再使用，可关闭对应标签页，仅保留必要页面。
- 输出 JSON 中不存在 `placeholder`、示例值、上一周期日期冒充本期数据、无来源数字。
- 执行反馈中列出已完成服务、未完成服务、未完成原因、证据来源和需要补抓的下一步。

## 8. 约束与边界

- 不建议在 skill 内部推断或硬编码统计周期。
- 不建议在 skill 内部推断或硬编码地域范围。
- 不建议在 skill 内部固定输出目录。
- 不允许使用旧数据、模板值、经验判断或报告正文反推本周阿里云指标。
- 不允许在用户要求网页请求采集时改用 OpenAPI/SDK。
- 不允许只因为文件已生成就判定成功；成功必须同时满足真实来源、范围完整、口径一致和 JSON 可解析。
- 单实例样本通常不宜直接等同于全量视图。
- 在 `services=["ecs"]` 场景下，若仅拿到验证样本，更适合作为部分结果而非完整成功结果。
- 在任一资源型服务场景下，若仅拿到资产列表或概览计数，而模板需要的关键利用率/容量指标尚未回填，更适合作为部分结果而非完整成功结果。
- 输出结果宜尽量贴近模板结构，而不是临时文本摘要。

## 9. 服务级覆盖矩阵（实测口径）

以下为当前控制台会话下可稳定拉取的指标范围（`metric_scope=all`）：

- `ecs`
  - 核心：CPU、内存、磁盘、网络（按实例聚合与汇总）。
  - 扩展：实例维度热点、可用区/规格补充信息。
- `rds`
  - 核心：连接数、CPU、IOPS、延迟、存储空间。
  - 扩展：实例状态、引擎版本、规格与区域信息。
- `redis`
  - 核心：QPS、连接数、CPU、内存使用、水位变化。
  - 扩展：实例状态、规格、节点信息（可见时）。
- `mongodb`
  - 核心：连接、CPU、内存、慢查询与吞吐相关指标。
  - 扩展：分片/副本集拓扑字段（可见时）。
- `k8s`
  - 核心：集群状态、任务/事件、发布统计（可访问时）。
  - 扩展：命名空间与 Deployment 明细（受 RBAC 影响）。
- `slb`
  - 核心：SLB/ALB/NLB 总量、空闲实例、配额。
  - 扩展：跨地域分布与实例类型细分；若发现多个地域，应显式保留地域分布结果。
- `cdn`
  - 核心：流量、带宽、HTTP 状态码分布、域名总览。
  - 扩展：套餐、证书/CNAME 配置状态、源站状态码分层。
- `eip`
  - 核心：总量、已绑定/未绑定、带宽总额、绑定类型分布。
  - 扩展：多地域明细（不只单地域）；如存在跨地域 EIP，应保持地域汇总与实例清单一致。
- `sms`
  - 核心：总发送、成功/失败、日趋势。
  - 扩展：资质状态、账号开通状态、套餐字段（可见时）。
- `voice`
  - 核心：账单金额、计费项、用量。
  - 扩展：商品目录与费用项目录；按周精确序列通常不可直接得到。
- `email`
  - 核心：总发送、成功/失败、无效地址、日趋势。
  - 扩展：发送详情样本、退订/垃圾举报名单、账号配额、验证额度。
  - 权限敏感：`ConfigSet`、`DedicatedIpPool` 常见 `NoPermission`。
- `certificates`
  - 核心：订单总量、过期数量、套餐使用量。
  - 扩展：逐证书剩余天数与部署明细（页面/API可见时）。

### 9.1 优先接口清单（按服务）

为保证 `metric_scope=all` 下稳定复现，建议优先观察以下控制台接口（接口名可随前端版本变化，但语义应一致）：

- `sms`：`QuerySmsStatisticsNew`、`QuerySmsBaseScreenNew`、`QueryPackageSummary`、`QuerySmsQualificationRecord`
- `voice`：`GetUserBill`、`ListCustomBillTab`、`GetSearchTreeData`、`GetBillViewDescription`
- `email`：`listStatistics`、`listStatisticsDetail`、`listBlockSending`、`descAccount`、`getValidationQuota`、`listMailAddress`
- `certificates`：`getCertificateOrderCount`、`getCertificatePackageCount`、`listCertificateOrder`
- `eip`：`DescribeResourceAggregations`、`DescribeEipAddresses`
- `slb`：`DescribeLoadBalancerSummary`、`DescribeIdleInstances`、`DescribeSlbQuotas`、`GetAlbGlobalSummary`、`GetNlbGlobalSummary`
- `cdn`：`DescribeDomainUsageData`、`DescribeDomainHttpCodeDataByLayer`、`DescribeDomainSrcHttpCodeData`、`DescribeCdnUserResourcePackage`
- `k8s`：`DescribeClusters`、`DescribeTasks`、`DescribeEvents`、`DescribeClusterNamespaces`、`Deployments 列表接口`

## 10. 权限降级与兜底规范

- 当接口返回 `NoPermission/403/forbidden`：
  - 可以继续保留该服务的部分输出。
  - 可在 `metric_coverage.extended_metrics_unavailable` 标注缺失项。
  - 可在 `permission_findings` 或 `notes` 记录接口名、错误码、RequestId。
- 当页面有数据但无 API 明细：
  - 可先保留“快照级”聚合结果。
  - 可在 `report_compatibility` 标注其与目标统计口径的一致程度。
- 当样本为空：
  - 更适合使用 `no_data` 或空数组，而不是伪造 0 值序列。

## 11. 建议执行顺序（全量覆盖）

当目标是“尽可能全面覆盖”且包含通信扩展视角时，建议顺序：

`ecs -> rds -> redis -> mongodb -> k8s -> slb -> cdn -> eip -> certificates -> sms -> voice -> email`

说明：
- 先拉基础资源稳定面（计算/数据库/网络），再拉通信与费用面。
- `email` 放在后段，便于在同一次会话中补采发送详情、退订、举报等扩展数据。
