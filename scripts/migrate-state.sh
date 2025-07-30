#!/bin/bash
set -e

# State migration helper for moving between deployment contexts
PROJECT_ID="${1:-credible-bank-466613-j6}"
ENVIRONMENT="${2:-dev}"
SOURCE_CONTEXT="${3:-manual}"
TARGET_CONTEXT="${4:-cicd}"
MODULE="${5:-bootstrap-backend}"

SOURCE_BUCKET="${PROJECT_ID}-tfstate-${ENVIRONMENT}-${SOURCE_CONTEXT}"
TARGET_BUCKET="${PROJECT_ID}-tfstate-${ENVIRONMENT}-${TARGET_CONTEXT}"

echo "Migrating state from $SOURCE_BUCKET to $TARGET_BUCKET"

# Create target bucket if it doesn't exist
if ! gsutil ls "gs://$TARGET_BUCKET" 2>/dev/null; then
    echo "Creating target bucket..."
    gsutil mb -p "$PROJECT_ID" -c STANDARD -l us-west1 "gs://$TARGET_BUCKET"
fi

# Copy state
echo "Copying state files..."
gsutil -m cp -r "gs://$SOURCE_BUCKET/$MODULE/*" "gs://$TARGET_BUCKET/$MODULE/" || {
    echo "No existing state found, starting fresh"
}

echo "State migration completed"