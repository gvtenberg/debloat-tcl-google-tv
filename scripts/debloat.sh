#!/usr/bin/env bash
# Desativa os apps de uma lista. Uso: TV_IP=... ./scripts/debloat.sh listas/fase1-debloat.txt
# 1ª tentativa: pm disable-user (desfaz com pm enable)
# 2ª tentativa, se o sistema não deixar desativar: pm uninstall -k --user 0
#   (o APK continua na TV; desfaz com cmd package install-existing)
source "$(dirname "$0")/comum.sh"
LISTA="${1:?Informe o arquivo de lista}"

for p in $(pacotes "$LISTA"); do
  if ! tv pm path "$p" >/dev/null 2>&1; then
    echo "-- $p: não está instalado para este usuário, pulando"
    continue
  fi
  out="$(tv pm disable-user --user 0 "$p" 2>&1 || true)"
  if grep -q "disabled-user" <<<"$out"; then
    echo "OK $p: desativado"
  else
    out2="$(tv pm uninstall -k --user 0 "$p" 2>&1 || true)"
    echo "OK $p: desinstalado só para o usuário 0 ($out2)"
  fi
  tv am force-stop "$p" >/dev/null 2>&1 || true
done
