#!/bin/bash
set -euo pipefail

# Generate test markdown files for sidebar lazy-loading performance tests
# Creates N files with varied content patterns

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${ROOT_DIR}/Tests/generated/sidebar_perf"

# Topics for variety
TOPICS=(
  "API Design" "Authentication" "Authorization" "Caching" "Configuration"
  "Database" "Deployment" "Encryption" "Error Handling" "Events"
  "Feature Flags" "Load Balancing" "Logging" "Monitoring" "Networking"
  "Observability" "Performance" "Queueing" "Rate Limiting" "Resilience"
  "Routing" "Scalability" "Security" "Serialization" "Sessions"
  "Storage" "Testing" "Tracing" "Validation" "Webhooks"
)

# Tags pools
TAGS_WIP=("wip" "draft" "review")
TAGS_DONE=("done" "stable" "archive")
TAGS_OPS=("ops" "infra" "devops")

# Sentence pools for overview section
SENTENCES=(
  "Security must be a first-class concern."
  "Error handling should be comprehensive."
  "Performance characteristics depend on input size."
  "Documentation is essential for maintainability."
  "Testing prevents regression and enables refactoring."
  "Simplicity trumps cleverness in production code."
  "Code review catches issues early."
  "Scalability requires careful architecture."
  "Monitoring provides visibility into system health."
  "Caching improves response times significantly."
)

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Get count from argument (default: 2000)
COUNT=${1:-2000}

echo "Generating $COUNT test markdown files..."

# Generate numbered notes using a more efficient approach
for ((i=1; i<=COUNT; i++)); do
  PADDED=$(printf "%04d" $i)
  TOPIC_IDX=$(( (i - 1) % ${#TOPICS[@]} ))
  TOPIC="${TOPICS[$TOPIC_IDX]}"
  TOPIC_LOWER=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

  # Determine tags
  if (( i % 3 == 0 )); then
    TAGS="[${TAGS_WIP[$((i % 3))]}, ${TAGS_OPS[$((i % 3))]}]"
  elif (( i % 3 == 1 )); then
    TAGS="[${TAGS_DONE[$((i % 3))]}]"
  else
    TAGS="[${TAGS_WIP[$((i % 2))]}, ${TAGS_DONE[$((i % 3))]}]"
  fi

  # Generate date
  DAY=$(( (i % 28) + 1 ))
  MONTH=$(( (i % 12) + 1 ))
  YEAR=$((2024 + (i / 500)))
  DATE="${YEAR}-$(printf "%02d" $MONTH)-$(printf "%02d" $DAY)"

  # Build overview from sentences
  OVERVIEW=""
  NUM_SENTENCES=$(( 4 + (i % 3) ))
  for ((j=0; j<NUM_SENTENCES; j++)); do
    SENTENCE_IDX=$(( (i + j) % ${#SENTENCES[@]} ))
    OVERVIEW+="${SENTENCES[$SENTENCE_IDX]} "
  done

  # Select language based on number
  LANG_IDX=$(( i % 4 ))

  # Generate code block based on language (using printf %b for escape interpretation)
  case $LANG_IDX in
    0)
      LANG="swift"
      CODE=$(printf 'func handle%s() -> Result<Void, Error> {\n    // TODO: implement %s\n    return .success(())\n}' "${TOPIC// /}" "$TOPIC_LOWER")
      ;;
    1)
      LANG="python"
      CODE=$(printf 'def %s_handler():\n    # TODO: implement %s\n    pass' "$TOPIC_LOWER" "$TOPIC_LOWER")
      ;;
    2)
      LANG="javascript"
      CODE=$(printf 'function handle%s() {\n    // TODO: implement %s\n    return Promise.resolve();\n}' "${TOPIC// /}" "$TOPIC_LOWER")
      ;;
    *)
      LANG="bash"
      CODE=$(printf '#!/bin/bash\n# %s handler\necho "Implementing %s..."' "$TOPIC" "$TOPIC_LOWER")
      ;;
  esac

  # Write file using printf to handle newlines
  # Use -- to stop option processing, or print each line separately
  {
    printf '%s\n' '---'
    printf 'title: "%s - Note %d"\n' "$TOPIC" "$i"
    printf 'tags: %s\n' "$TAGS"
    printf 'date: %s\n' "$DATE"
    printf '%s\n' '---' ''
    printf '# %s #%d\n\n' "$TOPIC" "$i"
    printf 'This document covers %s patterns and best practices.\n\n' "$TOPIC_LOWER"
    printf '%s\n' '## Overview' ''
    printf '%s\n\n' "$OVERVIEW"
    printf '```%s\n' "$LANG"
    printf '%b\n' "$CODE"
    printf '%s\n' '```'
  } > "${OUTPUT_DIR}/note_${PADDED}.md"

  # Progress indicator
  if (( i % 500 == 0 )); then
    echo "Generated $i files..."
  fi
done

echo ""
echo "Done! Generated $COUNT files in $OUTPUT_DIR"
echo "  - DEMO_all_elements.md (reference document)"
echo "  - note_0001.md through note_$(printf "%04d" $COUNT).md"
