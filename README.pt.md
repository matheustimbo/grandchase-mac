# 🎮 GrandChase Classic no macOS (Apple Silicon)

![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white) ![macOS 27](https://img.shields.io/badge/macOS%2027-verified-success) ![Free](https://img.shields.io/badge/100%25%20free-no%20CrossOver-brightgreen) ![Stack](https://img.shields.io/badge/stack-wine--proton%20(wined3d%20%E2%86%92%20OpenGL%20%E2%86%92%20Metal)-8A2BE2) ![License](https://img.shields.io/badge/license-MIT-blue)

**🇧🇷 Português** · [🇺🇸 English](README.md)

Rodar o **GrandChase Classic** (Steam, app `985810`) num Mac M1/M2/M3 — **100% grátis, sem CrossOver**.

Verificado: **MacBook Pro M1 Max, macOS 27**, junho/2026 — entra no lobby e renderiza 3D.

> **Por que é difícil:** o GrandChase é só Windows, protegido pelo anti-tamper **Themida**
> e renderizado em **Direct3D 9**. Rodar no Mac exige um Wine que rode o app e renderize o login
> da Steam, além de passar pelo Themida. Este repo documenta o setup que funciona e dá um comando
> `grandchase` pra abrir o jogo.

---

## A pilha que funciona

| Camada | Componente | Papel |
|---|---|---|
| Tudo | **wine-proton 10** | "new wow64" roda o app no macOS 27, renderiza o login CEF da Steam **e traz o wined3d** — que renderiza o D3D9 do jogo via OpenGL → Metal. Já vem com o próprio MoltenVK e o caminho GL→Metal. |
| Anti-tamper | runtimes **VC++ genuínos** + overrides `native` | passa o "Wrong DLL present" do Themida |
| Lançar | Steam `-applaunch 985810` | o jogo precisa do ambiente que a Steam injeta |

**Caminho do render** (confirmado por `vmmap` no jogo rodando):
**GrandChase (D3D9) → wined3d → OpenGL → GL-sobre-Metal da Apple → Metal.**

O único componente externo que você precisa trazer é o **wine-proton** — ele contém tudo de gráfico.
**Não há DXVK nem override de MoltenVK** na jogada; veja [becos sem saída](#-becos-sem-saída-pra-não-perder-tempo)
pra entender por que versões anteriores deste guia achavam o contrário.

---

## Pré-requisitos

- Mac **Apple Silicon** + **Rosetta 2** (`softwareupdate --install-rosetta --agree-to-license`)
- Conta **Steam** com o **GrandChase** na biblioteca
- **wine-proton 10** — a única peça externa

### De onde vem o wine-proton

A forma mais fácil é pelo **[GameHub](https://www.gamehubapp.com/)** (grátis), que o baixa — depois
ele roda **fora** do GameHub. Coloque em `~/Games/`:

```
~/Games/wine-proton/   # wine-proton 10 (bin/, lib/) — traz wined3d + MoltenVK + o caminho GL→Metal
~/Games/gc-proton/     # prefix Wine (Steam + GrandChase + fix do Themida), criado no setup
```

---

## Instalação

```sh
git clone https://github.com/matheustimbo/grandchase-mac.git
cd grandchase-mac
chmod +x grandchase setup.sh

# 1. Crie o prefix e instale a Steam + GrandChase nele (via wine-proton).
#    Faça login na Steam (a janela renderiza) e instale o jogo.

# 2. Aplique o fix do Themida (runtimes VC++ genuínos como 'native'):
./setup.sh ~/Games/gc-proton

# 3. Instale o comando:
cp grandchase /opt/homebrew/bin/
```

O env exato de launch está em **[`RECIPE-FREE.txt`](RECIPE-FREE.txt)**.

---

## Como jogar

```sh
grandchase          # sobe a Steam (login) e abre o jogo
grandchase steam    # abre só a Steam (login / biblioteca)
grandchase kill     # fecha tudo
```

Sequência de boot: `UnEnter` → `Loading 1..16` → loading visível → lobby (`State 15`).

---

## 🩹 Troubleshooting

| Sintoma | Causa | Solução |
|---|---|---|
| `Wrong DLL present` (Themida) | runtimes VC++ builtin do Wine | runtimes **genuínos** + overrides `native` (faz `setup.sh`) |
| Login da Steam não renderiza | webhelper CEF no Wine errado | use **wine-proton** (renderiza o CEF) |
| Trava em `UnEnter` ao abrir o `.exe` direto | falta o ambiente da Steam | lance via `-applaunch 985810` (o launcher já faz) |
| Steam desloga com `Session Replaced` | a conta logou em outro lugar | feche a Steam nos outros dispositivos e relance |
| **Engasga ao entrar em cena nova** | wined3d compilando shader on-the-fly (síncrono) | inerente — o wined3d **não** persiste shader em disco, então cenas/sessões novas podem engasgar 1×. Baixar efeitos no jogo ajuda. |
| Trava ~1min no alt-tab e desconecta | perda de device D3D9 + timeout do servidor | inerente; minimize o tempo em segundo plano |

---

## 🚧 Becos sem saída (pra não perder tempo)

- **DXVK + um "par casado" específico de MoltenVK — parece necessário, não é.** Versões anteriores
  deste guia diziam que um par "DXVK 2.7 + MoltenVK 1.4.1" era o que renderizava o 3D. A inspeção do
  jogo rodando (`vmmap`) provou que é falso: o processo carrega o **wined3d builtin** do wine-proton
  e **nunca o DXVK**, e um A/B removendo o override de MoltenVK 1.4.1 renderizou **igualzinho** com o
  MoltenVK embutido do wine-proton. A pasta `dxvk27` / `dxvk.conf` / `WINEDLLPATH` nunca chegaram a
  ativar — sem override `native` pro `d3d9`, o wined3d builtin sempre vence. Nada disso era load-bearing.
- **wine puro / build mínimo do fonte CrossOver** → o webhelper CEF da Steam não renderiza (não loga).
- **GPTK 7.7 / WhiskyWine** → 32-bit não funciona no macOS 27.
- **CrossOver 24 (Sikarugir)** → 32-bit OK, mas janela CEF da Steam fica 0×0.
- **`d3d9` NÃO é o gatilho do Themida** — é o runtime VC++. Trocar d3d9 não resolve o "Wrong DLL".
- **Lançar `GrandChase.exe` direto** → trava esperando o ambiente da Steam; use `-applaunch`.

---

## 💸 Alternativa: CrossOver (pago / trial)

Antes de achar o caminho grátis do wine-proton, a primeira coisa que funcionou foi o **CrossOver**
(trial de 14 dias): bottle CrossOver + runtimes VC++ genuínos (Themida) + renderer nativo + `-applaunch`.
O `setup.sh` aplica os overrides do Themida tanto numa bottle CrossOver quanto no prefix wine-proton.

Funciona, mas o **wine-proton grátis acima é o caminho recomendado**.

---

## Créditos

Construído sobre projetos open-source: [Wine](https://www.winehq.org/)/[Proton](https://github.com/ValveSoftware/Proton),
[wined3d](https://www.winehq.org/), [MoltenVK](https://github.com/KhronosGroup/MoltenVK).
O wine-proton é obtido via [GameHub](https://www.gamehubapp.com/). Themida © Oreans.

> Não afiliado à KOG / Playpark / Valve. Rode jogos da **sua própria conta**.
> Este repo só documenta configuração de compatibilidade — não distribui o jogo nem burla DRM.

## Licença

[MIT](LICENSE) — para os scripts e a documentação deste repositório.
