#!/bin/bash
# validate-commit-msg.sh - Validate conventional commit messages
# Usage: validate-commit-msg.sh <commit-msg-file>

set -euo pipefail

COMMIT_MSG_FILE="${1:-}"

if [ -z "$COMMIT_MSG_FILE" ]; then
    echo "Error: No commit message file provided"
    exit 1
fi

COMMIT_MSG=$(head -n1 "$COMMIT_MSG_FILE")

# Conventional commit pattern
# Examples:
#   feat: add new feature
#   fix(parser): handle edge case
#   docs: update README
#   refactor!: breaking change
PATTERN="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?: .+"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
    echo ""
    echo "Error: Commit message does not follow conventional commit format"
    echo ""
    echo "Expected format: <type>[(scope)][!]: <description>"
    echo ""
    echo "Valid types:"
    echo "  feat     - New feature"
    echo "  fix      - Bug fix"
    echo "  docs     - Documentation only"
    echo "  style    - Code style (formatting, semicolons, etc)"
    echo "  refactor - Code refactoring"
    echo "  perf     - Performance improvement"
    echo "  test     - Adding or fixing tests"
    echo "  build    - Build system or dependencies"
    echo "  ci       - CI/CD configuration"
    echo "  chore    - Maintenance tasks"
    echo "  revert   - Revert previous commit"
    echo ""
    echo "Examples:"
    echo "  feat: add liquid background animation"
    echo "  fix(parser): handle empty frontmatter"
    echo "  docs: update API documentation"
    echo "  refactor!: simplify render pipeline"
    echo ""
    exit 1
fi

# Check message length (should be <= 72 chars for first line)
if [ ${#COMMIT_MSG} -gt 72 ]; then
    echo "Warning: Commit message subject exceeds 72 characters"
    echo "Current length: ${#COMMIT_MSG}"
    echo "Consider making the subject line more concise"
fi

echo "Commit message format is valid"
exit 0
