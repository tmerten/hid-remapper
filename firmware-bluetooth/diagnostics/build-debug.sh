#!/usr/bin/env bash
set -euo pipefail

sdk_zephyr="${ZEPHYR_BASE:-/workdir/zephyr}"
patch=/workdir/project/firmware-bluetooth/diagnostics/smp-opcodes.patch

git -C "$sdk_zephyr" apply --check "$patch"
git -C "$sdk_zephyr" apply "$patch"
west build -b seeed_xiao_nrf52840 -- -DEXTRA_CONF_FILE=/workdir/project/firmware-bluetooth/diagnostics/smp.conf
