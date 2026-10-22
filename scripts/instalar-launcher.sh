#!/usr/bin/env bash
# Baixa o LTvLauncher (open source, GPL-3.0) do GitHub oficial, confere o SHA-256
# publicado pelo GitHub e instala na TV.
# Uso: TV_IP=... ./scripts/instalar-launcher.sh [armeabi-v7a|arm64-v8a]
#   Descubra a arquitetura com: adb shell getprop ro.product.cpu.abi
source "$(dirname "$0")/comum.sh"

REPO="leanbitlab-org/LtvLauncher"
ABI="${1:-$(tv getprop ro.product.cpu.abi | tr -d '\r')}"
PASTA="$RAIZ/apks"
mkdir -p "$PASTA"

read -r NOME URL DIGEST < <(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
  python3 -c 'import sys,json
abi=sys.argv[1]
for a in json.load(sys.stdin)["assets"]:
    if a["name"].endswith(f"-{abi}-release.apk"):
        print(a["name"], a["browser_download_url"], (a.get("digest") or "").removeprefix("sha256:"))' "$ABI")

[ -n "${URL:-}" ] || { echo "APK para $ABI não encontrado na última release de $REPO" >&2; exit 1; }
curl -fL -o "$PASTA/$NOME" "$URL"
echo "$DIGEST  $PASTA/$NOME" | sha256sum -c -

adb -s "$TV" install -r "$PASTA/$NOME"
tv cmd package set-home-activity --user 0 com.leanbitlab.ltvL/.MainActivity
echo "Instalado. Agora rode: TV_IP=$TV_IP ./scripts/debloat.sh listas/fase2-launcher.txt"
