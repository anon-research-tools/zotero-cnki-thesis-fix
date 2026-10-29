#!/usr/bin/env bash
# Zotero CNKI thesis metadata fix — Linux installer
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

CANDIDATES=(
  "$HOME/.zotero/zotero"
  "$HOME/.var/app/org.zotero.Zotero/.zotero/zotero"
  "$HOME/snap/zotero-snap/common/.zotero/zotero"
)
PREFS=""
for base in "${CANDIDATES[@]}"; do
  if [ -d "$base" ]; then
    found="$(ls -t "$base"/*/prefs.js 2>/dev/null | head -1 || true)"
    if [ -n "$found" ]; then PREFS="$found"; break; fi
  fi
done

DATA=""
if [ -n "$PREFS" ]; then
  USE="$(grep -o 'extensions\.zotero\.useDataDir", [a-z]*' "$PREFS" | awk '{print $2}' | tr -d ');' || true)"
  DIR="$(grep -o 'extensions\.zotero\.dataDir", "[^"]*"' "$PREFS" | sed 's/.*", "//; s/"$//' || true)"
  if [ "$USE" = "true" ] && [ -n "$DIR" ]; then
    DATA="$DIR"
  fi
fi

if [ -z "$DATA" ]; then
  DATA="$HOME/Zotero"
fi

TARGET_DIR="$DATA/translators"
TARGET="$TARGET_DIR/CNKI.js"

if [ ! -d "$TARGET_DIR" ]; then
  echo "找不到 Zotero 译者目录：$TARGET_DIR"
  echo "请先在 Zotero 设置 → 高级 → 文件和文件夹 确认数据目录。"
  exit 1
fi

STAMP="$(date +%Y%m%d%H%M%S)"
if [ -f "$TARGET" ]; then
  cp -p "$TARGET" "$TARGET.bak-$STAMP"
  echo "已备份：$TARGET.bak-$STAMP"
fi

cp "$HERE/CNKI.js" "$TARGET"
perl -0pi -e 's/"lastUpdated": "[^"]*"/"lastUpdated": "'"$(date '+%Y-%m-%d %H:%M:%S')"'"/' "$TARGET"

echo
echo "已安装到：$TARGET"
echo
echo "接下来："
echo "  1. 完全退出并重新启动 Zotero"
echo "  2. 浏览器 → Zotero 连接器 → 设置 → 高级 → Reset Translators"
echo "  3. 刷新知网检索页，批量保存 2 篇学位论文验证「大学」「日期」"
echo
echo "回滚：把 $TARGET.bak-$STAMP 改名回 CNKI.js，重启 Zotero 后再 Reset Translators。"
