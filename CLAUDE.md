# CLAUDE.md — guia operacional pra agentes (não é o README)

Contexto pra um Claude que for mexer/reconstruir este setup. O **README.md** é pra
humano (instalar e jogar). Este arquivo é o que te impede de refazer ~6h de
investigação. Leia inteiro antes de propor qualquer mudança.

**Objetivo:** rodar GrandChase Classic (Steam app `985810`) no macOS Apple Silicon.
**Status:** FUNCIONA — joga no lobby. Verificado 2026-06-11, M1 Max, macOS 27.

**CAMINHO PRINCIPAL = GRÁTIS (sem CrossOver):** wine-proton 10 + **DXVK 2.7 + MoltenVK
v1.4.1** (par casado) + runtimes VC++ genuínos (Themida) + `dxvk.conf` floatEmulation.
Componentes em `~/Games/` (wine-proton, dxvk27, mvk141, prefix gc-proton). Env exato em
`RECIPE-FREE.txt`. Launcher `grandchase` lança via `-applaunch 985810`. NÃO trocar o par
DXVK 2.7 / MoltenVK 1.4.1 (outras combinações → invisível ou device-fail; ver becos abaixo).
A seção CrossOver abaixo é a alternativa paga (foi o 1º caminho que funcionou).

**Como obter os componentes:** `./fetch.sh` baixa o **par casado** em versão FIXA do upstream —
DXVK 2.7 (doitsujin/dxvk, dir `x64` → `~/Games/dxvk27/wine/x86_64-windows/`) e MoltenVK 1.4.1
(KhronosGroup, asset `MoltenVK-macos.tar`, **NÃO** o `-privateapi` → beco) em `~/Games/mvk141/`. O
wine-proton (2.1G) NÃO é baixado pelo script (vem do GameHub). CAVEAT: o DXVK que o autor validou
foi compilado do fonte LGPL do CrossOver; o `fetch.sh` instala o release upstream do **mesmo 2.7**
(builds diferentes — não byte-iguais — mas mesma versão). Se o render quebrar com o upstream,
compilar o 2.7 do fonte é o plano B.

---

## A receita que funciona (resumo; passos humanos no README)

Vehículo = **bottle do CrossOver** (`~/Library/Application Support/CrossOver/Bottles/Steam`).
Tudo via `"$CX/bin/cxstart" --bottle Steam ...`, onde
`CX=/Applications/CrossOver.app/Contents/SharedSupport/CrossOver`.

1. **Themida ("Wrong DLL present")** → overrides `native,builtin` dos runtimes VC++
   no registro (`HKCU\Software\Wine\DllOverrides`). É isso que `setup.sh` aplica.
   O gatilho do Themida é o **runtime VC++**, NÃO o d3d9.
2. **Login da Steam** → a bottle do CrossOver loga (webhelper CEF do CrossOver
   renderiza). Reusa a sessão salva.
3. **Render** → renderer **nativo do CrossOver** (d3d9 = wined3d, que importa só
   `wined3d.dll`). NÃO usar DXVK.
4. **Lançar** → `Steam.exe -applaunch 985810` (NUNCA o exe direto).

---

## BECOS SEM SAÍDA — não repita (com o porquê)

- **DXVK (qualquer versão) pro d3d9** → passa o Themida mas dá **TELA PRETA**:
  7 shaders do jogo dão `Failed to compile pipeline` no log do DXVK. O d3d9 do jogo
  é DX9 puro; use **wined3d** (o nativo do CrossOver), que renderiza certo.
- **Compilar Wine do fonte do CrossOver (nosso `wine-cx`)** → o webhelper CEF da
  Steam não renderiza nele → **não dá pra logar**. Fique na bottle do CrossOver.
- **MoltenVK custom patchado** (geometryShader etc.) → trava em `InitDeviceObjects`.
- **Lançar `GrandChase.exe` direto** → trava em `NtWaitForSingleObject` (espera o
  ambiente que a Steam injeta: SteamAppId, pipe, overlay). Sempre `-applaunch`.
- **Trocar o d3d9 pra "consertar" o Themida** → inútil. d3d9 (DXVK/wined3d) não é o
  gatilho; o runtime VC++ builtin é. Instale os VC++ genuínos + override `native`.
- **`CX_GRAPHICS_BACKEND=dxvk` / `WINEDXVK=1` na bottle** → leva ao DXVK = preto.
  Deixe o default (D3DMetal/wined3d nativo).

Se for tentado a reconstruir o stack em `~/Games/` (wine-cx, MoltenVK, DXVK
compilados): **não é o caminho.** Foi como aprendemos as peças, mas a solução é a
bottle CrossOver + os 4 itens acima.

---

## Playbook de debug (como verificar uma mudança)

- **Estado do jogo:** `GameLog.txt` na pasta do jogo
  (`.../steamapps/common/GrandChase/GameLog.txt`). Sequência boa: `UnEnter` →
  `Loading 1..16` → `State 25` (intro, vídeo .avi = preto mas avança) → `State 14`
  → loading visível → `State 15` + `EnterChannel` (= lobby). Lacuna de tempo no log
  = freeze (ex.: alt-tab).
- **Conexão com servidor:** `lsof -nP -p <PID> | grep 9501` — ESTABLISHED = conectado.
- **CPU:** `ps -o %cpu= -p <PID>`. ~0% + `NtWaitForSingleObject` = travado esperando;
  alto = renderizando.
- **Themida passou?** Se aparece a janela "Themida / Wrong DLL present" (modal),
  não passou. Se chega no `GameLog` com `Loading N` de hoje, passou.
- **`cxstart` NÃO repassa `WINEDEBUG`** pro stdout. Pra log do wine, use
  `CX_LOG`/`CX_DEBUGMSG` como env de SHELL antes do cxstart, ou `--cx-log FILE`.
- **Achar a janela do jogo:** é uma janela nativa 1024x768 (ou a res do virtual
  desktop). `screencapture` e leitura de janelas via osascript exigem permissão de
  Gravação de Tela/Acessibilidade — normalmente bloqueadas; peça print ao usuário.

## Gotchas de ambiente

- **Sandbox bloqueia escrita em `/Applications/CrossOver.app`** — não dá pra trocar
  o MoltenVK lá dentro sem `dangerouslyDisableSandbox` (e mesmo assim "Operation not
  permitted" por SIP). Use override via env (`DYLD_LIBRARY_PATH`) se precisar.
- **Registro vivo vs disco:** mudanças via `regedit /S` vão pro wineserver em
  memória; só caem no `user.reg` no shutdown. Pra ler o estado real, consulte com
  `cxstart ... -- reg query` (sincrono) com a Steam rodando.
- **vcrun genuíno:** a bottle já tinha (do `GrandChasePrerequisiteInstaller.exe`).
  Em bottle nova, instale o "Microsoft Visual C++ Redistributable" antes do `setup.sh`.

---

## Reconstrução do zero (Mac formatado / outro Mac)

1. Instalar CrossOver. Criar bottle Windows 10/11 64-bit chamada `Steam`.
2. Instalar Steam na bottle; logar; instalar GrandChase (985810).
3. Rodar o `GrandChasePrerequisiteInstaller.exe` (instala VC++ genuíno) — ou
   instalar o VC++ Redistributable pela GUI do CrossOver.
4. `./setup.sh` (aplica overrides do Themida + virtual desktop).
5. `cp grandchase /opt/homebrew/bin/` e jogar com `grandchase`.

Detalhes e troubleshooting: README.md.

---

## Threads em aberto (pra não perder)

- **Migração pra grátis (sem CrossOver, trial expira):** viável. Confirmado que o
  d3d9 vencedor é **wined3d puro** (não bridge proprietário) → qualquer Wine grátis
  com wined3d renderiza o jogo. Peças grátis presentes: Whisky.app instalado,
  WhiskyWine (com D3DMetal) baixado via Wayback em `~/Games/whiskywine`, GPTK (gcenx)
  instalado. Plano: bottle no Whisky/GPTK + Steam (login via D3DMetal grátis) +
  overrides VC++ + wined3d. NÃO precisa de DXVK. Reusar os 14GB do jogo já baixado.
- **Freeze/desconexão no alt-tab:** virtual desktop por-app (`AppDefaults\GrandChase.exe`)
  reduz o freeze. Desconectar após alt-tab longo é timeout do servidor (normal em MMO).
  A res do virtual desktop tem que casar com a res escolhida no jogo.
- **Freeze ~1min DURANTE o jogo (não-alt-tab):** ao mudar de cena/modo (`State change`
  no GameLog), um core vai a 100% e volta sozinho. É **compilação de shaders D3D9→Metal
  + load de assets** da cena nova, síncrona na thread de render. wined3d NÃO persiste
  shaders em disco (o DXVK persistiria, mas DXVK = preto aqui), então pode repetir em
  cenas novas/sessão nova. Diagnóstico: CPU 100% num core + `NtWaitForSingleObject` nos
  outros + rede ESTABLISHED + recupera sozinho = compilação, não deadlock/rede.
  Mitigações parciais: csmt no wined3d (`HKCU\Software\Wine\Direct3D` "csmt"), baixar
  efeitos no jogo. Eliminar 100% é inviável (inerente à tradução D3D9→Metal on-the-fly).
