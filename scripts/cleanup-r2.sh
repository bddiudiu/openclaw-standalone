#!/bin/bash
# OpenClaw Standalone - R2 旧版本清理脚本
# Usage: CLOUDFLARE_ACCOUNT_ID=xxx CLOUDFLARE_API_TOKEN=xxx bash scripts/cleanup-r2.sh [keep_count]
# Requires: wrangler CLI installed

set -euo pipefail

KEEP_COUNT="${1:-3}"  # 保留最近 N 个版本，默认 3
BUCKET="clawpanel-releases"
PREFIX="openclaw-standalone/"

echo "=== OpenClaw Standalone R2 Cleanup ==="
echo "Bucket: $BUCKET"
echo "Prefix: $PREFIX"
echo "Keep latest: $KEEP_COUNT versions"
echo ""

# List all version directories
echo "Listing versions..."
VERSIONS=$(npx wrangler r2 object list "$BUCKET" --prefix "$PREFIX" 2>/dev/null | \
    grep -oE '"key":"openclaw-standalone/[^/]+/' | \
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^/]*' | \
    sort -Vr | uniq)

if [ -z "$VERSIONS" ]; then
    echo "No versions found."
    exit 0
fi

echo "Found versions:"
COUNT=0
while IFS= read -r ver; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -le $KEEP_COUNT ]; then
        echo "  ✅ $ver (keep)"
    else
        echo "  🗑️  $ver (will delete)"
    fi
done <<< "$VERSIONS"

# Delete old versions
COUNT=0
while IFS= read -r ver; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -gt $KEEP_COUNT ]; then
        echo ""
        echo "Deleting $ver..."
        # List and delete all objects under this version
        npx wrangler r2 object list "$BUCKET" --prefix "${PREFIX}${ver}/" 2>/dev/null | \
            grep -oE '"key":"[^"]*"' | grep -oE ':[^"]*"' | tr -d ':"' | \
            while IFS= read -r key; do
                echo "  rm $key"
                npx wrangler r2 object delete "$BUCKET/$key" 2>/dev/null || true
            done
    fi
done <<< "$VERSIONS"

echo ""
echo "=== Cleanup complete ==="
