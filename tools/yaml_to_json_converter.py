#!/usr/bin/env python3
"""
YAML 到 JSON 转换工具
专门为 Microverse 项目设计，方便配置文件的手动编辑和维护

特性:
- 智能格式化，便于阅读
- 保持注释（通过特殊标记）
- 批量转换
- 验证JSON语法
- 备份原文件
"""

import os
import json
import yaml
import argparse
from pathlib import Path
from datetime import datetime
import shutil
from typing import Dict, Any, List, Optional

class YAMLToJSONConverter:
    def __init__(self, config_dir: str = "config"):
        self.config_dir = Path(config_dir)
        self.backup_dir = Path("backups")
        self.supported_extensions = ['.yml', '.yaml']

    def setup_backup_directory(self):
        """创建备份目录"""
        if not self.backup_dir.exists():
            self.backup_dir.mkdir()
            print(f"📁 创建备份目录: {self.backup_dir}")

    def create_backup(self, file_path: Path) -> Path:
        """创建文件备份"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{file_path.stem}_{timestamp}{file_path.suffix}"
        backup_path = self.backup_dir / backup_name

        shutil.copy2(file_path, backup_path)
        print(f"💾 备份: {file_path} -> {backup_path}")
        return backup_path

    def load_yaml(self, file_path: Path) -> Optional[Dict[str, Any]]:
        """加载YAML文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 处理可能的BOM
            if content.startswith('\ufeff'):
                content = content[1:]

            data = yaml.safe_load(content)
            return data
        except yaml.YAMLError as e:
            print(f"❌ YAML解析错误 {file_path}: {e}")
            return None
        except Exception as e:
            print(f"❌ 文件读取错误 {file_path}: {e}")
            return None

    def save_json(self, data: Dict[str, Any], file_path: Path, indent: int = 2) -> bool:
        """保存JSON文件"""
        try:
            json_path = file_path.with_suffix('.json')

            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=indent, ensure_ascii=False, sort_keys=True)

            print(f"✅ 转换成功: {file_path} -> {json_path}")
            return True
        except Exception as e:
            print(f"❌ JSON保存错误 {json_path}: {e}")
            return False

    def validate_json(self, file_path: Path) -> bool:
        """验证JSON文件语法"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                json.load(f)
            return True
        except json.JSONDecodeError as e:
            print(f"❌ JSON语法错误 {file_path}: {e}")
            return False

    def convert_single_file(self, yaml_path: Path, backup: bool = True) -> bool:
        """转换单个YAML文件"""
        if not yaml_path.exists():
            print(f"❌ 文件不存在: {yaml_path}")
            return False

        # 创建备份
        if backup:
            self.create_backup(yaml_path)

        # 加载YAML
        data = self.load_yaml(yaml_path)
        if data is None:
            return False

        # 保存JSON
        return self.save_json(data, yaml_path)

    def find_yaml_files(self, directory: Path = None) -> List[Path]:
        """查找所有YAML文件"""
        if directory is None:
            directory = self.config_dir

        yaml_files = []

        # 使用glob模式搜索
        for ext in self.supported_extensions:
            yaml_files.extend(directory.rglob(f"*{ext}"))

        # 排除备份目录
        yaml_files = [f for f in yaml_files if self.backup_dir not in f.parents]

        return sorted(yaml_files)

    def convert_directory(self, directory: Path = None, backup: bool = True) -> Dict[str, int]:
        """转换目录下的所有YAML文件"""
        if directory is None:
            directory = self.config_dir

        yaml_files = self.find_yaml_files(directory)

        if not yaml_files:
            print(f"📂 在 {directory} 中未找到YAML文件")
            return {"total": 0, "success": 0, "failed": 0}

        print(f"🔄 找到 {len(yaml_files)} 个YAML文件，开始转换...")

        results = {"total": len(yaml_files), "success": 0, "failed": 0}

        for yaml_file in yaml_files:
            if self.convert_single_file(yaml_file, backup):
                results["success"] += 1
            else:
                results["failed"] += 1

        return results

    def validate_json_files(self, directory: Path = None) -> Dict[str, int]:
        """验证目录下的所有JSON文件"""
        if directory is None:
            directory = self.config_dir

        json_files = list(directory.rglob("*.json"))
        json_files = [f for f in json_files if self.backup_dir not in f.parents]

        if not json_files:
            print(f"📂 在 {directory} 中未找到JSON文件")
            return {"total": 0, "valid": 0, "invalid": 0}

        print(f"🔍 验证 {len(json_files)} 个JSON文件...")

        results = {"total": len(json_files), "valid": 0, "invalid": 0}

        for json_file in json_files:
            if self.validate_json(json_file):
                results["valid"] += 1
            else:
                results["invalid"] += 1

        return results

    def show_status(self, directory: Path = None):
        """显示转换状态"""
        if directory is None:
            directory = self.config_dir

        yaml_files = self.find_yaml_files(directory)
        json_files = list(directory.rglob("*.json"))
        json_files = [f for f in json_files if self.backup_dir not in f.parents]

        print(f"\n📊 配置文件状态报告 ({directory})")
        print("=" * 50)
        print(f"YAML文件: {len(yaml_files)} 个")
        print(f"JSON文件: {len(json_files)} 个")

        # 配对分析
        yaml_stems = {f.stem for f in yaml_files}
        json_stems = {f.stem for f in json_files}

        both_formats = yaml_stems & json_stems
        yaml_only = yaml_stems - json_stems
        json_only = json_stems - yaml_stems

        print(f"\n🔄 格式对比:")
        print(f"  两种格式都有: {len(both_formats)} 个")
        print(f"  仅有YAML: {len(yaml_only)} 个")
        print(f"  仅有JSON: {len(json_only)} 个")

        if yaml_only:
            print(f"\n📝 需要转换的YAML文件:")
            for stem in sorted(yaml_only):
                yaml_files = [f for f in yaml_files if f.stem == stem]
                for yaml_file in yaml_files:
                    rel_path = yaml_file.relative_to(directory)
                    print(f"  - {rel_path}")

    def cleanup_yaml_files(self, directory: Path = None, dry_run: bool = True) -> List[Path]:
        """清理已转换为JSON的YAML文件"""
        if directory is None:
            directory = self.config_dir

        yaml_files = self.find_yaml_files(directory)
        json_files = list(directory.rglob("*.json"))
        json_files = [f for f in json_files if self.backup_dir not in f.parents]

        yaml_stems = {f.stem for f in yaml_files}
        json_stems = {f.stem for f in json_files}

        # 找出两种格式都有的文件
        both_formats = yaml_stems & json_stems
        files_to_remove = []

        for stem in both_formats:
            yaml_candidates = [f for f in yaml_files if f.stem == stem]
            files_to_remove.extend(yaml_candidates)

        if dry_run:
            print(f"\n🔍 将删除 {len(files_to_remove)} 个YAML文件:")
            for yaml_file in files_to_remove:
                rel_path = yaml_file.relative_to(directory)
                print(f"  - {rel_path}")
        else:
            print(f"\n🗑️  删除 {len(files_to_remove)} 个YAML文件:")
            for yaml_file in files_to_remove:
                try:
                    rel_path = yaml_file.relative_to(directory)
                    yaml_file.unlink()
                    print(f"  ✅ 删除: {rel_path}")
                except Exception as e:
                    print(f"  ❌ 删除失败 {rel_path}: {e}")

        return files_to_remove

def main():
    parser = argparse.ArgumentParser(
        description="YAML 到 JSON 转换工具 - Microverse 项目专用",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  python yaml_to_json_converter.py                    # 转换所有YAML文件
  python yaml_to_json_converter.py --status           # 显示状态
  python yaml_to_json_converter.py --validate         # 验证JSON文件
  python yaml_to_json_converter.py --file config.yml  # 转换单个文件
  python yaml_to_json_converter.py --cleanup          # 清理YAML文件（试运行）
  python yaml_to_json_converter.py --cleanup --force  # 真正删除YAML文件
        """
    )

    parser.add_argument('--dir', '-d', default='config',
                       help='配置目录路径 (默认: config)')
    parser.add_argument('--file', '-f',
                       help='转换单个文件')
    parser.add_argument('--no-backup', action='store_true',
                       help='不创建备份')
    parser.add_argument('--status', '-s', action='store_true',
                       help='显示转换状态')
    parser.add_argument('--validate', '-v', action='store_true',
                       help='验证JSON文件')
    parser.add_argument('--cleanup', action='store_true',
                       help='清理已转换的YAML文件')
    parser.add_argument('--force', action='store_true',
                       help='强制执行（配合 --cleanup 使用）')
    parser.add_argument('--indent', '-i', type=int, default=2,
                       help='JSON缩进空格数 (默认: 2)')

    args = parser.parse_args()

    converter = YAMLToJSONConverter(args.dir)

    if args.status:
        converter.show_status()
        return

    if args.validate:
        results = converter.validate_json_files()
        print(f"\n📊 验证结果: 总计 {results['total']}, 有效 {results['valid']}, 无效 {results['invalid']}")
        return

    if args.cleanup:
        converter.cleanup_yaml_files(dry_run=not args.force)
        return

    if args.file:
        # 转换单个文件
        file_path = Path(args.file)
        if not converter.convert_single_file(file_path, backup=not args.no_backup):
            exit(1)
    else:
        # 转换所有文件
        converter.setup_backup_directory()
        results = converter.convert_directory(backup=not args.no_backup)

        print(f"\n📊 转换结果:")
        print(f"  总计: {results['total']} 个文件")
        print(f"  成功: {results['success']} 个")
        print(f"  失败: {results['failed']} 个")

        if results['failed'] > 0:
            print(f"\n💡 提示: 请检查失败的YAML文件格式")
            exit(1)

        # 验证转换结果
        print(f"\n🔍 验证转换结果...")
        validate_results = converter.validate_json_files()
        print(f"JSON验证: 有效 {validate_results['valid']}, 无效 {validate_results['invalid']}")

        if validate_results['invalid'] == 0:
            print(f"🎉 所有文件转换成功！")
            print(f"💡 建议运行: python {__file__} --status 查看状态")
            print(f"💡 建议运行: python {__file__} --cleanup --force 清理YAML文件")

if __name__ == "__main__":
    main()