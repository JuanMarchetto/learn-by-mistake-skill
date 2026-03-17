---
name: learn
description: "Force-extract a lesson from the last error, bypassing the 2-occurrence confidence gate"
---

# /learn — Force Lesson Extraction

You are the Learn-by-Mistake skill's lesson extraction engine. The user has triggered `/learn` to force-extract a lesson from the most recent error in this conversation.

## Instructions

1. **Find the most recent error** in this conversation. Look for:
   - Failed Bash commands (non-zero exit codes)
   - Error messages in stderr
   - Compilation/build failures
   - Runtime exceptions or tracebacks
   - Any tool use that produced an error

2. **If no error is found**, tell the user: "No recent error found in this conversation. Try running a command first, or describe the mistake you want to capture."

3. **Extract a lesson** using this format:
   ```
   ### [NUMBER]. [SHORT TITLE]
   - **Pattern**: [What triggers this error — the recognizable pattern]
   - **Fix**: [The correct approach or solution]
   - **Category**: [One of: syntax, config, tooling, environment, logic, testing, git, deployment, permissions, dependencies]
   - **Added**: [YYYY-MM-DD]
   - **Hits**: 0
   ```

4. **Show the lesson to the user** and ask for approval before writing. Example:
   ```
   Extracted lesson from the last error:

   ### 12. Use --no-pager with git log in scripts
   - **Pattern**: git log hangs in non-interactive shell
   - **Fix**: Always pass `--no-pager` or pipe to `cat` when using git in scripts
   - **Category**: tooling
   - **Added**: 2026-03-17
   - **Hits**: 0

   Write this to .claude/lessons.md? (yes/no/edit)
   ```

5. **On approval**, write the lesson directly to the **Active Lessons** section of `.claude/lessons.md`:
   - If the file doesn't exist, create it with the standard template (see below)
   - Auto-increment the lesson number
   - Place it at the end of the Active Lessons section (before Archive if it exists)

6. **Skip the Pending stage** — this command bypasses the normal 2-occurrence confidence gate and writes directly to Active Lessons.

## lessons.md Template (if file doesn't exist)

```markdown
# Lessons Learned

> Auto-maintained by the learn-by-mistake skill. Do not edit the YAML front matter.

<!--
confidence_gate: 2
max_active: 50
auto_archive_days: 30
-->

## Active Lessons

## Pending

## Archive
```

## Important

- Each lesson must be concise — one pattern, one fix
- Avoid duplicates: scan existing lessons before adding
- If a similar lesson exists, suggest updating it instead of creating a new one
- Always show the lesson for user approval before writing
