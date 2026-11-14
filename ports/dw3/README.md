## Installing it (no tools needed)

1. Install the port with **PortMaster** on the console (Ports → PortMaster → search for "Digimon World 2003"), or unzip
   `dw3.zip` into the card's `ports/` folder by hand. On EmuELEC that folder is `/storage/roms/ports/`.
2. Put your own disc in `ports/dw3/game/`: the **`.cue` and the `.bin`**, from your own copy of the game (Europe / PAL,
   disc 1, serial `SLES-03936`). The launcher looks for the common names (`dw3`, `dw2003`, `Digimon World 2003`,
   `Digimon World 3`) and otherwise takes the first `.cue` or `.bin` it finds in `game/`. If you rename the `.bin`, edit
   the `.cue` to match. Copy the files the way you copy any ROM: card in the PC, or over the network. The `.bin` is
   about 660 MB.
3. Launch it from the **Ports** menu. A gamepad menu comes first (the port's own, driven only by the pad): the bottom
   row is **PLAY**. Settings, button remapping and the LED bar are the rows above it.

The port contains no game data. Without a disc in `game/` the launcher shows "Please copy your Digimon World 2003
.bin/.cue into ports/dw3/game/" and exits.

If the game does not start after an update, delete `settings.json` and `pad.map` in `ports/dw3/`; both are rebuilt on
the next launch.

## Notes

A source port of **Digimon World 2003** (PAL), built from the [dw2003recomp](https://github.com/gascarcella/dw2003recomp)
decompilation: the game's own C, compiled for 32-bit ARM, with the PlayStation's hardware (CPU, GTE, GPU, SPU, MDEC, CD)
reimplemented on the host. The disc is the only source of game data; nothing of the game is included here.

Two renderers ship in the binary: the software rasteriser (byte-identical to the port's reference) and a GLES one that
draws the PlayStation's VRAM on the Mali. `ports/dw3/settings.json` picks one (`"video": { "renderer": "gles" }` or
`"software"`), and so does the `RENDERER` row of the menu. GLES is faster in 3D, software is faster in menus.

How the launcher chooses:

- With no writable `/dev/fb0`, or with Wayland as the display (ROCKNIX on some devices), the framebuffer menu is skipped
  and the game starts with `settings.json` as it is.
- The launcher passes `--renderer gles` only when the CPU part is `0xd04` (Cortex-A35, the RK3326) and there is no
  `settings.json` yet. Everywhere else the default is software.
- `DW3_FORCE_VIDEO` (`fbdev` or `sdl2`) and `DW3_FORCE_RENDERER` (`gles` or `software`) override both choices.

More: [running, deploying and limits](https://github.com/al4xdev/digimon-world-3-definitive-edition/blob/main/docs/HANDHELD.md).

## What the menu offers

The menu runs before the game, is driven by the pad alone and writes `ports/dw3/settings.json` as you change it.
`Cross` enters a group or changes a value, `Circle` goes back, `Start` plays from anywhere, `Select + Start` quits. The
defaults are the setup the port was tuned with, so a player who never opens the menu gets it anyway: 8x fast-forward
with the audio muted. The experience rules (the whole party sharing a battle's experience, form experience 14x) are
the Definitive Edition's own, with nothing to set.

| main row | what it holds |
|---|---|
| `GAME` | `FAST-FORWARD` (speed and off/on), `SKIP DIALOGUES`, `SKIP BATTLE ANIMS` and `HIT REACTION`, `SAVE ANYWHERE`, `BATTLE MENU` (its buttons, `REMEMBER CURSOR`, `BUFFER INPUT`) |
| `VIDEO` | `HZ` (50 or 60), `RENDERER` (`GLES` for 3D, `SOFTWARE` for 2D-heavy scenes and the byte-exact reference) |
| `DEBUG` | `LOGS` (off / soft / heavy, off by default), `SAVE LOGS` (a `dw3-logs-<date>.zip` beside the port: the logs, the crash reports, the settings and the pad map) and `CLEAN LOGS`, after asking, which deletes those files and the old zips |
| `LED BAR` | the console's LED bar follows the acting Digimon's HP in battle (installs a small daemon) |
| `BUTTONS` | remap the pad: `LAYOUT` (`PS1` symbols or `MODERN` A/B/X/Y), `BATTLE MENU` (direct-button Persona-style HUD bindings for Fight, Tech, DV, Items, Tag, Run), and per-action button remapping |
| `RESET SETTINGS` | after asking, puts everything back: the tuned settings, the pad map (modern layout) and the LED bar switched on. The memory cards are never touched |
| `PLAY` | start the game |

Form experience is 14x and the game's own brake on it (10 points a battle before the fifth form-level threshold, 50
after, which is why a digivolution gains one level per battle) is skipped, so a won battle can raise several form
levels. The three chosen forms of each party member earn it, not a form left in the lab. These are the Definitive
Edition's rules, with nothing to set ([`docs/MECHANICS.md`](https://github.com/al4xdev/digimon-world-3-definitive-edition/blob/main/docs/MECHANICS.md)
section 6).

## Controls (default PS1 layout)

| Button | PS1 action |
|--|--|
| D-Pad | Move / menu |
| South | Cross (✕) |
| East | Circle (◯) |
| North | Square (▢) |
| West | Triangle (△) |
| L1 / R1 | L1 / R1 |
| L2 / R2 | L2 / R2 |
| Start | Start |
| Select + Start | Quit |

Everything can be rebound in the menu (`BUTTONS` → `REMAP`); it writes the mapping into `settings.json` and `pad.map`.
The button labels can be switched between classic PS1 symbols and Modern (A/B/X/Y). `Select + Start` quits from anywhere.

## Tested on

| device / CFW | state |
|---|---|
| XF35H (RK3326, Mali-G31, 640x480), EmuELEC 4.7-Nexus | **tested**: everything in this port was measured here |
| R36S and its clones (same SoC) | **not tested** on hardware (built against Cortex-A35, Mali-G31, 640x480, armhf + aarch64) |
| AmberELEC | **not tested** on hardware |
| dArkOS / ArkOS (including 64-bit-only builds) | **not tested** on hardware |
| muOS | **not tested** on hardware |
| ROCKNIX (Libmali and Panfrost) | **not tested** on hardware |
| Knulli (including TrimUI 64-bit) | **not tested** on hardware |
| TrimUI Stock / CrossMix (`aarch64`) | **not tested** on hardware |
| Other resolutions (480x320, 720x720, 1024x768, 1280x720) | **not tested** on hardware — **synthetically simulated** (`dw3-launcher` scales/centers across 480x320..1920x1080; `dw2003` integer-scales 2x/3x on `fbdev` or logical-scales on SDL2) |

> **Note (synthetic testing):** All `not tested` CFWs above (EmuELEC, R36S/clones, AmberELEC, ArkOS/dArkOS, muOS, ROCKNIX, Knulli, TrimUI Stock/CrossMix) were **synthetically tested** via source-code audits of PortMaster and each CFW's boot/SDL/GPU/audio scripts plus Docker + `qemu-arm` / `qemu-aarch64` + `Xvfb` simulations against the real `SLES-03936` disc and unpacked `dist/dw3.zip`, rather than direct playtests on physical hardware. Variations verified synthetically:
> - **Architectures & loaders (`armhf` + `aarch64`)**: native `aarch64` selection (`PORT_32BIT=N`), native `armv7l` `armhf` selection (`PORT_32BIT=Y`), hybrid 64-bit kernel (`uname -m = aarch64`) with 32-bit-only `armhf` userspace (missing `ld-linux-aarch64.so.1` automatic fallback to `armhf`), `DW3_FORCE_ARCH=armhf` override, `DEVICE_HAS_ARMHF=N` error guard, and `dw3-launcher.<arch>` standalone game binary auto-detection (`find_game_bin`).
> - **ABI & GPU/display fallbacks**: `glibc 2.28` floor on Debian 10 `buster` (covering ArkOS/EmuELEC `2.30` and TrimUI `2.33` through ROCKNIX `2.40`), `dlopen`-only GLES/EGL/GBM initialization without `libgbm.so.1` or `libEGL.so.1` (falling back cleanly to `--renderer software` on fbdev-only Mali and PowerVR devices), `WAYLAND_DISPLAY` SDL2 path (ROCKNIX Sway), `$ESUDO env` preservation (ArkOS/dArkOS), `muOS` static `PORT_32BIT="Y"` grep safety + `SDL_GAMECONTROLLERCONFIG` preservation, and BusyBox `/bin/sh` (`dash`) re-exec to `bash` (TrimUI/CrossMix).
> - **Resolutions & initial-screen captures**: `480x320`, `640x480`, `720x720`, `1024x768`, and `1280x720`, with pixel-identical initial-screen captures of `dw3-launcher` (`640x480`) and `dw2003` (`SELECT LANGUAGE` / `STDWTITL` intro) across both `armhf` and `aarch64`.
>
> Physical hardware confirmation from testers is still needed before marking any CFW row as tested.

**If you run it on another device, please report what you see**, in the port's thread on the PortMaster Discord, with
the device, the CFW and its version, and the resolution. Two facts make a report useful:

- the frame-rate line the game writes at exit: `port: window: N frames presented in X s (Y per second)` in
  `ports/dw3/logs/game.log` (this needs `LOGS` set to soft or heavy in the DEBUG group);
- whether the **films** show a rectangle of wrong pixels in the top-right corner. That is the one known rendering defect
  (see [the notes](https://github.com/al4xdev/digimon-world-3-definitive-edition/blob/main/docs/gpu/17-movie-artefact.md)); knowing which devices and
  drivers show it is worth more than a fix nobody can test.

## Known issues

- **Movie artefact on the GLES renderer:** a rectangle of wrong pixels in the top-right corner of the films. Cosmetic,
  films only, absent on the software renderer.
- **The renderer is a trade-off:** GLES wins where a frame has 3D (41.9 against 37.7 fps in the same battle); a light 2D
  frame pays the same ~3.2 ms present either way. Switch with the `RENDERER` row.
- **The heaviest battles are over budget:** about 24 ms against 20 ms with GLES.
- **GLES VRAM differs from the software renderer in 0.2-0.7% of its texels** (edges, 5-bit rounding). The picture is
  byte-identical at the frames compared with `--screenshot`.
- **`--input-test` hangs on the XF35H** (no output, immune to `timeout`). It does not affect playing.
- **One device only:** everything was measured on one handheld (XF35H, RK3326, Mali-G31, 640x480) at 60 Hz. The audio
  output is reproducible byte for byte (`--wav`).

## Compile

The port is built with the repository's ARM cross build (Docker with an armhf toolchain) and packed by a second script:

```
git clone https://github.com/al4xdev/digimon-world-3-definitive-edition --recurse-submodules
cd dw3
tools/build_arm.sh               # builds build/armhf-sdl2/dw2003 (-DPSXSTACK_SDL2=ON -DPSXSTACK_EGL=ON)
portmaster/make_release.sh       # checks the binary and writes dist/dw3.zip
```

## Thanks and credits

| project | what it gave this port |
|---|---|
| [gascarcella/dw2003recomp](https://github.com/gascarcella/dw2003recomp) | the decompilation of the game's own C and the PC port; the base this repository forks |
| [gascarcella/psxstack](https://github.com/gascarcella/psxstack) (fork used here: [al4xdev/dw3-psxstack](https://github.com/al4xdev/dw3-psxstack)) | the host runtime: arena, overlays, video, SPU, audio, input, memory cards, settings, the mods engine, the GPU backend, the crash report and the measurement switches |
| [stenzek/duckstation](https://github.com/stenzek/duckstation) | studied, not linked: the VRAM-as-a-texture design, the batch key that became per-vertex state here, and the framebuffer-fetch strategy for the mask bit and semi-transparency. The notes in [`docs/gpu`](https://github.com/al4xdev/digimon-world-3-definitive-edition/tree/main/docs/gpu) record what was kept and what was rejected; the implementation is this project's own |
| [psx-spx](https://psx-spx.consoledev.net/) | the hardware reference: the SPU's voices, envelopes and reverb, the GPU's commands, the GTE's arithmetic |
| PCSX-Redux | the oracle for the tests (SPU traces, replay runners), never a source of code |
| [SDL2](https://github.com/libsdl-org/SDL) | the window, the gamepad, the audio device and the threads on the host |
| [libretro-thumbnails](https://github.com/libretro-thumbnails/libretro-thumbnails) | the box art in `cover.png` |
| [PortMaster](https://github.com/PortsMaster) | the packaging rules this folder follows, and the multiverse catalogue a decompilation goes to |