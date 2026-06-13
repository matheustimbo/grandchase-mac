# 🎮 GrandChase Classic on macOS (Apple Silicon)

![macOS](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white) ![macOS 27](https://img.shields.io/badge/macOS%2027-verified-success) ![Free](https://img.shields.io/badge/100%25%20free-no%20CrossOver-brightgreen) ![Stack](https://img.shields.io/badge/stack-wine--proton%20(wined3d%20%E2%86%92%20OpenGL%20%E2%86%92%20Metal)-8A2BE2) ![License](https://img.shields.io/badge/license-MIT-blue)

[🇧🇷 Português](README.pt.md) · **🇺🇸 English**

Run **GrandChase Classic** (Steam, app `985810`) on an M1/M2/M3 Mac — **100% free, no CrossOver**.

Verified: **MacBook Pro M1 Max, macOS 27**, June 2026 — reaches the lobby and renders 3D.

> **Why it's hard:** GrandChase is Windows-only, protected by the **Themida** anti-tamper, and
> rendered in **Direct3D 9**. Running it on a Mac needs a working Wine build (to run the app
> and render Steam's login) plus a way past Themida. This repo documents the setup that works
> and ships a `grandchase` command to launch the game.

---

## The stack that works

| Layer | Component | Role |
|---|---|---|
| Everything | **wine-proton 10** | "new wow64" runs the app on macOS 27, renders Steam's CEF login, **and provides wined3d** — which renders the game's D3D9 through OpenGL → Metal. Ships its own MoltenVK and the GL→Metal path. |
| Anti-tamper | genuine **VC++ runtimes** + `native` overrides | gets past Themida's "Wrong DLL present" |
| Launch | Steam `-applaunch 985810` | the game needs the environment Steam injects |

**Render path** (confirmed by `vmmap` on the running game):
**GrandChase (D3D9) → wined3d → OpenGL → Apple's GL-on-Metal → Metal.**

The only external component you have to bring is **wine-proton** — it contains everything graphics-related.
There is **no DXVK and no MoltenVK override** in the picture; see [dead ends](#-dead-ends-to-save-you-time)
for why earlier versions of this guide thought otherwise.

---

## Prerequisites

- **Apple Silicon** Mac + **Rosetta 2** (`softwareupdate --install-rosetta --agree-to-license`)
- A **Steam** account with **GrandChase** in your library
- **wine-proton 10** — the only external piece

### Where wine-proton comes from

The easiest way to get wine-proton is via **[GameHub](https://www.gamehubapp.com/)** (free), which
downloads it — then it runs **outside** of GameHub. Put it under `~/Games/`:

```
~/Games/wine-proton/   # wine-proton 10 (bin/, lib/) — brings wined3d + MoltenVK + the GL→Metal path
~/Games/gc-proton/     # Wine prefix (Steam + GrandChase + Themida fix), created during setup
```

---

## Install

```sh
git clone https://github.com/matheustimbo/grandchase-mac.git
cd grandchase-mac
chmod +x grandchase setup.sh

# 1. Create the prefix and install Steam + GrandChase into it (via wine-proton).
#    Log into Steam (the window renders) and install the game.

# 2. Apply the Themida fix (genuine VC++ runtimes as 'native'):
./setup.sh ~/Games/gc-proton

# 3. Install the command:
cp grandchase /opt/homebrew/bin/
```

The exact launch environment is in **[`RECIPE-FREE.txt`](RECIPE-FREE.txt)**.

---

## How to play

```sh
grandchase          # starts Steam (login) and launches the game
grandchase steam    # opens Steam only (login / library)
grandchase kill     # closes everything
```

Boot sequence: `UnEnter` → `Loading 1..16` → visible loading → lobby (`State 15`).

---

## 🩹 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Wrong DLL present` (Themida) | Wine's builtin VC++ runtimes | **genuine** runtimes + `native` overrides (done by `setup.sh`) |
| Steam login won't render | wrong Wine for the CEF webhelper | use **wine-proton** (it renders CEF) |
| Hangs at `UnEnter` when launching the `.exe` directly | missing Steam launch env | launch via `-applaunch 985810` (the launcher does this) |
| Steam logs off with `Session Replaced` | the account logged in elsewhere | close Steam on other devices, then relaunch |
| **Stutters when entering a new scene** | wined3d compiling shaders on the fly (synchronous) | inherent — wined3d does **not** persist compiled shaders to disk, so new scenes / new sessions can stutter once. Lowering in-game effects helps. |
| ~1min freeze on alt-tab, then disconnect | D3D9 device loss + server timeout | inherent; minimize time in the background |

---

## 🚧 Dead ends (to save you time)

- **DXVK + a specific MoltenVK "matched pair" — looks necessary, isn't.** Earlier versions of this
  guide claimed a "DXVK 2.7 + MoltenVK 1.4.1" pair was the thing that rendered the 3D. Runtime
  inspection of the running game (`vmmap`) proved that false: the process loads wine-proton's
  **builtin wined3d** and **never DXVK**, and an A/B with the MoltenVK 1.4.1 override removed
  rendered **identically** on wine-proton's bundled MoltenVK. The `dxvk27` folder / `dxvk.conf` /
  `WINEDLLPATH` never engaged — without a `native` override for `d3d9`, Wine's builtin wined3d
  always wins. None of it was load-bearing.
- **plain wine / minimal CrossOver-source build** → Steam's CEF webhelper won't render (can't log in).
- **GPTK 7.7 / WhiskyWine** → 32-bit doesn't work on macOS 27.
- **CrossOver 24 (Sikarugir)** → 32-bit OK, but the Steam CEF window is 0×0.
- **`d3d9` is NOT the Themida trigger** — the VC++ runtime is. Swapping d3d9 won't fix "Wrong DLL".
- **Launching `GrandChase.exe` directly** → hangs waiting for the Steam env; use `-applaunch`.

---

## 💸 Alternative: CrossOver (paid / trial)

Before finding the free wine-proton path, the first thing that worked was **CrossOver** (14-day trial):
a CrossOver bottle + genuine VC++ runtimes (Themida) + its native renderer + `-applaunch`. `setup.sh`
applies the Themida overrides to either a CrossOver bottle or the wine-proton prefix.

It works, but the **free wine-proton path above is the recommended one**.

---

## Credits

Built on open-source projects: [Wine](https://www.winehq.org/)/[Proton](https://github.com/ValveSoftware/Proton),
[wined3d](https://www.winehq.org/), [MoltenVK](https://github.com/KhronosGroup/MoltenVK).
wine-proton is obtained via [GameHub](https://www.gamehubapp.com/). Themida © Oreans.

> Not affiliated with KOG / Playpark / Valve. Run games from **your own account**.
> This repo only documents compatibility configuration — it does not distribute the game or bypass DRM.

## License

[MIT](LICENSE) — for the scripts and documentation in this repository.
