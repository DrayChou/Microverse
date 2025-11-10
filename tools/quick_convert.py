#!/usr/bin/env python3
"""
快速 YAML 到 JSON 转换脚本
简单易用，专门处理常见的配置文件转换问题
"""

import json
import yaml
import os
from pathlib import Path


def fix_yaml_content(content: str) -> str:
    """修复常见的YAML语法错误"""
    lines = content.split("\n")
    fixed_lines = []

    for i, line in enumerate(lines):
        # 修复缺少冒号的问题（针对数组项）
        if (
            line.strip().startswith("- ")
            and ":" not in line
            and not line.strip().endswith("-")
        ):
            # 如果是简单的字符串数组项，可能需要修复
            stripped = line.strip()
            if stripped.startswith("- ") and len(stripped) > 2:
                # 如果不包含特殊字符，可能需要添加引号
                if not any(char in stripped for char in ["[", "]", "{", "}", '"', "'"]):
                    # 检查是否是引号开头但没有结束引号
                    if not (stripped.startswith('- "') and stripped.endswith('"')):
                        if not (stripped.startswith("- '") and stripped.endswith("'")):
                            # 添加引号
                            new_content = stripped.replace("- ", '- "') + '"'
                            line = line.replace(stripped, new_content)

        fixed_lines.append(line)

    return "\n".join(fixed_lines)


def convert_yaml_to_json(yaml_path: str, json_path: str = None) -> bool:
    """转换单个YAML文件到JSON"""
    try:
        yaml_file = Path(yaml_path)

        if not yaml_file.exists():
            print(f"❌ 文件不存在: {yaml_path}")
            return False

        if json_path is None:
            json_path = yaml_file.with_suffix(".json")

        # 读取YAML文件
        with open(yaml_file, "r", encoding="utf-8") as f:
            content = f.read()

        # 尝试修复常见问题
        try:
            data = yaml.safe_load(content)
        except yaml.YAMLError as e:
            print(f"⚠️  YAML解析错误，尝试修复: {e}")
            content = fix_yaml_content(content)
            data = yaml.safe_load(content)

        # 保存JSON文件
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False, sort_keys=True)

        print(f"✅ 转换成功: {yaml_path} -> {json_path}")
        return True

    except Exception as e:
        print(f"❌ 转换失败 {yaml_path}: {e}")
        return False


def convert_all_in_directory(directory: str = "config") -> dict:
    """转换目录下的所有YAML文件"""
    config_dir = Path(directory)

    if not config_dir.exists():
        print(f"❌ 目录不存在: {directory}")
        return {"total": 0, "success": 0, "failed": 0}

    yaml_files = []
    for ext in [".yml", ".yaml"]:
        yaml_files.extend(config_dir.rglob(f"*{ext}"))

    if not yaml_files:
        print(f"📂 在 {directory} 中未找到YAML文件")
        return {"total": 0, "success": 0, "failed": 0}

    print(f"🔄 找到 {len(yaml_files)} 个YAML文件，开始转换...")

    results = {"total": len(yaml_files), "success": 0, "failed": 0}

    for yaml_file in sorted(yaml_files):
        if convert_yaml_to_json(str(yaml_file)):
            results["success"] += 1
        else:
            results["failed"] += 1

    return results


def main():
    import sys

    if len(sys.argv) > 1:
        # 转换指定文件
        yaml_path = sys.argv[1]
        convert_yaml_to_json(yaml_path)
    else:
        # 转换所有YAML文件
        results = convert_all_in_directory("config")

        print(f"\n📊 转换结果:")
        print(f"  总计: {results['total']} 个文件")
        print(f"  成功: {results['success']} 个")
        print(f"  失败: {results['failed']} 个")

        if results["failed"] == 0:
            print(f"\n🎉 所有文件转换成功！")
            print(f"💡 现在可以删除 .yml 文件了")


if __name__ == "__main__":
    main()
