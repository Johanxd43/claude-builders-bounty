#!/bin/bash

# changelog.sh
# Generates a structured CHANGELOG.md from git history

set -e

OUTPUT_FILE="CHANGELOG.md"
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
COMMITS_SINCE_TAG=$(git log --pretty=format:"%h - %an, %ar : %s" ${LAST_TAG}..HEAD)

# Initialize changelog
echo "# Changelog" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Categorize commits
echo "## Added" >> $OUTPUT_FILE
echo "$COMMITS_SINCE_TAG" | grep -i "add" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "## Fixed" >> $OUTPUT_FILE
echo "$COMMITS_SINCE_TAG" | grep -i "fix" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "## Changed" >> $OUTPUT_FILE
echo "$COMMITS_SINCE_TAG" | grep -i "change" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "## Removed" >> $OUTPUT_FILE
echo "$COMMITS_SINCE_TAG" | grep -i "remove" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

echo "Changelog generated successfully at $OUTPUT_FILE"