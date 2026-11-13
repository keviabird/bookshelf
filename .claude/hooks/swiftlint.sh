#!/bin/bash
input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")

# Только Swift-файлы
[[ "$file" == *.swift ]] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0

# Сначала автоисправление того, что SwiftLint умеет чинить сам
swiftlint --fix --quiet "$file" >/dev/null 2>&1

# Остальное — обратно Claude (exit 2 = Claude увидит stderr)
if ! output=$(swiftlint lint --strict --quiet "$file" 2>&1); then
  echo "SwiftLint: исправь замечания в $file" >&2
  echo "$output" >&2
  exit 2
fi
exit 0
