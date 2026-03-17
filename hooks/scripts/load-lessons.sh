#!/bin/bash
# load-lessons.sh — SessionStart hook
# Reads .claude/lessons.md at session start and emits a summary
# so Claude is aware of accumulated lessons from the beginning.

set -euo pipefail

LESSONS_FILE=".claude/lessons.md"

# Check if lessons file exists
if [ ! -f "$LESSONS_FILE" ]; then
  cat <<'EOF'
{"systemMessage": "Learn-by-Mistake skill active. No lessons file found yet (.claude/lessons.md). Lessons will be created as errors are encountered. The user can also run /learn to force-extract a lesson from any error."}
EOF
  exit 0
fi

# Count active lessons
ACTIVE_COUNT=$(grep -c '^### [0-9]' "$LESSONS_FILE" 2>/dev/null || echo "0")

# If we can parse sections, count per section
ACTIVE_SECTION_COUNT=0
PENDING_COUNT=0
ARCHIVE_COUNT=0

# Use awk to count lessons per section
read -r ACTIVE_SECTION_COUNT PENDING_COUNT ARCHIVE_COUNT <<< $(python3 -c "
import re, sys

try:
    with open('$LESSONS_FILE', 'r') as f:
        content = f.read()

    sections = re.split(r'^## ', content, flags=re.MULTILINE)
    active = pending = archive = 0

    for section in sections:
        lesson_count = len(re.findall(r'^### \d+\.', section, re.MULTILINE))
        header = section.split('\n')[0].strip().lower()
        if 'active' in header:
            active = lesson_count
        elif 'pending' in header:
            pending = lesson_count
        elif 'archive' in header:
            archive = lesson_count

    print(f'{active} {pending} {archive}')
except:
    print('0 0 0')
" 2>/dev/null || echo "0 0 0")

# Extract categories of active lessons
CATEGORIES=$(python3 -c "
import re

try:
    with open('$LESSONS_FILE', 'r') as f:
        content = f.read()

    # Find the Active Lessons section
    active_match = re.search(r'## Active Lessons\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    if active_match:
        cats = re.findall(r'\*\*Category\*\*:\s*(\w+)', active_match.group(1))
        from collections import Counter
        counts = Counter(cats)
        parts = [f'{cat}({n})' for cat, n in counts.most_common()]
        print(', '.join(parts) if parts else 'none')
    else:
        print('none')
except:
    print('none')
" 2>/dev/null || echo "none")

# Build the summary message
SUMMARY="Learn-by-Mistake skill active. Loaded $ACTIVE_SECTION_COUNT active lessons"

if [ "$PENDING_COUNT" -gt 0 ] 2>/dev/null; then
  SUMMARY="$SUMMARY, $PENDING_COUNT pending"
fi

if [ "$ARCHIVE_COUNT" -gt 0 ] 2>/dev/null; then
  SUMMARY="$SUMMARY, $ARCHIVE_COUNT archived"
fi

SUMMARY="$SUMMARY. Categories: $CATEGORIES."
SUMMARY="$SUMMARY When you encounter errors, check these lessons BEFORE attempting a fix. Consult .claude/lessons.md for full details."

# Escape for JSON
SUMMARY_ESCAPED=$(echo "$SUMMARY" | sed 's/"/\\"/g' | tr -d '\n')

cat <<EOF
{"systemMessage": "$SUMMARY_ESCAPED"}
EOF
