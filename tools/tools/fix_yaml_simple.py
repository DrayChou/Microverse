#!/usr/bin/env python3
"""
简单的YAML格式修复工具
不依赖外部库，仅进行基本的格式修复
"""

import re
from pathlib import Path

def fix_yaml_basic_issues(content: str) -> str:
    """修复基本的YAML格式问题"""
    lines = content.split('\n')
    fixed_lines = []

    for i, line in enumerate(lines):
        # 跳过空行和注释
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            fixed_lines.append(line)
            continue

        # 修复数组项缺少引号的问题
        if stripped.startswith('- '):
            # 检查是否是字符串数组项
            array_item = stripped[2:].strip()

            # 如果包含特殊字符但没有引号，添加引号
            if array_item and not any(char in array_item for char in ['"', "'", '{', '}', '[', ']']):
                # 如果包含中文或特殊符号，需要加引号
                if re.search(r'[^\w\-\.\:]', array_item):
                    # 避免重复加引号
                    if not (array_item.startswith('"') and array_item.endswith('"')):
                        if not (array_item.startswith("'") and array_item.endswith("'")):
                            # 优先使用双引号
                            new_item = f'"{array_item}"'
                            line = line.replace(array_item, new_item)

        fixed_lines.append(line)

    return '\n'.join(fixed_lines)

def fix_yaml_file(file_path: Path) -> bool:
    """修复单个YAML文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 应用基本修复
        fixed_content = fix_yaml_basic_issues(content)

        # 保存修复后的内容
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)

        print(f"✅ 修复完成: {file_path}")
        return True
    except Exception as e:
        print(f"❌ 修复失败 {file_path}: {e}")
        return False

def main():
    import sys

    # 默认处理config目录
    config_dir = Path("../config")

    if not config_dir.exists():
        print(f"❌ 目录不存在: {config_dir}")
        return

    # 查找所有YAML文件
    yaml_files = []
    for ext in ['.yml', '.yaml']:
        yaml_files.extend(config_dir.rglob(f"*{ext}"))

    if not yaml_files:
        print(f"📂 在 {config_dir} 中未找到YAML文件")
        return

    print(f"🔄 找到 {len(yaml_files)} 个YAML文件，开始修复...")

    success_count = 0
    for yaml_file in sorted(yaml_files):
        if fix_yaml_file(yaml_file):
            success_count += 1

    print(f"\n📊 修复结果:")
    print(f"  总计: {len(yaml_files)} 个文件")
    print(f"  成功: {success_count} 个")
    print(f"  失败: {len(yaml_files) - success_count} 个")

    if success_count == len(yaml_files):
        print(f"\n🎉 所有文件修复成功！")
        print(f"💡 现在可以重新运行游戏测试配置加载")

if __name__ == "__main__":
    main()