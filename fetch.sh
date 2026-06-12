#!/bin/zsh
# fetch.sh — baixa os 2 componentes de versão FIXA (o "par casado") direto do upstream:
#   • DXVK 2.7       (doitsujin/dxvk)        -> ~/Games/dxvk27/wine/x86_64-windows/{d3d9,d3d11,dxgi}.dll
#   • MoltenVK 1.4.1 (KhronosGroup/MoltenVK) -> ~/Games/mvk141/libMoltenVK.dylib
#
# Por que pinado: o par DXVK 2.7 + MoltenVK 1.4.1 é o que renderiza o jogo. Pegar do
# GameHub é loteria de versão (foi o que quebrou o setup uma vez). Aqui é determinístico.
#
# NÃO baixa o wine-proton (2.1G) — esse vem do GameHub/Proton (ver README).
#
# Uso: ./fetch.sh
#   GAMES=/outro/dir ./fetch.sh   -> instala noutro lugar (default: ~/Games)
#   FORCE=1 ./fetch.sh            -> sobrescreve sem backup
#   SKIP_EXISTING=1 ./fetch.sh    -> não toca no que já existe
# Por padrão, se um alvo já existe ele é preservado em <alvo>.bak-<timestamp>.

set -euo pipefail

GAMES="${GAMES:-$HOME/Games}"
DXVK_VER="2.7"
MVK_VER="1.4.1"
DXVK_URL="https://github.com/doitsujin/dxvk/releases/download/v${DXVK_VER}/dxvk-${DXVK_VER}.tar.gz"
MVK_URL="https://github.com/KhronosGroup/MoltenVK/releases/download/v${MVK_VER}/MoltenVK-macos.tar"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
ts="$(date +%Y%m%d-%H%M%S)"

# devolve 0 = pode escrever no alvo; 1 = pular
backup() {
  [ -e "$1" ] || return 0
  if [ "${SKIP_EXISTING:-0}" = "1" ]; then echo "   já existe, pulando: $1"; return 1; fi
  if [ "${FORCE:-0}" = "1" ]; then rm -rf "$1"; return 0; fi
  echo "   backup -> $(basename "$1").bak-$ts"; mv "$1" "$1.bak-$ts"; return 0
}

echo "==> DXVK ${DXVK_VER} (d3d9/d3d11/dxgi 64-bit) — $DXVK_URL"
curl -fL --retry 3 "$DXVK_URL" -o "$tmp/dxvk.tar.gz"
tar -xzf "$tmp/dxvk.tar.gz" -C "$tmp"
dxvk_dest="$GAMES/dxvk27/wine/x86_64-windows"
mkdir -p "$dxvk_dest"
for dll in d3d9 d3d11 dxgi; do
  src="$tmp/dxvk-${DXVK_VER}/x64/$dll.dll"
  [ -f "$src" ] || { echo "ERRO: $src não veio no tarball"; exit 1; }
  if backup "$dxvk_dest/$dll.dll"; then
    cp "$src" "$dxvk_dest/$dll.dll"; echo "   ok: $dll.dll"
  fi
done

echo "==> MoltenVK ${MVK_VER} (libMoltenVK.dylib universal) — $MVK_URL"
curl -fL --retry 3 "$MVK_URL" -o "$tmp/mvk.tar"
tar -xf "$tmp/mvk.tar" -C "$tmp"
mvk_src="$(find "$tmp" -path '*/dylib/macOS/libMoltenVK.dylib' -type f | head -1)"
[ -n "$mvk_src" ] || { echo "ERRO: libMoltenVK.dylib não encontrado no tar"; exit 1; }
mvk_dest="$GAMES/mvk141"
mkdir -p "$mvk_dest"
if backup "$mvk_dest/libMoltenVK.dylib"; then
  cp "$mvk_src" "$mvk_dest/libMoltenVK.dylib"; echo "   ok: libMoltenVK.dylib"
fi

echo ""
echo "Pronto: DXVK ${DXVK_VER} + MoltenVK ${MVK_VER} instalados em $GAMES/."
echo "Ainda falta o wine-proton (2.1G) — veja 'Where the components come from' no README."
echo "Depois: ./setup.sh (fix do Themida + dxvk.conf) e cp grandchase /opt/homebrew/bin/."
