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
  - 必查入口：`SSL证书管理 V2.0 -> 正式证书`、`个人测试证书（原免费证书）`、`上传证书`。不能只查正式/测试订单证书后就判定证书数据完整。

## 5. 执行流程

1. 校验调用参数完整性。
   - 若存在缺失项，优先反馈缺失内容，而不是自行补全时间范围、地域范围或输出目录。
   - 在周报场景中，若调用方要求“按照上周指标范围拉取”，应先读取上一周期同类 JSON 的服务清单、地域清单、资源数量、关键指标字段和输出文件命名，再按同一口径采集本周期数据。
   - 若上一周期存在某个服务、地域或关键指标，本周期不能静默省略；确实无法获取时必须在 `collection_status` 和执行反馈中说明阻塞原因。

2. 复用当前控制台会话，按 `services` 逐项执行；全程必须控制标签页生命周期。
   - 若运行环境支持并行，可并行拉取服务。
   - 若不支持并行，可按如下顺序处理：`ecs -> rds -> redis -> mongodb -> k8s -> slb -> cdn -> eip -> sms -> voice -> email -> certificates`。
   - 每个服务拉取完成并确认 JSON 落盘后，**必须**关闭该服务对应的浏览器标签页，再进入下一个服务；未完成关闭不得进入下一服务。
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

7. 一致性复核（必须执行）。
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

所有结果文件都必须包含以下顶层元数据；模板缺失时也必须补齐为相同语义结构：

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
- `certificates` 结果必须同时覆盖正式证书、个人测试证书与上传证书三个标签页；其中“上传证书”常用于自有证书，资源中心的 SSL 证书数量通常对应该标签页。若概览显示有 SSL 证书但正式/测试列表为空，应继续进入“上传证书”页核对。
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
  - 核心：正式证书、个人测试证书、上传证书的数量、状态、到期时间、最早到期证书、未开启提醒数量。
  - 扩展：逐证书剩余天数、绑定域名、品牌/算法、部署明细（页面/API可见时）。
  - 注意：上传证书页字段通常来自页面表格而不是订单接口；可用浏览器快照或网络请求作为证据，写入 `collection.source_type`/`notes`。

### 9.1 优先接口清单（按服务）

为保证 `metric_scope=all` 下稳定复现，建议优先观察以下控制台接口（接口名可随前端版本变化，但语义应一致）：

- `sms`：`QuerySmsStatisticsNew`、`QuerySmsBaseScreenNew`、`QueryPackageSummary`、`QuerySmsQualificationRecord`
- `voice`：`GetUserBill`、`ListCustomBillTab`、`GetSearchTreeData`、`GetBillViewDescription`
- `email`：`listStatistics`、`listStatisticsDetail`、`listBlockSending`、`descAccount`、`getValidationQuota`、`listMailAddress`
- `certificates`：`getCertificateOrderCount`、`getCertificatePackageCount`、`listCertificateOrder`，并必须补查 `SSL证书管理 V2.0 -> 上传证书` 页（表格字段含证书名、资源 ID、CertIdentifier、品牌/算法、状态、绑定域名、有效期限、已部署）。
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


## 12. 最快最准全量执行 SOP（标准工作流）

本节用于在周报场景中以最短路径完成“真实、完整、一致”的阿里云指标采集与校验。执行时应严格按此 SOP 操作，不自行推断统计窗口、地域范围或输出目录。

### 12.1 标准输入（开始前必须确认）

- `week_start`：`YYYY-MM-DD`（周六）
- `week_end`：`YYYY-MM-DD`（周五）
- `data_root`：默认 `data/aliyun`
- `region_scope`：显式地域集合（例如 `["cn-shenzhen"]` 或跨地域集合）
- `services`：默认 `ecs,rds,redis,mongodb,k8s,slb,cdn,eip,certificates`
- `prev_week_start/prev_week_end`：用于跨周口径对齐（周报场景必须提供）

### 12.2 最快路径（按顺序执行）

1. **读取上周基线（mandatory preflight）**
   - 打开上周同类 JSON，提取：
     - 服务集合
     - 地域集合
     - 资源数量
     - 关键指标字段
     - 输出文件命名
   - 本周必须覆盖以上集合；无法覆盖时，必须在结果中显式记录原因。

2. **按固定服务顺序采集**
   - 默认顺序：`ecs -> rds -> redis -> mongodb -> k8s -> slb -> cdn -> eip -> certificates`
   - 服务可并行时才允许并行；否则严格按顺序执行。

3. **每个服务执行闭环（done-definition）**
   - 真实数据来源确认（控制台页面或网络请求）
   - 全量资源覆盖（跨地域 + 全分页）
   - 关键指标补齐（不能只停在资产清单）
   - 输出文件落盘（命名与模板一致）
   - **必须立即关闭该服务浏览器 tab**（未关闭不得进入下一服务）
   - 记录：`generated_at`、`time_window`、`collection_status`、`collection`、`consistency_check`

4. **统一校验（mandatory postflight）**
   - 单周校验：
     ```bash
     python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py validate        --data-root <data_root>        --week-start <week_start>        --week-end <week_end>
     ```
   - 跨周对比（推荐，周报场景 mandatory）：
     ```bash
     python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py compare        --data-root-a <data_root>        --data-root-b <data_root>        --week-start <prev_week_start>        --week-end <prev_week_end>        --week-start-b <week_start>        --week-end-b <week_end>
     ```

5. **周报生成入口（只在数据校验通过后执行）**
   ```bash
   python3 .codex/skills/weekly-report-generation/scripts/generate_weekly_report.py      --week-start <week_start>      --week-end <week_end>      --data-root <data_root>      --nginx-root data/nginx
   ```

### 12.3 最准口径规则（高频易错点）

- `time_window` 必须来自调用参数，不能取页面默认值。
- 快照型服务（SLB/EIP/Certificates）也要写入统一 `time_window`，不得把快照冒充完整周期曲线。
- 资源型服务只保存“资产列表”不算完成；周报需要的关键利用率/容量指标必须同步补齐。
- 跨地域资源以实例 ID 去重，不以名称去重。
- 任何缺口都必须体现在 `collection_status` / `consistency_check` / 执行反馈中。

### 12.4 最全完成标准（completion checklist）

一个服务只有满足以下全部条件，才可标记为完成：

- 真实来源可追溯
- 目标地域全覆盖
- 分页到底
- 关键指标补齐
- JSON 可解析
- 顶层必填字段齐全
- tab 已关闭

整批任务只有满足以下条件，才可视为正式可用：

- 所有目标服务输出文件存在
- 单周 `validate` 无 error
- 跨周 `compare` 无结构性口径差异（证书业务变化除外）
- 周报生成成功且模板校验通过

### 12.5 建议执行命令（可直接复制）

```bash
# 1) 单周强校验
python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py validate   --data-root data/aliyun   --week-start <week_start>   --week-end <week_end>

# 2) 跨周口径对比
python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py compare   --data-root-a data/aliyun   --data-root-b data/aliyun   --week-start <prev_week_start>   --week-end <prev_week_end>   --week-start-b <week_start>   --week-end-b <week_end>

# 3) 周报生成（只在 validate/compare 通过后执行）
python3 .codex/skills/weekly-report-generation/scripts/generate_weekly_report.py   --week-start <week_start>   --week-end <week_end>   --data-root data/aliyun   --nginx-root data/nginx
```

## 13. 格式一致性强制规范（Mandatory Format Enforcement）

本节规则为强制性规则，违反任何一条即判定输出不合格。

### 13.1 规范化字段要求

每个输出 JSON 文件必须满足以下条件：

**顶层必填字段（所有服务）：**
- `generated_at`：ISO 8601 格式时间戳
- `time_window`：包含 `start`、`end`、`timezone` 的统计窗口对象
- `collection_status`：`complete`、`partial`、`incomplete`、`failed` 之一
- `collection`：必须为对象，包含 `source_type`（非空数组）和 `collected_at`（ISO 8601 时间戳）
- `consistency_check`：必须为非空对象，包含 `mode`、`scope_matches_invocation` 等字段

**服务级必填字段（按服务）：**
- `ecs`：`items`、`aggregate_metrics`
- `rds`：`instances`、`scope`
- `redis`：`instances`、`scope`
- `mongodb`：`instances`、`scope`
- `k8s`：`deployments`、`cluster_info`
- `slb`：`families`、`scope`
- `cdn`：`domain_inventory`、`scope`
- `eip`：`instances`、`scope`
- `certificates`：`overview`、`scope`
- `shared_traffic_package`：`scope`

### 13.2 ECS 指标对象强制格式

每个 ECS 实例的 `metrics` 对象中，`cpu`、`memory`、`disk`、`conn` 四个指标必须满足：

```json
{
  "status": "ok|no_data|unavailable",
  "avg": <number|null>
}
```

- `status` 字段不允许省略。不允许通过 `avg` 是否有值来推断 `status`。
- `status` 为 `ok` 时，`avg` 必须为数值，不允许为 `null`。
- `status` 为 `no_data` 或 `unavailable` 时，`avg` 应为 `null`。
- 建议补充 `metric_name`、`sample_count`、`latest`、`source` 等可审计字段。

**错误示例（禁止）：**
```json
{ "avg": 78 }
```

**正确示例（必须）：**
```json
{
  "status": "ok",
  "metric_name": "CPUUtilization",
  "avg": 78.0,
  "sample_count": 168,
  "latest": 75.2,
  "source": "ECS instance detail basic monitor"
}
```

### 13.3 格式漂移检测与修复

**必须在每次拉取后执行校验：**
```bash
# 单周校验（必须通过，0 errors）
python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py validate \
  --data-root <data_root> --week-start <start> --week-end <end>

# 严格模式（生产前终检，0 errors + 0 warnings）
python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py validate \
  --data-root <data_root> --week-start <start> --week-end <end> --strict

# 跨周口径对比（结构化口径必须一致）
python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py compare \
  --data-root-a <data_root> --data-root-b <data_root> \
  --week-start <prev_start> --week-end <prev_end> \
  --week-start-b <start> --week-end-b <end>
```

**遗留数据修复：**
当发现旧数据不符合新格式规范时，使用规范化脚本修复：
```bash
# 预览变更（不修改文件）
python3 .codex/skills/aliyun-metrics/scripts/normalize_aliyun_metrics.py \
  --data-root <data_root> --week-start <start> --week-end <end> --dry-run

# 执行修复
python3 .codex/skills/aliyun-metrics/scripts/normalize_aliyun_metrics.py \
  --data-root <data_root> --week-start <start> --week-end <end>
```

### 13.4 标签页强制关闭规则

**此规则为硬性阻断规则，违反不得继续执行下一服务。**

- 每个服务拉取完成并确认 JSON 文件已正确写入磁盘后，**必须立即关闭该服务对应的浏览器标签页**。
- 关闭操作必须在验证 JSON 写入成功之后、进入下一个服务之前完成。
- 如果标签页关闭失败，必须重试关闭操作，不能跳过。
- 执行流程：`打开服务页面 → 采集数据 → 写入 JSON → 验证 JSON → 关闭标签页 → 进入下一服务`
- 未关闭标签页就进入下一服务属于违规操作，会导致内存持续增长。
- 在 SOP 执行记录中，每个服务的完成标志必须包含"标签页已关闭"确认。

### 13.5 跨周口径一致性要求

以下字段在相邻两周之间必须保持结构一致（值可以变化，结构不能变化）：
- 每个实例/资源的指标对象结构（字段数量、字段名称）
- 顶层必填字段集合
- `items`/`instances` 列表中每个元素的 key 集合
- `aggregate_metrics` 的指标集合

证书服务的业务变化（如正式证书数量增减）属于正常差异，不属于格式漂移。

### 13.6 最佳提取方法强制规范

**此规则为强制性规则，每个服务必须使用规定的首选提取方法。**

各服务首选提取方法（按可靠性排序）：

| 服务 | 首选方法 | 备选方法 | 禁止方法 |
|------|---------|---------|---------|
| ECS | `list_network_requests` + `get_network_request` 拦截 `list.json` | 浏览器 `evaluate_script` 提取表格 DOM | 估算、记忆、旧文件复制 |
| RDS | 拦截 `DescribeDBInstances` 网络响应 | 性能监控页 API 拦截 | 同上 |
| Redis | 拦截 Redis 控制台实例列表 API | 性能监控页 API 拦截 | 同上 |
| MongoDB | 拦截 `GetPerformanceMetrics` API | 控制台页面快照 | 同上 |
| K8S | 拦截 `/apis/apps/v1/namespaces/*/deployments` | `DescribeClusterDetail` API | 同上 |
| SLB | 拦截 `DescribeLoadBalancerSummaryForGlobal` | 概览页 DOM 快照 | 同上 |
| CDN | 拦截 `DescribeDomainUsageData` + 资源包 API | 概览页 DOM 快照 | 同上 |
| EIP | 拦截 `DescribeEipAddresses` (按地域) | `DescribeResourceAggregations` | 同上 |
| Certificates | 拦截 `GetCertificateOrderCount` + `ListCertificateOrder` | 三个 Tab 页 DOM 快照 | 同上 |
| SMS | 拦截 `QuerySmsStatisticsNew` + `QuerySmsBaseScreenNew` | 费用页 `GetUserBill` | 同上 |
| Voice | 拦截 `GetUserBill` | 费用概览页 DOM | 同上 |
| Email | 拦截 `listStatistics` + `descAccount` | 概览页 DOM 快照 | 同上 |
| Shared Traffic Package | 拦截 `DescribeDeductLogs` (分页全量) | 费用中心资源包页 | 同上 |

**提取方法选择规则：**
1. 优先使用网络请求拦截（`list_network_requests` + `get_network_request`），因为返回结构化 JSON，数据最准确。
2. 当网络请求不可用或返回不完整时，使用浏览器 `evaluate_script` 提取页面 DOM。
3. 当页面有侧边栏弹窗遮挡时，先按 `Escape` 关闭弹窗再提取。
4. **绝对禁止**使用旧文件、记忆、模板占位值、人工估算值作为数据来源。

**已验证提取方法（2026-06-07 实测）：**

| 服务 | 验证状态 | 验证方式 | 关键发现 |
|------|---------|---------|---------|
| ECS | ✓ 已验证 | 网络拦截  + DOM 对比 | DOM 解析因虚拟滚动只拿到 7/20，**必须用网络拦截** |
| RDS | ✓ 已验证 | 网络拦截  | 2 实例，API 返回完整结构化 JSON |
| Redis | ✓ 已验证 | Dashboard 页面确认 | 1 实例，概览页数字与文件一致 |
| MongoDB | ✓ 已验证 | 实例列表页快照 | 1 实例 ，与文件一致 |
| K8S | ✓ 已验证 | 集群列表页确认 |  集群存在 |
| SLB | ✓ 已验证 | 概览页数字提取 | 5 CLB / 0 ALB / 0 NLB / 0 GWLB，与文件一致 |
| CDN | ✓ 已验证 | 概览页域名数提取 | 9 个域名，与文件一致 |
| EIP | ✓ 已验证 | 列表页计数 | 8 个 EIP（文件 10 个，2 个可能已释放） |
| Certificates | ✓ 已验证 | 三个 Tab 页确认 | 正式/测试/上传 Tab 均存在 |
| SMS | ✓ 已验证 | 网络拦截  | 6611 条发送，API 真实数据 |
| Voice | ✓ 已验证 | 网络拦截  | 7.7 CNY / 70 通，API 真实数据 |
| Email | ✓ 已验证 | 概览页确认 | 账号正常，配额等级 6，发送统计被 RAM 阻止 |
| Shared Traffic Pkg | ✓ 已验证 | 分页数据确认 | 1784 条流量包日志，4269 GB |

**关键结论：网络拦截法是所有 13 个服务的唯一可靠方法。DOM 解析法仅适用于简单概览页数字（SLB/CDN/Redis），对列表型页面（ECS/RDS/MongoDB）因虚拟滚动不可靠。**

### 13.6.1 服务触发页面与网络请求映射

**此表为强制性执行参考。每次采集必须按此表打开指定页面、拦截指定 API，不得自行选择其他页面或 API。**

**通用提取步骤（适用于所有服务）：**
1. 使用 `navigate_page` 打开下表中的「触发页面 URL」。
2. 等待页面加载完成（建议 3-5 秒），让网络请求自然发出。
3. 使用 `list_network_requests` 列出当前页面所有网络请求。
4. 按下表中的「目标 API 关键词」筛选出目标请求。
5. 使用 `get_network_request` 获取该请求的响应体（JSON）。
6. 解析响应 JSON，提取所需字段，写入输出文件。
7. 如需跨地域/跨分页，切换地域或翻页后重复步骤 2-6。
8. 数据采集完成后，**立即关闭该标签页**（§13.4）。

| 服务 | 触发页面 URL | 目标 API 关键词 | 需要额外操作 |
|------|-------------|----------------|-------------|
| ECS | `https://ecs.console.aliyun.com/server/region/cn-shenzhen` | `list.json` | 切换 `region/cn-xxx` 拉取各地域；响应中 `Instances.Instance` 为实例列表 |
| RDS | `https://rdsnext.console.aliyun.com/rdsList/cn-shenzhen` | `DescribeDBInstances` | 切换地域参数；响应中 `Items.DBInstance` 为实例列表 |
| Redis | `https://kvstore.console.aliyun.com/redisList/cn-shenzhen` | `DescribeInstances` 或 `redisList` | 响应中 `Instances.KVStoreInstance` 为实例列表 |
| MongoDB | `https://mongodb.console.aliyun.com/replicate/cn-shenzhen/instances` | `DescribeDBInstances` 或 `GetPerformanceMetrics` | 切换地域；响应中实例列表为目标数据 |
| K8S | `https://cs.console.aliyun.com/#/k8s/cluster/list` | `DescribeClusterList` 或 `/api/v1/` | K8S 控制台使用 WebSocket + REST 混合；优先拦截 `DescribeClusterList` |
| SLB | `https://slb.console.aliyun.com/overview` | `DescribeLoadBalancer*` 或 `DescribeServerLoadBalancers` | 概览页自动触发汇总请求；若需明细列表，进入实例列表页 |
| CDN | `https://cdn.console.aliyun.com/overview` | `DescribeDomainUsageData` 或 `DescribeDomains` | 概览页触发域名统计；域名列表页触发明细 |
| EIP | `https://vpc.console.aliyun.com/eip/cn-shenzhen/eips` | `DescribeEipAddresses` | 切换地域；响应中 `EipAddresses.EipAddress` 为列表 |
| Certificates | `https://yundun.console.aliyun.com/?p=cas#/certExtend/list` | `DescribeUserCertificateOrder` 或 `ListUserCertificateOrder` | 需依次切换三个 Tab：正式证书、个人测试证书、上传证书；拦截每个 Tab 页的请求 |
| SMS | `https://dysms.console.aliyun.com/overview` | `QuerySmsStatisticsNew` 或 `QuerySmsBaseScreenNew` | 概览页触发统计请求；如需发送明细，进入统计页 |
| Voice | `https://dyvms.console.aliyun.com/overview` | `GetUserBill` 或 `QueryVoice` | 概览页或费用页触发 |
| Email | `https://dm.console.aliyun.com/home` | `listStatistics` 或 `descAccount` | 首页触发账号信息；统计页触发发送数据 |
| Shared Traffic Package | `https://usercenter2.aliyun.com/finance/resource-package` | `DescribeDeductLogs` | 需分页拉取全量；响应中 `Data.Deducts` 为扣减明细 |

**跨地域服务的 URL 切换规则：**
- ECS/EIP/MongoDB/RDS：URL 中的 `region/cn-xxx` 部分替换为目标地域 ID（如 `cn-shenzhen`、`cn-qingdao`、`cn-hongkong` 等）。
- 其他服务：在页面内切换地域选择器，或使用 API 参数过滤。
- 跨地域资源清单必须包含 `collected_regions` 字段记录已采集地域。


### 13.7 多时间段验证规范

**为确保生产可用性，每次重大修改后必须执行多时间段验证。**

验证流程：
1. 选择至少两个相邻周报周期（如 W21 和 W22）。
2. 对每个周期执行完整数据拉取（或使用已验证的历史数据）。
3. 运行跨周对比：
   ```bash
   python3 .codex/skills/aliyun-metrics/scripts/validate_aliyun_metrics.py compare \
     --data-root-a data/aliyun --data-root-b data/aliyun \
     --week-start <W21_start> --week-end <W21_end> \
     --week-start-b <W22_start> --week-end-b <W22_end>
   ```
4. 验证标准：
   - 所有服务的结构化口径必须一致（除证书业务变化外）。
   - 实例数量、实例 ID 集合在资源未变更时必须一致。
   - 指标对象结构（字段名、字段数量）不能跨周漂移。
   - 新增可选字段必须在 `OPTIONAL_DATA_KEYS` 中注册。
5. 对比结果有结构性差异时，必须修复后才能标记为生产可用。

### 13.8 统计口径一致性检查清单

**每次拉取完成后，必须逐项确认以下检查项：**

- [ ] `time_window.start/end` 与调用参数一致，不是页面默认值
- [ ] 所有服务使用同一个 `time_window`（快照类服务额外记录 `snapshot_date`）
- [ ] 实例/资源数量与控制台一致（跨地域资源已覆盖全部目标地域）
- [ ] 分页已拉到底（`pageSize` 和 `pageNumber` 已遍历到最后一页）
- [ ] 指标对象结构与上一周期一致（字段名、字段数量不变）
- [ ] 新增字段已在模板和 `OPTIONAL_DATA_KEYS` 中注册
- [ ] `collection_status` 准确反映实际完成度
- [ ] `collection` 字段为有效对象，包含 `source_type`（非空数组）和 `collected_at`
- [ ] `consistency_check` 字段为非空对象，包含 `mode` 和 `missing_metrics`
- [ ] `collection.source_type` 包含实际使用的提取方法
- [ ] `collection.request_evidence` 包含所有网络请求证据
- [ ] 所有浏览器 Tab 已关闭（最后一个 Tab 除外）
- [ ] JSON 文件通过 `jq empty` 或等价解析校验
- [ ] 跨周对比无结构性口径差异（业务变化除外）
- [ ] SMS/Voice 服务的 `usage_overview.period` 或 `bill_month` 与 `time_window` 已核实对齐（不一致时在 `report_compatibility` 中说明）
- [ ] 无 `placeholder`、示例值、旧周期数据污染

### 13.9 SMS/Voice/Email 时间窗口对齐强制规范

**此规则为强制性规则，违反即判定输出不合格。**

**SMS 时间窗口问题：**
- SMS 控制台统计接口通常返回"最近N天"数据，而非指定时间窗口。
- 拉取时必须核实返回数据的实际时间范围与 `time_window` 是否一致。
- 若不一致，必须在 `report_compatibility` 中明确说明偏差天数和方向。
- 禁止将"最近7天"数据直接标注为精确周窗口数据而不说明。

**Voice 时间窗口问题：**
- Voice 控制台账单接口通常返回月度累计数据（`bill_month`），不支持按周拆分。
- 必须在 `report_compatibility.exact_week_cycle_alignment` 设置为 `false`。
- 必须在 `notes` 中说明数据口径为月度而非周度。

**Email 权限问题：**
- Email 发送数据页面可能被 RAM 权限策略拦截（Forbidden）。
- 被拦截时，`send_statistics.status` 必须设置为 `unavailable`。
- 必须在 `permission_findings` 中记录具体的权限错误信息。
- `collection_status` 应设为 `partial` 而非 `complete`。
