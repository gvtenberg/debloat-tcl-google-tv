#!/usr/bin/env bash
# Usa o Gboard como teclado de tela e desabilita o "teclado-ponte" do controle
# remoto pelo celular (ImeBridgeService), que esconde o teclado da TV.
# Uso:    TV_IP=... ./scripts/teclado-gboard.sh
# Desfaz: TV_IP=... ./scripts/teclado-gboard.sh reverter
source "$(dirname "$0")/comum.sh"

GBOARD="com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME"
PONTE="com.google.android.tv.remote.service/.ImeBridgeService"
TCL="com.tcl.inputmethod.international/.T_IME"

if [ "${1:-}" = "reverter" ]; then
  tv ime enable "$PONTE"
  tv ime set "$TCL"
  tv ime disable "$GBOARD"
else
  tv ime enable "$GBOARD"
  tv ime set "$GBOARD"
  tv ime disable "$PONTE"
fi
tv settings get secure default_input_method
