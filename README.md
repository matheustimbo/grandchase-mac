# GrandChase Classic no macOS (Apple Silicon)

Como rodar o **GrandChase Classic** (Steam, app `985810`) num Mac M-series, de graça,
via [CrossOver](https://www.codeweavers.com/crossover) / Wine — incluindo passar pela
proteção **Themida** e pela tela preta do DXVK.

Testado num **MacBook Pro M1 Max, macOS 27**, CrossOver 26.2, em junho/2026.

> Por que não é trivial: o GrandChase é só Windows, protegido por **Themida**
> (anti-tamper) e renderizado em **Direct3D 9**. Cada uma dessas camadas quebra
> de um jeito diferente sob Wine. Este repo documenta a combinação que funciona.

---

## TL;DR — as 4 peças que destravam o jogo

| Muro | Sintoma | Solução |
|------|---------|---------|
| **Themida** | `An error has occurred while loading imports. Wrong DLL present.` | Forçar os runtimes do **Visual C++ genuínos** (override `native`) — o Themida rejeita os builtin do Wine. **NÃO é o d3d9.** |
| **Login da Steam** | UI da Steam preta / "SteamWebHelper não está respondendo" | Usar a **bottle do CrossOver** (o webhelper dele renderiza e loga). |
| **Tela preta no jogo** | Janela 1024×768 preta, mas o processo renderiza (CPU alto) | Usar o **renderer nativo D3DMetal do CrossOver, NÃO o DXVK** (o DXVK falha ao compilar 7 shaders do jogo → preto). |
| **Trava no loading** | Fica em `NtWaitForSingleObject`, 0% CPU | Lançar **pela Steam** (`-applaunch 985810`), não o `.exe` direto. |

---

## Pré-requisitos

1. **CrossOver** instalado (tem trial de 14 dias; o engine é LGPL).
2. Uma **bottle** (Windows 10/11 64-bit) com:
   - **Steam** instalada e **logada** na sua conta;
   - **GrandChase** instalado pela Steam;
   - os **runtimes do Visual C++** genuínos (normalmente o
     `GrandChasePrerequisiteInstaller.exe` já instala; senão, instale o
     "Microsoft Visual C++ Redistributable" pela GUI do CrossOver nessa bottle).

A bottle padrão usada pelos scripts se chama `Steam`. Ajuste se a sua tiver outro nome.

---

## Setup

```sh
git clone https://github.com/matheustimbo/grandchase-mac.git
cd grandchase-mac
chmod +x grandchase setup.sh

# aplica o fix do Themida (overrides native dos runtimes VC++) na bottle
./setup.sh            # ou ./setup.sh NomeDaSuaBottle

# instala o comando (opcional)
cp grandchase /opt/homebrew/bin/   # ou deixe em ./grandchase
```

## Jogar

```sh
grandchase          # sobe a Steam (login) e abre o jogo via -applaunch
grandchase steam    # abre só o cliente Steam da bottle
grandchase kill     # fecha tudo
```

Sequência de boot: `UnEnter` → `Loading 1..16` → intro (`State 25`, vídeo `.avi`
fica preto mas avança sozinho) → tela de loading **visível** → lobby. O jogo conecta
no servidor (`:9501`). A primeira abertura demora (compila shaders).

---

## Becos sem saída (pra você não perder tempo)

- **DXVK** (qualquer versão): passa o Themida, mas **tela preta** — 7 shaders do
  GrandChase dão `Failed to compile pipeline`. Use o D3DMetal nativo do CrossOver.
- **Wine "puro" / build próprio do CrossOver-source**: o webhelper (CEF) da Steam
  não renderiza → não dá pra logar. Fique na bottle do CrossOver.
- **MoltenVK custom patchado**: trava em `InitDeviceObjects`.
- **Lançar `GrandChase.exe` direto**: trava esperando o ambiente que a Steam injeta.
  Sempre via `-applaunch 985810`.
- **`d3d9` não é o gatilho do Themida** — é o runtime VC++. Trocar d3d9 (DXVK,
  wined3d) não resolve o "Wrong DLL present"; instalar os VC++ genuínos resolve.

---

## Detalhe técnico do fix do Themida

O Themida valida as DLLs importadas pelo executável. O GrandChase importa
`VCRUNTIME140`, `VCRUNTIME140_1`, `MSVCP140`, `CONCRT140` etc. Se essas resolverem
para as versões **builtin do Wine**, o Themida detecta "DLL errada" e aborta.

A correção é garantir os arquivos **genuínos** da Microsoft no `system32` da bottle
**e** dizer ao Wine para preferi-los, via overrides no registro
(`HKCU\Software\Wine\DllOverrides`, valor `native,builtin`). É isso que o `setup.sh` faz.

---

*Não afiliado à KOG / Playpark / Valve. Rode jogos da sua própria conta.*
