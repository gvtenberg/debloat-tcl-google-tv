#!/usr/bin/env bash
# Reativa os apps de uma lista. Uso: TV_IP=... ./scripts/reverter.sh listas/fase1-debloat.txt
source "$(dirname "$0")/comum.sh"
LISTA="${1:?Informe o arquivo de lista}"

for p in $(pacotes "$LISTA"); do
  tv cmd package install-existing --user 0 "$p" >/dev/null 2>&1 || true
  if tv pm enable --user 0 "$p" 2>&1 | grep -q "enabled"; then
    echo "OK $p: reativado"
  else
    echo "!! $p: não foi possível reativar (talvez não exista nesta TV)"
  fi
done
