#!/usr/bin/env bash
set -euo pipefail

sdk_zephyr="${ZEPHYR_BASE:-/workdir/zephyr}"
diag=/workdir/project/firmware-bluetooth/diagnostics

# Order matters: encryption-ll-trace.patch is made on top of smp-opcodes.patch.
patches=(
    "$diag/smp-opcodes.patch"
    "$diag/encryption-ll-trace.patch"
)

git -C "$sdk_zephyr" describe --tags --always 2>/dev/null || true

for patch in "${patches[@]}"; do
    echo "Applying $(basename "$patch")"
    git -C "$sdk_zephyr" apply --check "$patch"
    git -C "$sdk_zephyr" apply "$patch"
done

west build -b seeed_xiao_nrf52840 -- -DEXTRA_CONF_FILE="$diag/smp.conf"
