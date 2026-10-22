#!/usr/bin/env bash
# Baixa o Key Mapper (open source, GPL-3.0) do GitHub oficial, confere o SHA-256
# publicado pelo GitHub, instala e libera o serviço de acessibilidade dele.
# Uso: TV_IP=... ./scripts/instalar-keymapper.sh [versão, ex.: v4.6.2]
source "$(dirname "$0")/comum.sh"

REPO="keymapperorg/KeyMapper"
VERSAO="${1:-v4.6.2}"
PKG="io.github.sds100.keymapper"
SERVICO="$PKG/.system.accessibility.MyAccessibilityService"
PASTA="$RAIZ/apks"
mkdir -p "$PASTA"

read -r NOME URL DIGEST < <(curl -fsSL "https://api.github.com/repos/$REPO/releases/tags/$VERSAO" |
  python3 -c 'import sys,json
for a in json.load(sys.stdin)["assets"]:
    if a["name"].endswith("-foss.apk"):
        print(a["name"], a["browser_download_url"], (a.get("digest") or "").removeprefix("sha256:"))')

[ -n "${URL:-}" ] || { echo "APK não encontrado na release $VERSAO de $REPO" >&2; exit 1; }
curl -fL -o "$PASTA/$NOME" "$URL"
echo "$DIGEST  $PASTA/$NOME" | sha256sum -c -
adb -s "$TV" install -r "$PASTA/$NOME"

# Abre o app uma vez (o serviço de acessibilidade só ativa depois disso)
tv monkey -p "$PKG" -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1
sleep 3

# Não deixar o Android/TCL matar o serviço nem bloquear a inicialização no boot
tv dumpsys deviceidle whitelist +"$PKG" >/dev/null
tv cmd appops set "$PKG" RUN_ANY_IN_BACKGROUND allow
# [TCL] o TclAppBoot bloqueia serviços de apps sem esta permissão no boot
tv cmd appops set "$PKG" APP_AUTO_START allow 2>/dev/null || echo "(APP_AUTO_START não existe nesta TV, ok)"

# Liga o serviço de acessibilidade (desliga e liga para forçar o vínculo)
tv settings put secure enabled_accessibility_services '""'
tv settings put secure accessibility_enabled 0
sleep 3
tv settings put secure enabled_accessibility_services "$SERVICO"
tv settings put secure accessibility_enabled 1
sleep 5

if tv dumpsys accessibility | grep -q "Bound services:{Service\[label=Key Mapper"; then
  echo "Key Mapper instalado e ativo. Agora crie os mapeamentos na TV (veja o README)."
else
  echo "Serviço não ativou. Na TV: Configurações > Acessibilidade > Key Mapper > ativar." >&2
fi
