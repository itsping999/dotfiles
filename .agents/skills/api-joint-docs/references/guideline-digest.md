# Agent API 规范摘要

本文件供 Agent 生成联调接口文档时参考。项目现有约定优先。

## 参考规范

- Google AIP：借鉴资源化设计和一致性规则。
- Microsoft REST API Guidelines：借鉴兼容性、错误处理和版本演进。
- Zalando RESTful API Guidelines：借鉴 API first、URL、数据格式和错误处理。
- OpenAPI Specification：借鉴参数位置、request body、responses、schema、examples 的结构。

## 简化规则

- API 契约应先于联调歧义。
- 参数必须标明位置：`path`、`query`、`header`、`cookie`、`body`。
- 每个参数至少写类型、必填、约束、示例、说明。
- 路由优先表达资源，不优先表达动作。
- 更新接口必须说明兼容性影响。
- 错误响应至少说明状态码、业务码、触发条件和前端处理。
- 示例必须和参数表一致。
- 冲突不静默合并，统一放到待确认。
- Agent 输出时区分事实、推断和待确认。
