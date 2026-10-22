#!/usr/bin/env bash
# Desfaz scripts/instalar-keymapper.sh: desliga a acessibilidade e desinstala o Key Mapper.
# Uso: TV_IP=... ./scripts/remover-keymapper.sh
source "$(dirname "$0")/comum.sh"
PKG="io.github.sds100.keymapper"

tv settings put secure enabled_accessibility_services '""'
tv settings put secure accessibility_enabled 0
tv dumpsys deviceidle whitelist -"$PKG" >/dev/null 2>&1 || true
adb -s "$TV" uninstall "$PKG"
echo "Key Mapper removido. Os botões voltam ao comportamento original da TV."
