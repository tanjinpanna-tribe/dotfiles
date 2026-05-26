#!/usr/bin/env bash
# Claude Code statusLine command — Catppuccin Mocha + context progress bar

input=$(cat)

# Extract fields
user=$(whoami)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
branch=$(echo "$input" | jq -r '.workspace.repo | if . then .owner + "/" + .name else empty end // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Truncate cwd to last 3 path components
short_dir=$(echo "$cwd" | awk -F'/' '{
  n=NF; start=n-2;
  if (start < 1) start=1;
  out="";
  for (i=start; i<=n; i++) {
    if (out != "") out = out "/" $i;
    else out = $i;
  }
  if (start > 1) out = "…/" out;
  print out
}')

# Git branch
git_branch=""
if [ -n "$cwd" ] && { [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; }; then
  git_branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

# Catppuccin Mocha palette
RED='\033[38;2;243;139;168m'      # #f38ba8
PEACH='\033[38;2;250;179;135m'    # #fab387
YELLOW='\033[38;2;249;226;175m'   # #f9e2af
GREEN='\033[38;2;166;227;161m'    # #a6e3a1
SAPPHIRE='\033[38;2;116;199;236m' # #74c7ec
LAVENDER='\033[38;2;180;190;254m' # #b4befe
RESET='\033[0m'

# Context bar: tokens_k = used_pct * 10, bar fills toward 200k
tokens_k=$(echo "$context_pct" | awk '{printf "%.0f", $1 * 2}')
filled=$(echo "$tokens_k" | awk '{f = int($1 / 20); print (f > 10 ? 10 : f)}')
empty=$((10 - filled))

bar=""
for ((i=0; i<filled; i++)); do bar="${bar}█"; done
for ((i=0; i<empty; i++)); do bar="${bar}░"; done

if [ "$tokens_k" -lt 100 ]; then
  bar_color="$GREEN"
elif [ "$tokens_k" -lt 200 ]; then
  bar_color="$YELLOW"
else
  bar_color="$RED"
fi

# Assemble parts
parts="${RED}${user}${RESET}"
parts="${parts} ${PEACH}${short_dir}${RESET}"

if [ -n "$git_branch" ]; then
  parts="${parts} ${YELLOW} ${git_branch}${RESET}"
fi

if [ -n "$model" ]; then
  parts="${parts} ${SAPPHIRE}${model}${RESET}"
fi

if [ -n "$context_pct" ] && [ "$context_pct" != "0" ] || [ "$tokens_k" -ge 0 ]; then
  parts="${parts} ${bar_color}${bar} ${tokens_k}k${RESET}"
fi

if [ -n "$vim_mode" ] && [ "$vim_mode" != "INSERT" ]; then
  parts="${parts} ${LAVENDER}[${vim_mode}]${RESET}"
fi

printf "%b\n" "$parts"
