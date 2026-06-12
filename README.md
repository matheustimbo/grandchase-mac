# 🎮 GrandChase Classic no macOS (Apple Silicon)

**🇧🇷 Português** · [🇺🇸 English](README.en.md)

Rodar o **GrandChase Classic** (Steam, app `985810`) num Mac M1/M2/M3 — **100% grátis, sem CrossOver**.

Verificado: **MacBook Pro M1 Max, macOS 27**, junho/2026 — entra no lobby e joga.

> **Por que é difícil:** o GrandChase é só Windows, protegido pelo anti-tamper **Themida**
> e renderizado em **Direct3D 9**. Rodar no Mac exige uma pilha de tradução
> (Wine → DXVK → MoltenVK → Metal) **e a combinação exata** de versões. Trocar qualquer
> peça quebra de um jeito diferente. Este repo documenta a combinação que funciona e dá um
> comando `grandchase` pra abrir o jogo.

---

## A pilha que funciona

| Camada | Componente | Papel |
|---|---|---|
| Wine | **wine-proton 10** | "new wow64" → roda 32-bit no macOS 27 **e** renderiza o login da Steam (CEF) |
| DirectX → Vulkan | **DXVK 2.7** | traduz o D3D9 do jogo |
| Vulkan → Metal | **MoltenVK v1.4.1** | precisa ser o **par moderno** com o DXVK 2.7 |
| Anti-tamper | runtimes **VC++ genuínos** + overrides `native` | passa o "Wrong DLL present" do Themida |
| Render | `dxvk.conf`: `d3d9.floatEmulation = Strict` | corrige cálculo de vértice |

**A combinação importa.** DXVK 2.7 **+** MoltenVK **1.4.1** é o par que funciona. Veja
[becos sem saída](#-becos-sem-saída-pra-não-perder-tempo) pro que NÃO funciona.

---

## Pré-requisitos

- Mac **Apple Silicon** + **Rosetta 2** (`softwareupdate --install-rosetta --agree-to-license`)
- Conta **Steam** com o **GrandChase** na biblioteca
- Os 3 componentes livres: **wine-proton 10**, **DXVK 2.7**, **MoltenVK v1.4.1**

### De onde vêm os componentes

A forma mais fácil de obter wine-proton e MoltenVK é pelo **[GameHub](https://www.gamehubapp.com/)**
(grátis), que os baixa — depois eles rodam **fora** dele. O DXVK 2.7 pode ser compilado do
[fonte do DXVK](https://github.com/doitsujin/dxvk) (ou do fonte LGPL do CrossOver). Coloque tudo em `~/Games/`:

```
~/Games/wine-proton/          # wine-proton 10 (bin/, lib/)
~/Games/dxvk27/wine/          # DXVK 2.7 (x86_64-windows/{d3d9,d3d11,dxgi}.dll)
~/Games/mvk141/libMoltenVK.dylib
~/Games/gc-proton/            # prefix Wine (criado no setup)
```

---

## Instalação

```sh
git clone https://github.com/matheustimbo/grandchase-mac.git
cd grandchase-mac
chmod +x grandchase setup.sh

# 1. Crie o prefix e instale a Steam + GrandChase nele (via wine-proton).
#    Faça login na Steam (a janela renderiza) e instale o jogo.

# 2. Aplique o fix do Themida (runtimes VC++ genuínos como 'native') + dxvk.conf:
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
A 1ª abertura demora (compila shaders).

---

## 🩹 Troubleshooting

| Sintoma | Causa | Solução |
|---|---|---|
| `Wrong DLL present` (Themida) | runtimes VC++ builtin do Wine | runtimes **genuínos** + overrides `native` (faz `setup.sh`) |
| Login da Steam não renderiza | webhelper CEF no Wine errado | use **wine-proton** (renderiza o CEF) |
| **Personagens 3D / cursor invisíveis** | par DXVK×MoltenVK errado | **DXVK 2.7 + MoltenVK 1.4.1** (par moderno) |
| `Install DirectX...` | device do DXVK não cria | MoltenVK incompatível com o DXVK — use o par certo |
| Trava em `UnEnter` ao abrir o `.exe` direto | falta o ambiente da Steam | lance via `-applaunch 985810` (o launcher já faz) |
| **Engasga ao entrar em cena nova** | DXVK compilando shader (síncrono) | normal; o cache (`.dxvk-cache`) faz **não repetir** — pré-aqueça jogando seus modos 1× |
| Trava ~1min no alt-tab e desconecta | perda de device D3D9 + timeout do servidor | inerente; minimize o tempo em segundo plano |

### Sobre os engasgos de shader
O Metal/MoltenVK **não suporta** a compilação assíncrona (Graphics Pipeline Library), então a
**primeira** visita a cada cena tem um engasgo enquanto o DXVK compila. O `dxvk.conf` já liga o
**cache em disco** (`enableStateCache`) — então cada cena compila **uma vez na vida** e nunca mais
trava ali, mesmo após reiniciar. Jogue seus modos uma vez pra "pré-aquecer" e fica liso.

---

## 🚧 Becos sem saída (pra não perder tempo)

- **wine puro / build mínimo do fonte CrossOver** → o webhelper CEF da Steam não renderiza (não loga).
- **GPTK 7.7 / WhiskyWine** → 32-bit não funciona no macOS 27.
- **CrossOver 24 (Sikarugir)** → 32-bit OK, mas janela CEF da Steam fica 0×0.
- **dxvk-1.10.3 + MoltenVK 1.2.1** → 4 shaders não compilam → personagens invisíveis.
- **dxvk-1.10.3 + MoltenVK 1.4.x** → falha ao criar o device ("Install DirectX").
- **MoltenVK com features "fingidas"** (geometryShader etc. forçados) → render errado.
- **`d3d9` NÃO é o gatilho do Themida** — é o runtime VC++. Trocar d3d9 não resolve o "Wrong DLL".
- **Lançar `GrandChase.exe` direto** → trava esperando o ambiente da Steam; use `-applaunch`.

---

## 💸 Alternativa: CrossOver (pago / trial)

Antes de achar a pilha grátis, o caminho que funcionou foi o **CrossOver** (trial de 14 dias).
Lá o render usa o **D3DMetal nativo** (wined3d → Metal), não DXVK. Resumo:
bottle CrossOver + runtimes VC++ genuínos (Themida) + renderer nativo + `-applaunch`.
O `setup.sh` aplica os overrides do Themida tanto numa bottle CrossOver quanto no prefix wine-proton.

Funciona, mas o **wine-proton grátis acima é o caminho recomendado**.

---

## Créditos

Construído sobre projetos open-source: [Wine](https://www.winehq.org/)/[Proton](https://github.com/ValveSoftware/Proton),
[DXVK](https://github.com/doitsujin/dxvk), [MoltenVK](https://github.com/KhronosGroup/MoltenVK).
Componentes obtidos via [GameHub](https://www.gamehubapp.com/). Themida © Oreans.

> Não afiliado à KOG / Playpark / Valve. Rode jogos da **sua própria conta**.
> Este repo só documenta configuração de compatibilidade — não distribui o jogo nem burla DRM.

## Licença

[MIT](LICENSE) — para os scripts e a documentação deste repositório.
