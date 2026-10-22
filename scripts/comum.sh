#!/usr/bin/env bash
# Funções comuns. Uso: TV_IP=192.168.x.y ./scripts/<script>.sh
set -euo pipefail

: "${TV_IP:?Defina o IP da TV, ex.: TV_IP=192.168.1.50 ./scripts/backup.sh}"
TV="${TV_IP}:5555"
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

adb connect "$TV" >/dev/null
if ! adb devices | grep -q "^${TV}[[:space:]]*device$"; then
  echo "TV não autorizada/conectada. Aceite o aviso 'Permitir depuração' na TV e rode de novo." >&2
  exit 1
fi

tv() { adb -s "$TV" shell "$@"; }

# Lê pacotes de uma lista, ignorando comentários e linhas vazias
pacotes() { sed 's/#.*//' "$1" | awk 'NF {print $1}'; }
