#!/usr/bin/env bash
set -euo pipefail

sdk_zephyr="${ZEPHYR_BASE:-/workdir/zephyr}"
diag=/workdir/project/firmware-bluetooth/diagnostics

# Order matters: encryption-ll-trace.patch is made on top of smp-opcodes.patch.
# scan-trace.patch only touches scan.c and was made on top of both.
patches=(
    "$diag/smp-opcodes.patch"
    "$diag/encryption-ll-trace.patch"
    "$diag/scan-trace.patch"
)

# Kconfig fragments merged after prj.conf. Keep experiments to one variable.
overlays=(
    "$diag/smp.conf"
    "$diag/experiment-no-auto-phy.conf"
)

git -C "$sdk_zephyr" describe --tags --always 2>/dev/null || true

for patch in "${patches[@]}"; do
    echo "Applying $(basename "$patch")"
    git -C "$sdk_zephyr" apply --check "$patch"
    git -C "$sdk_zephyr" apply "$patch"
done

# Zephyr 3.2 (NCS 2.2) only knows OVERLAY_CONFIG (space-separated list).
# EXTRA_CONF_FILE was added in a later Zephyr and is silently ignored here.
west build -b seeed_xiao_nrf52840 -- -DOVERLAY_CONFIG="${overlays[*]}"

# Fail the build if any fragment assignment did not end up in the final config.
config=build/zephyr/.config
for overlay in "${overlays[@]}"; do
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '' | '#'*) continue ;;
        esac
        name="${line%%=*}"
        if [ "${line#*=}" = "n" ]; then
            expected="# $name is not set"
        else
            expected="$line"
        fi
        if ! grep -qxF "$expected" "$config"; then
            echo "Kconfig fragment not applied: $(basename "$overlay"): $line" >&2
            exit 1
        fi
        echo "Kconfig applied: $line"
    done < "$overlay"
done
