#!/usr/bin/env bash
# Salva o estado atual da TV em backup/<data-hora>/ (somente leitura na TV)
source "$(dirname "$0")/comum.sh"

DEST="$RAIZ/backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEST"

tv pm list packages -f -u   > "$DEST/pacotes-todos.txt"
tv pm list packages -e      > "$DEST/pacotes-ativos.txt"
tv pm list packages -d      > "$DEST/pacotes-desativados.txt"
tv pm list packages -3      > "$DEST/pacotes-terceiros.txt"
tv settings list global     > "$DEST/settings-global.txt"
tv settings list secure     > "$DEST/settings-secure.txt"
tv settings list system     > "$DEST/settings-system.txt"
tv cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME \
  > "$DEST/launcher-padrao.txt"
tv dumpsys meminfo          > "$DEST/memoria.txt"

echo "Backup salvo em: $DEST"
