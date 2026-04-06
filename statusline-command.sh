#!/usr/bin/env bash
# Claude Code status line — styled after Git for Windows PS1
# Optimized: bash builtins for JSON parsing, minimal subshells

MAX_CWD_LENGTH=40   # Max display length for cwd (0 = no truncation)
CWD_TRUNC_POS=20    # Characters to keep from the start before the ellipsis

input=$(cat)
[ -z "$input" ] && exit 0

# Parse all JSON values using bash regex (no external processes)
[[ $input =~ \"current_dir\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && cwd="${BASH_REMATCH[1]}"
[[ $input =~ \"remaining_percentage\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && remaining="${BASH_REMATCH[1]}"
[[ $input =~ \"five_hour\"[^}]*\"used_percentage\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && five_hr="${BASH_REMATCH[1]}"
[[ $input =~ \"seven_day\"[^}]*\"used_percentage\"[[:space:]]*:[[:space:]]*([0-9]+) ]] && seven_day="${BASH_REMATCH[1]}"
[[ $input =~ \"display_name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && model="${BASH_REMATCH[1]}"
[[ $input =~ \"session_id\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]] && session_id="${BASH_REMATCH[1]}"

: "${cwd:=$(pwd)}"

# Git branch (1-2 git calls max) — must run before cwd truncation
git_branch=""
if branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null); then
  git_branch=" ($branch)"
elif short=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  git_branch=" ($short)"
fi

# Truncate long paths: keep head + … + tail
if (( MAX_CWD_LENGTH > 0 && ${#cwd} > MAX_CWD_LENGTH )); then
  (( CWD_TRUNC_POS < 0 )) && CWD_TRUNC_POS=0
  (( CWD_TRUNC_POS >= MAX_CWD_LENGTH )) && CWD_TRUNC_POS=$(( MAX_CWD_LENGTH - 1 ))
  _tail=$(( MAX_CWD_LENGTH - CWD_TRUNC_POS - 1 ))
  (( _tail > 0 )) && cwd="${cwd::CWD_TRUNC_POS}…${cwd: -_tail}"
fi

# Identity from env (no subshell needed)
: "${short_host:=${HOSTNAME%%.*}}"
[ -z "$short_host" ] && short_host=$(hostname -s 2>/dev/null || hostname 2>/dev/null)

# Detect shell environment label — portable across Windows/macOS/Linux
if [ -n "$MSYSTEM" ]; then
  env_label="$MSYSTEM"
else
  _os=$(uname -s 2>/dev/null)
  case "$_os" in
    Darwin)  env_label="macOS" ;;
    Linux)   env_label="Linux" ;;
    CYGWIN*) env_label="Cygwin" ;;
    MINGW*)  env_label="MinGW" ;;
    *)       env_label="${_os:-unknown}" ;;
  esac
fi

# Detect whether the terminal supports ANSI escape codes
# Respects the NO_COLOR convention (https://no-color.org)
if [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
  _dim=$'\033[2m' _rst=$'\033[0m'
else
  _dim="" _rst=""
fi

# Build segments inline — no subshells
ctx="" limits="" model_info="" session_info=""
[ -n "$session_id" ] && session_info=" ${_dim}s:${session_id::8}${_rst}"
[ -n "$remaining"  ] && ctx=" ${_dim}ctx:$(( 100 - remaining ))%${_rst}"
if [ -n "$five_hr" ] || [ -n "$seven_day" ]; then
  limits=" ${_dim}5h:${five_hr:-0}% 7d:${seven_day:-0}%${_rst}"
fi
[ -n "$model" ] && model_info=" ${_dim}[$model]${_rst}"

_grn=$'\033[32m' _mag=$'\033[35m' _yel=$'\033[33m' _cyn=$'\033[36m'
[ -n "$_rst" ] || { _grn="" _mag="" _yel="" _cyn=""; }

printf "%s%s@%s%s %s%s%s %s%s%s%s%s%s%s%s%s%s" \
  "$_grn" "${USER:-$(whoami)}" "$short_host" "$_rst" \
  "$_mag" "$env_label"                        "$_rst" \
  "$_yel" "$cwd"                              "$_rst" \
  "$_cyn" "$git_branch"                       "$_rst" \
  "$model_info" "$ctx" "$limits" "$session_info"
