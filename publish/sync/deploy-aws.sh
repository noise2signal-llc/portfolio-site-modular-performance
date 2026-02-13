#!/bin/bash
set -e

if [[ -z "$AWS_PROFILE" ]]; then
    echo "Nope: AWS_PROFILE environment variable is not set"
    exit 1
fi

SITE_ROOT="$(git rev-parse --show-toplevel)/site-root"
BUCKET="s3://camdenwander.com"

# Generate cache-busting version (Unix timestamp)
CACHE_VERSION=$(date +%s)

# Inject cache version into index.html
sed -i "s/CACHE_VERSION/$CACHE_VERSION/g" "${SITE_ROOT}/index.html"

# Restore function to ensure cleanup on exit
cleanup() {
    sed -i "s/$CACHE_VERSION/CACHE_VERSION/g" "${SITE_ROOT}/index.html"
}
trap cleanup EXIT

# Sync files separately to ensure explicit MIME types

aws s3 sync \
    --delete \
    --exclude "*" \
    --include "*.css" \
    --content-type "text/css" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

aws s3 sync \
    --delete \
    --exclude "*" \
    --include "*.js" \
    --content-type "application/javascript" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

aws s3 sync \
    --delete \
    --exclude "*" \
    --include "*.html" \
    --content-type "text/html" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

aws s3 sync \
    --delete \
    --exclude "*" \
    --include "*.m3u8" \
    --content-type "application/vnd.apple.mpegurl" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

aws s3 sync \
    --delete \
    --exclude "*" \
    --include "*.ts" \
    --content-type "video/mp2t" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

# Sync remaining files with auto-detection (AWS CLI auto-detects MIME types by default)
aws s3 sync \
    --delete \
    --exclude "*.md" \
    --exclude "*.css" \
    --exclude "*.js" \
    --exclude "*.html" \
    --exclude "*.m3u8" \
    --exclude "*.ts" \
    "${SITE_ROOT}/" \
    "${BUCKET}/"

echo "Deployment complete!"
