# 🎮 GrandChase Classic on macOS (Apple Silicon)

[🇧🇷 Português](README.md) · **🇺🇸 English**

Run **GrandChase Classic** (Steam, app `985810`) on an M1/M2/M3 Mac — **100% free, no CrossOver**.

Verified: **MacBook Pro M1 Max, macOS 27**, June 2026 — reaches the lobby and plays.

> **Why it's hard:** GrandChase is Windows-only, protected by the **Themida** anti-tamper,
> and rendered in **Direct3D 9**. Running it on a Mac needs a translation stack
> (Wine → DXVK → MoltenVK → Metal) **and the exact combination** of versions. Swapping any
> piece breaks it in a different way. This repo documents the combo that works and ships a
> `grandchase` command to launch the game.

---

## The stack that works

| Layer | Component | Role |
|---|---|---|
| Wine | **wine-proton 10** | "new wow64" → runs 32-bit on macOS 27 **and** renders the Steam login (CEF) |
| DirectX → Vulkan | **DXVK 2.7** | translates the game's D3D9 |
| Vulkan → Metal | **MoltenVK v1.4.1** | must be the **modern pair** with DXVK 2.7 |
| Anti-tamper | genuine **VC++ runtimes** + `native` overrides | gets past Themida's "Wrong DLL present" |
| Render | `dxvk.conf`: `d3d9.floatEmulation = Strict` | fixes vertex math |

**The combination matters.** DXVK 2.7 **+** MoltenVK **1.4.1** is the pair that works. See
[dead ends](#-dead-ends-to-save-you-time) for what does NOT.

---

## Prerequisites

- **Apple Silicon** Mac + **Rosetta 2** (`softwareupdate --install-rosetta --agree-to-license`)
- A **Steam** account with **GrandChase** in your library
- The 3 free components: **wine-proton 10**, **DXVK 2.7**, **MoltenVK v1.4.1**

### Where the components come from

The easiest way to get wine-proton and MoltenVK is via **[GameHub](https://www.gamehubapp.com/)**
(free), which downloads them — then they run **outside** of it. DXVK 2.7 can be built from the
[DXVK source](https://github.com/doitsujin/dxvk) (or the CrossOver LGPL source). Place everything under `~/Games/`:

```
~/Games/wine-proton/          # wine-proton 10 (bin/, lib/)
~/Games/dxvk27/wine/          # DXVK 2.7 (x86_64-windows/{d3d9,d3d11,dxgi}.dll)
~/Games/mvk141/libMoltenVK.dylib
~/Games/gc-proton/            # Wine prefix (created during setup)
```

---

## Install

```sh
git clone https://github.com/matheustimbo/grandchase-mac.git
cd grandchase-mac
chmod +x grandchase setup.sh

# 1. Create the prefix and install Steam + GrandChase into it (via wine-proton).
#    Log into Steam (the window renders) and install the game.

# 2. Apply the Themida fix (genuine VC++ runtimes as 'native') + dxvk.conf:
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
The first launch is slow (compiling shaders).

---

## 🩹 Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Wrong DLL present` (Themida) | Wine's builtin VC++ runtimes | **genuine** runtimes + `native` overrides (done by `setup.sh`) |
| Steam login won't render | wrong Wine for the CEF webhelper | use **wine-proton** (it renders CEF) |
| **Invisible 3D characters / cursor** | wrong DXVK×MoltenVK pair | **DXVK 2.7 + MoltenVK 1.4.1** (modern pair) |
| `Install DirectX...` | DXVK can't create the device | MoltenVK incompatible with that DXVK — use the right pair |
| Hangs at `UnEnter` when launching the `.exe` directly | missing Steam launch env | launch via `-applaunch 985810` (the launcher does this) |
| **Stutters when entering a new scene** | DXVK compiling shaders (synchronous) | normal; the cache (`.dxvk-cache`) makes it **not repeat** — pre-warm by playing your modes once |
| ~1min freeze on alt-tab, then disconnect | D3D9 device loss + server timeout | inherent; minimize time in the background |

### About shader stutter
Metal/MoltenVK does **not** support asynchronous pipeline compilation (Graphics Pipeline
Library), so the **first** visit to each scene stutters while DXVK compiles. `dxvk.conf` enables
the **on-disk cache** (`enableStateCache`), so each scene compiles **once ever** and never stutters
there again, even after a restart. Play through your modes once to "pre-warm" and it's smooth.

---

## 🚧 Dead ends (to save you time)

- **plain wine / minimal CrossOver-source build** → Steam's CEF webhelper won't render (can't log in).
- **GPTK 7.7 / WhiskyWine** → 32-bit doesn't work on macOS 27.
- **CrossOver 24 (Sikarugir)** → 32-bit OK, but the Steam CEF window is 0×0.
- **dxvk-1.10.3 + MoltenVK 1.2.1** → 4 shaders fail to compile → invisible characters.
- **dxvk-1.10.3 + MoltenVK 1.4.x** → device creation fails ("Install DirectX").
- **MoltenVK with "faked" features** (forced geometryShader etc.) → wrong rendering.
- **`d3d9` is NOT the Themida trigger** — the VC++ runtime is. Swapping d3d9 won't fix "Wrong DLL".
- **Launching `GrandChase.exe` directly** → hangs waiting for the Steam env; use `-applaunch`.

---

## 💸 Alternative: CrossOver (paid / trial)

Before finding the free stack, the path that worked was **CrossOver** (14-day trial). There the
renderer uses native **D3DMetal** (wined3d → Metal), not DXVK. Summary: CrossOver bottle + genuine
VC++ runtimes (Themida) + native renderer + `-applaunch`. `setup.sh` applies the Themida overrides
to either a CrossOver bottle or the wine-proton prefix.

It works, but the **free wine-proton path above is the recommended one**.

---

## Credits

Built on open-source projects: [Wine](https://www.winehq.org/)/[Proton](https://github.com/ValveSoftware/Proton),
[DXVK](https://github.com/doitsujin/dxvk), [MoltenVK](https://github.com/KhronosGroup/MoltenVK).
Components obtained via [GameHub](https://www.gamehubapp.com/). Themida © Oreans.

> Not affiliated with KOG / Playpark / Valve. Run games from **your own account**.
> This repo only documents compatibility configuration — it does not distribute the game or bypass DRM.

## License

[MIT](LICENSE) — for the scripts and documentation in this repository.
