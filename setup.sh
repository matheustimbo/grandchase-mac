#!/bin/zsh
# setup.sh — aplica o fix do Themida ("Wrong DLL present") numa bottle CrossOver
# que já tem a Steam + GrandChase instalados e logados.
#
# O que faz:
#  1. força os runtimes do Visual C++ a carregarem as versões GENUÍNAS (native)
#     em vez das builtin do Wine — é isso que o anti-tamper Themida exige.
#  2. configura um virtual desktop só pro GrandChase, pra alt-tab não congelar
#     o jogo (perda/recuperação do device D3D9 ao trocar de foco).
# NÃO mexe em d3d9 (o renderer nativo D3DMetal do CrossOver é o que funciona).
#
# Uso: ./setup.sh [NOME_DA_BOTTLE]   (default: Steam)

set -e
CX="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver"
BOTTLE="${1:-Steam}"
BPATH="$HOME/Library/Application Support/CrossOver/Bottles/$BOTTLE"

# Resolução do virtual desktop — CASE com a resolução que você escolher DENTRO
# do jogo (Opções), senão dá borda ou corte. Default = nativa do jogo (4:3).
VDESKTOP_RES="${VDESKTOP_RES:-1024x768}"

[ -d "$CX" ] || { echo "CrossOver não encontrado em $CX"; exit 1; }
[ -d "$BPATH" ] || { echo "Bottle '$BOTTLE' não encontrada em $BPATH"; exit 1; }

echo "==> Garantindo runtimes genuínos do VC++ na bottle (vcrun2022)…"
echo "    (se já instalados, o CrossOver/winetricks pula)"
# Os arquivos genuínos normalmente já vêm com o GrandChasePrerequisiteInstaller.
# Se faltarem, instale o 'Microsoft Visual C++ Redistributable' pela GUI do CrossOver
# (Install Software -> nesta bottle) ou rode o GrandChasePrerequisiteInstaller.exe.

echo "==> Aplicando overrides native pros runtimes VC++ (fix do Themida)…"
REG='C:\gc_themida_fix.reg'
cat > "$BPATH/drive_c/gc_themida_fix.reg" <<'EOF'
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

"$CX/bin/cxstart" --bottle "$BOTTLE" -- regedit /S "$REG" >/dev/null 2>&1
sleep 2
rm -f "$BPATH/drive_c/gc_themida_fix.reg"

echo "==> Verificando overrides aplicados…"
"$CX/bin/cxstart" --bottle "$BOTTLE" -- reg query 'HKCU\Software\Wine\DllOverrides' 2>/dev/null \
  | grep -iE "vcruntime140|msvcp140|concrt140|d3dx9" || echo "  (não consegui ler — tente rodar o jogo mesmo assim)"

echo "==> Configurando virtual desktop pro GrandChase ($VDESKTOP_RES)…"
VREG='C:\gc_vdesktop.reg'
cat > "$BPATH/drive_c/gc_vdesktop.reg" <<EOF
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\AppDefaults\\GrandChase.exe\\Explorer]
"Desktop"="GrandChase"

[HKEY_CURRENT_USER\\Software\\Wine\\Explorer\\Desktops]
"GrandChase"="$VDESKTOP_RES"
EOF
"$CX/bin/cxstart" --bottle "$BOTTLE" -- regedit /S "$VREG" >/dev/null 2>&1
sleep 2
rm -f "$BPATH/drive_c/gc_vdesktop.reg"
echo "    (mudou a resolução no jogo? rode: VDESKTOP_RES=LARGURAxALTURA ./setup.sh)"

echo ""
echo "Pronto. Agora use ./grandchase para jogar."
