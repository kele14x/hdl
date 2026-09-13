#!/usr/bin/env bash
# Run one or more make targets across every HDL module, continuing past failures.
#
# The top-level Makefile calls this for `make all`, `make lint`, `make test`,
# `make format`, `make ooc` and `make ooc-impl`.  Every module writes its full
# output to .build_logs/<target>-<module>.log; the console gets one PASS/FAIL
# line per module plus a final summary, so a change that fixes one block and
# breaks a neighbour is visible without scrolling through build output.
#
# Module lists and other settings come from the environment, set by the
# top-level Makefile:
#   HDL_MODULES       modules for lint / test / format
#   HDL_OOC_MODULES   modules that provide an out-of-context synthesis script
#   HDL_IMPL_MODULES  modules that provide an out-of-context implementation script
set -uo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

log_dir=$repo_root/.build_logs
mkdir -p "$log_dir"

# Unquoted expansions below deliberately split the space-separated lists.
# shellcheck disable=SC2206
declare -a hdl_modules=(${HDL_MODULES:-})
# shellcheck disable=SC2206
declare -a ooc_modules=(${HDL_OOC_MODULES:-})
# shellcheck disable=SC2206
declare -a impl_modules=(${HDL_IMPL_MODULES:-})
declare -a failures=()

if (($# == 0)); then
  echo "usage: $(basename "$0") <target> [<target> ...]" >&2
  exit 2
fi

# ANSI colors only when attached to a terminal.
if [[ -t 1 ]]; then
  c_pass=$'\033[32m'
  c_fail=$'\033[31m'
  c_bold=$'\033[1m'
  c_off=$'\033[0m'
else
  c_pass=''
  c_fail=''
  c_bold=''
  c_off=''
fi

modules_for() {
  case $1 in
  ooc) ((${#ooc_modules[@]})) && printf '%s\n' "${ooc_modules[@]}" ;;
  ooc-impl) ((${#impl_modules[@]})) && printf '%s\n' "${impl_modules[@]}" ;;
  *) ((${#hdl_modules[@]})) && printf '%s\n' "${hdl_modules[@]}" ;;
  esac
  return 0
}

run_module() {
  local target=$1 module=$2
  local log=$log_dir/$target-$module.log
  local start end rc

  printf '  %-24s ' "$module"
  start=$(date +%s)
  make -C "$module" "$target" >"$log" 2>&1
  rc=$?
  end=$(date +%s)

  if ((rc == 0)); then
    printf '%sPASS%s %3ds\n' "$c_pass" "$c_off" "$((end - start))"
  else
    printf '%sFAIL%s %3ds  %s\n' "$c_fail" "$c_off" "$((end - start))" "${log#"$repo_root"/}"
    failures+=("$target:$module")
  fi
}

for target in "$@"; do
  mapfile -t list < <(modules_for "$target")
  if ((${#list[@]} == 0)); then
    printf '%s[%s]%s no modules configured, skipped\n' "$c_bold" "$target" "$c_off"
    continue
  fi
  printf '%s[%s]%s %d module(s), logs in .build_logs/\n' \
    "$c_bold" "$target" "$c_off" "${#list[@]}"
  for module in "${list[@]}"; do
    run_module "$target" "$module"
  done
  echo
done

if ((${#failures[@]} == 0)); then
  printf '%s==================== summary: all passed ====================%s\n' "$c_pass" "$c_off"
  exit 0
fi

printf '%s==================== summary: %d failure(s) ====================%s\n' \
  "$c_fail" "${#failures[@]}" "$c_off"
for entry in "${failures[@]}"; do
  printf '  %-24s target: %-8s log: %s\n' "${entry#*:}" "${entry%%:*}" \
    ".build_logs/${entry%%:*}-${entry#*:}.log"
done

printf '\n---------------- tail of failed logs ----------------\n'
for entry in "${failures[@]}"; do
  target=${entry%%:*}
  module=${entry#*:}
  printf '\n===== %s: %s =====\n' "$target" "$module"
  tail -n 25 "$log_dir/$target-$module.log"
done
exit 1
