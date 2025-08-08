import os
import re
import sys
from pathlib import Path

# 匹配形如 `.withOpacity(0.9)` 或 `.withOpacity(.8)` 或 `.withOpacity(1)`
pattern = re.compile(r'\.withOpacity\(\s*([0-9]*\.?[0-9]+)\s*\)')

def opacity_to_alpha(opacity: float) -> int:
    """按 Flutter 逻辑：alpha = round(opacity * 255)，并限制范围"""
    opacity = max(0.0, min(opacity, 1.0))
    return round(opacity * 255)

def process_file(file_path: Path, dry_run: bool = True) -> int:
    """处理单个文件，返回替换次数"""
    with file_path.open('r', encoding='utf-8') as f:
        content = f.read()

    changes = 0

    def replacer(match):
        nonlocal changes
        val_str = match.group(1)
        try:
            val = float(val_str)
        except ValueError:
            return match.group(0)  # 保留原样

        alpha_val = opacity_to_alpha(val)
        changes += 1
        return f'.withAlpha({alpha_val})'

    new_content = pattern.sub(replacer, content)

    if changes > 0 and not dry_run:
        with file_path.open('w', encoding='utf-8') as f:
            f.write(new_content)

    return changes

def scan_directory(root_path: Path, dry_run: bool = True):
    total_changes = 0
    files_changed = 0
    for file_path in root_path.rglob("*.dart"):
        changes = process_file(file_path, dry_run=dry_run)
        if changes > 0:
            files_changed += 1
            total_changes += changes
            print(f"{'[DRY RUN] ' if dry_run else ''}Updated {file_path} ({changes} changes)")
    print(f"\nSummary: {files_changed} files changed, {total_changes} replacements.")
    if dry_run:
        print("Dry run mode: No files were actually modified.")

if __name__ == "__main__":
    # 默认扫描当前目录，可以通过命令行参数指定路径
    target_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    dry_run = '--dry-run' in sys.argv
    scan_directory(target_dir, dry_run=dry_run)
