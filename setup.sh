#!/bin/zsh
# setup.sh — aplica o fix do Themida num prefix Wine que já tem a Steam + GrandChase
# instalados (caminho grátis: wine-proton).
#
# O que faz:
#   Overrides 'native' pros runtimes VC++ -> passa o "Wrong DLL present" do Themida.
#   (o Themida rejeita os runtimes builtin do Wine; precisa dos genuínos da Microsoft,
#    normalmente já instalados pelo GrandChasePrerequisiteInstaller na 1ª execução.)
#   O gatilho do Themida é o runtime VC++, NÃO o d3d9.
#
# Uso: ./setup.sh [PREFIX]      (default: ~/Games/gc-proton)
#
# Também funciona numa bottle do CrossOver: passe o caminho da bottle como PREFIX
# e ajuste WINE abaixo para o wine do CrossOver.

set -e
PREFIX="${1:-$HOME/Games/gc-proton}"
WINE="${WINE:-$HOME/Games/wine-proton/bin/wine}"

[ -d "$PREFIX" ] || { echo "Prefix não encontrado: $PREFIX"; exit 1; }
[ -x "$WINE" ]   || { echo "Wine não encontrado: $WINE (defina WINE=...)"; exit 1; }

echo "==> Aplicando overrides 'native' dos runtimes VC++ (fix do Themida)…"
cat > "$PREFIX/drive_c/gc_themida_fix.reg" <<'EOF'
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"*vcruntime140"="native,builtin"
"*vcruntime140_1"="native,builtin"
"*msvcp140"="native,builtin"
"*msvcp140_1"="native,builtin"
"*msvcp140_2"="native,builtin"
"*msvcp140_atomic_wait"="native,builtin"
"*msvcp140_codecvt_ids"="native,builtin"
"*concrt140"="native,builtin"
"*vcamp140"="native,builtin"
"*vccorlib140"="native,builtin"
"*vcomp140"="native,builtin"
"*d3dx9_42"="native"
"*d3dx9_43"="native"
EOF
WINEPREFIX="$PREFIX" WINEDEBUG=-all "$WINE" regedit /S 'C:\gc_themida_fix.reg' >/dev/null 2>&1 || true
sleep 2
rm -f "$PREFIX/drive_c/gc_themida_fix.reg"

echo ""
echo "Pronto. Use ./grandchase para jogar."
