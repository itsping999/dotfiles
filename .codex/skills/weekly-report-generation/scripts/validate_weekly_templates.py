#!/usr/bin/env python3
"""Validate generated weekly report template consistency (strict V2)."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

WEEKLY_TEMPLATE_MARKER = "<!-- TEMPLATE: WEEKLY_REPORT_V2 -->"

WEEKLY_HEADINGS = [
    "## 一、本周结论与业务影响",
    "### 1.1 关键结论",
    "### 1.2 核心可用率（本周 / 本月 / 本年度）",
    "### 1.3 业务影响概览",
    "## 二、可靠性与故障治理",
    "### 2.1 本周故障明细",
    "### 2.2 可靠性效率指标",
    "#### 风险与关注项",
    "#### 待决策事项",
    "## 三、交付质量与变更风险",
    "## 四、性能与容量表现",
    "### 4.1 接口与流量",
    "### 4.2 下周重点",
    "## 五、附录（按组件资源明细）",
]

SECTION_TABLES: dict[str, int | list[int]] = {
    "### 1.2 核心可用率": 4,
    "### 1.3 业务影响概览": 3,
    "### 2.2 可靠性效率指标": 3,
    "#### 待决策事项": 5,
    "## 三、交付质量与变更风险": 3,
    "### 4.1 接口与流量": 3,
}

APPENDIX_SECTIONS = {
    "5.1 ECS":            {"table_cols": 14},
    "5.2 RDS MySQL":      {"table_cols": 8},
    "5.3 Redis":          {"table_cols": 7},
    "5.4 MongoDB":        {"table_cols": 8},
    "5.5 SLB":            {"table_cols": 4},
    "5.6 CDN":            {"table_cols": [4, 8]},
    "5.7 EIP":            {"table_cols": [5, 5]},
    "5.8 共享流量包":      {"table_cols": 6},
}


def is_separator(row: str) -> bool:
    return bool(re.match(r"^\|[\s\-:|]+\|$", row.strip()))


def count_cols(row: str) -> int:
    return len([p for p in row.strip().strip("|").split("|") if p.strip()])


def extract_table_headers(rows: list[str]) -> list[tuple[int, int, int]]:
    """Find all tables by locating separator rows.
    Returns list of (sep_index, header_index, col_count) tuples.
    Each table's header is the row immediately before its separator.
    """
    tables = []
    for i, row in enumerate(rows):
        if is_separator(row):
            header_idx = i - 1
            if header_idx >= 0:
                cols = count_cols(rows[header_idx])
                tables.append((i, header_idx, cols))
    return tables


def get_section_text(text: str, heading: str, next_heading: str | None) -> str:
    s = text.find(heading)
    if s == -1:
        return ""
    e = len(text)
    if next_heading:
        p = text.find(next_heading, s + len(heading))
        if p != -1:
            e = p
    return text[s:e]


def get_table_rows(text: str) -> list[str]:
    return [l.strip() for l in text.split("\n") if l.strip().startswith("|")]


def missing_or_out_of_order(text: str, headings: list[str]) -> list[str]:
    missing: list[str] = []
    cursor = -1
    for h in headings:
        idx = text.find(h, cursor + 1)
        if idx == -1:
            missing.append(h)
            continue
        cursor = idx
    return missing


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")

    # 1. Template marker
    if WEEKLY_TEMPLATE_MARKER not in text:
        errors.append(f"缺少模板标识: {WEEKLY_TEMPLATE_MARKER}")

    # 2. Heading order
    missing = missing_or_out_of_order(text, WEEKLY_HEADINGS)
    if missing:
        errors.append("缺少或顺序不符的章节: " + "；".join(missing))

    # 3. Title format
    if not re.search(r"^# 【\d{4}-\d{2}-\d{2} 至 \d{4}-\d{2}-\d{2}】云平台运行情况报告", text, re.MULTILINE):
        errors.append("标题格式不符合: # 【{week_start} 至 {week_end}】云平台运行情况报告")

    # 4. No 5.9 section
    if re.search(r"5\.9.*采集完整性|采集完整性.*5\.9", text):
        errors.append("不应包含 5.9 采集完整性章节")

    # 5. No data paths in body
    body_start = text.find("## 一、")
    if body_start != -1:
        body = text[body_start:]
        if re.search(r"`data/[^`]+`", body):
            errors.append("正文中不应出现 data/ 源文件路径")

    # 6. Version note
    if "当前报告版本不为最终版" not in text:
        errors.append("缺少版本说明引用块")

    # 7. Main section table columns
    headings_list = list(SECTION_TABLES.keys())
    for i, heading in enumerate(headings_list):
        next_h = headings_list[i + 1] if i + 1 < len(headings_list) else None
        sec_text = get_section_text(text, heading, next_h)
        rows = get_table_rows(sec_text)
        tables = extract_table_headers(rows)
        expected = SECTION_TABLES[heading]
        if tables:
            _, _, actual = tables[0]
            if actual != expected:
                errors.append(f"{heading} 表格列数应为 {expected}，实际为 {actual}")

    # 8. Appendix sections
    app_start = text.find("## 五、附录")
    if app_start != -1:
        app_text = text[app_start:]
        for sec_name, cfg in APPENDIX_SECTIONS.items():
            heading = f"### {sec_name}"
            if heading not in app_text:
                errors.append(f"附录缺少子章节: {heading}")
                continue

            sec_pos = app_text.find(heading)
            next_m = re.search(r"### 5\.\d+", app_text[sec_pos + len(heading):])
            sec_end = sec_pos + len(heading) + next_m.start() if next_m else len(app_text)
            sec_text = app_text[sec_pos:sec_end]

            rows = get_table_rows(sec_text)
            tables = extract_table_headers(rows)
            expected = cfg["table_cols"]

            if isinstance(expected, list):
                # Multi-table: check each table's header col count
                for ti, exp in enumerate(expected):
                    if ti < len(tables):
                        _, _, actual = tables[ti]
                        if actual != exp:
                            errors.append(f"{heading} 表格 {ti+1} 列数应为 {exp}，实际为 {actual}")
                    else:
                        errors.append(f"{heading} 缺少表格 {ti+1}（期望 {exp} 列）")
            else:
                if tables:
                    _, _, actual = tables[0]
                    if actual != expected:
                        errors.append(f"{heading} 表格列数应为 {expected}，实际为 {actual}")

            # Check 重点观察 / 建议与改进措施
            if "#### 重点观察" not in sec_text:
                errors.append(f"{heading} 缺少 #### 重点观察")
            if "#### 建议与改进措施" not in sec_text:
                errors.append(f"{heading} 缺少 #### 建议与改进措施")

    return errors


def collect_weekly_reports(reports_root: Path) -> list[Path]:
    weekly_root = reports_root / "weekly"
    if not weekly_root.exists():
        return []
    return sorted(p for p in weekly_root.rglob("*.md") if p.name != "index.md")


def main() -> None:
    parser = argparse.ArgumentParser(description="校验已生成周报的模板一致性")
    parser.add_argument("--reports-dir", default="reports")
    parser.add_argument("--scope", choices=["weekly"], default="weekly")
    args = parser.parse_args()

    files = collect_weekly_reports(Path(args.reports_dir))
    print(f"周报待校验: {len(files)}")

    failed = False
    for path in files:
        errors = validate_file(path)
        if errors:
            failed = True
            print(f"[FAIL] {path}")
            for err in errors:
                print(f"  - {err}")

    if failed:
        raise SystemExit(1)
    print("周报模板一致性校验通过")


if __name__ == "__main__":
    main()
