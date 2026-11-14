#!/bin/bash

# TrimUI / CrossMix runs ports via `/bin/sh "$@"` (BusyBox ash), ignoring the shebang.
# Re-exec under bash early when available so PortMaster's control.txt/funcs.txt work cleanly.
if [ -z "${BASH_VERSION:-}" ] && command -v bash >/dev/null 2>&1; then
  exec bash "$0" "$@"
fi

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/PortMaster/" ]; then
  controlfolder="/PortMaster"
elif [ -d "/mnt/mmc/MUOS/PortMaster/" ]; then
  controlfolder="/mnt/mmc/MUOS/PortMaster"
elif [ -d "/mnt/SDCARD/Apps/PortMaster/PortMaster/" ]; then
  controlfolder="/mnt/SDCARD/Apps/PortMaster/PortMaster"
elif [ -d "/mnt/SDCARD/Persistent/portmaster/PortMaster/" ]; then
  controlfolder="/mnt/SDCARD/Persistent/portmaster/PortMaster"
elif [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

# Choose native aarch64 on 64-bit systems when aarch64 userspace and dw2003.aarch64 are present, else armhf.
# Note: muOS ext-general.sh statically greps this script for literal PORT_32BIT="Y" and injects 32-bit PipeWire
# paths if found; keep PORT_32BIT dynamic so 64-bit muOS runs keep 64-bit PipeWire plugins.
case "$(uname -m 2>/dev/null || echo armv7l)" in
  aarch64|arm64)
    has_aarch64_ld=0
    for ld64 in /lib/ld-linux-aarch64.so.1 /usr/lib/ld-linux-aarch64.so.1 /lib64/ld-linux-aarch64.so.1; do
      [ -e "$ld64" ] && has_aarch64_ld=1 && break
    done
    if [ "$has_aarch64_ld" = 1 ]; then
      host_arch="aarch64"
    else
      # 64-bit kernel with 32-bit-only rootfs (e.g. RPi 32-bit OS / hybrid RK3326 images).
      host_arch="armhf"
    fi
    ;;
  *) host_arch="armhf" ;;
esac
target_arch="${DW3_FORCE_ARCH:-$host_arch}"
if [ "$target_arch" = "aarch64" ]; then
  pm_32bit="N"
else
  pm_32bit="Y"
fi
export PORT_32BIT="$pm_32bit"

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/dw3"
cd "$GAMEDIR" || {
  pm_show_error "Missing port directory: $GAMEDIR" --title "Digimon World 3"
  exit 1
}

if [ -n "${BASH_VERSION:-}" ]; then
  > "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
else
  exec > "$GAMEDIR/log.txt" 2>&1
fi

if [ "$target_arch" = "aarch64" ] && [ ! -f "$GAMEDIR/dw2003.aarch64" ] && [ -f "$GAMEDIR/dw2003.armhf" ]; then
  target_arch="armhf"
  pm_32bit="Y"
  export PORT_32BIT="$pm_32bit"
  unset PM_FUNCS_VERSION
  [ -f "$controlfolder/funcs.txt" ] && source "$controlfolder/funcs.txt"
  [ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
fi
if [ "$target_arch" = "armhf" ] && [ "${DEVICE_HAS_ARMHF:-Y}" = "N" ] && [ ! -f "$GAMEDIR/dw2003.aarch64" ]; then
  echo "BLOCKER: CFW/device has no 32-bit armhf userspace (DEVICE_HAS_ARMHF=N, CFW=${CFW_NAME:-unknown})"
  pm_show_error "This port requires 32-bit armhf or 64-bit aarch64 libraries unavailable on ${CFW_NAME:-this device}." --title "Digimon World 3"
  exit 1
fi

if [ -x "$GAMEDIR/dw2003.${target_arch}" ]; then
  BINARY="dw2003.${target_arch}"
else
  BINARY="dw2003"
fi
if [ -x "$GAMEDIR/dw3-launcher.${target_arch}" ]; then
  LAUNCHER="dw3-launcher.${target_arch}"
else
  LAUNCHER="dw3-launcher"
fi
export DW3_GAME_BIN="$GAMEDIR/$BINARY"

# The player's disc. This list is the game's; pm has no finder.
DISC=""
for candidate in \
  "$GAMEDIR/game/dw3.cue" \
  "$GAMEDIR/game/dw3.bin" \
  "$GAMEDIR/game/dw2003.cue" \
  "$GAMEDIR/game/dw2003.bin" \
  "$GAMEDIR/game/Digimon World 2003.cue" \
  "$GAMEDIR/game/Digimon World 2003.bin" \
  "$GAMEDIR/game/Digimon World 3.cue" \
  "$GAMEDIR/game/Digimon World 3.bin"; do
  if [ -f "$candidate" ]; then
    DISC="$candidate"
    break
  fi
done

if [ -z "$DISC" ]; then
  DISC=$(find "$GAMEDIR/game" -maxdepth 1 \( -iname "*.cue" -o -iname "*.bin" \) 2>/dev/null | head -n 1)
fi

if [ -z "$DISC" ]; then
  echo "Missing Digimon World 2003 disc image (.bin/.cue) in $GAMEDIR/game/"
  pm_show_error "Please copy your Digimon World 2003 .bin/.cue into ports/dw3/game/" --title "Digimon World 3"
  exit 1
fi

# Preserve CFW/PortMaster controller mapping; mod_EmuELEC clears >100KB strings to avoid E2BIG,
# and muOS ext-general.sh already sets SDL_GAMECONTROLLERCONFIG before running the script.
if [ -n "${sdl_controllerconfig:-}" ]; then
  export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
fi

fb=0
if [ -e /dev/fb0 ] && { { [ -r /dev/fb0 ] && [ -w /dev/fb0 ]; } || [ -n "${ESUDO:-}" ]; }; then
  fb=1
fi
if [ -n "${DW3_FORCE_VIDEO:-}" ]; then
  export DW3_VIDEO="$DW3_FORCE_VIDEO"
elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
  # Wayland compositors (e.g. ROCKNIX Sway) own DRM; keep the port off /dev/fb0.
  export DW3_VIDEO=sdl2
elif [ "$fb" = 1 ]; then
  export DW3_VIDEO=fbdev
else
  export DW3_VIDEO=sdl2
fi

BIN="$GAMEDIR/$BINARY"
check_bin_ldd() {
  local target="$1"
  if [ "$target_arch" = "aarch64" ]; then
    if command -v ldd >/dev/null 2>&1; then
      local out
      out="$(ldd "$target" 2>&1 || true)"
      echo "$out" | grep -v "not a dynamic executable" || true
    else
      for ld64 in /lib/ld-linux-aarch64.so.1 /usr/lib/ld-linux-aarch64.so.1 /lib64/ld-linux-aarch64.so.1; do
        if [ -x "$ld64" ]; then
          "$ld64" --list "$target" 2>&1
          break
        fi
      done
    fi
    return
  fi
  if command -v ldd32 >/dev/null 2>&1; then
    ldd32 "$target" 2>&1
  elif command -v ldd_32 >/dev/null 2>&1; then
    ldd_32 "$target" 2>&1
  elif [ -x /lib/ld-linux-armhf.so.3 ]; then
    /lib/ld-linux-armhf.so.3 --list "$target" 2>&1
  elif [ -x /usr/lib/ld-linux-armhf.so.3 ]; then
    /usr/lib/ld-linux-armhf.so.3 --list "$target" 2>&1
  elif command -v ldd >/dev/null 2>&1; then
    local out
    out="$(ldd "$target" 2>&1 || true)"
    echo "$out" | grep -v "not a dynamic executable" || true
  fi
}

ldd_out="$(check_bin_ldd "$BIN")"
missing="$(echo "$ldd_out" | grep 'not found' || true)"
if [ -n "$missing" ]; then
  echo "BLOCKER: $target_arch libraries missing:"
  echo "$missing"
  pm_show_error "Missing $target_arch shared libraries for $BINARY. See ports/dw3/log.txt." --title "Digimon World 3"
  exit 1
fi

mkdir -p ./logs
echo "arch: $target_arch (host=$host_arch, binary=$BINARY, launcher=$LAUNCHER)"

# software is the binary default. gles only on Cortex-A35 (CPU part 0xd04, RK3326).
cpu_part=""
if [ -r /proc/cpuinfo ]; then
  cpu_part=$(awk -F': ' '/CPU part/ { gsub(/^[ \t]+/, "", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null || true)
fi
if [ "$cpu_part" = "0xd04" ]; then
  export DW3_DEFAULT_RENDERER=gles
  echo "renderer: gles (CPU part 0xd04)"
else
  echo "renderer: software (CPU part ${cpu_part:-unknown})"
fi

# pm_finish clears the TTY. It does not clear pixels written directly to /dev/fb0.
blank_fb() {
  if [ "$DW3_VIDEO" = "fbdev" ] && [ -w /dev/fb0 ]; then
    dd if=/dev/zero of=/dev/fb0 bs=4096 count=2048 status=none 2>/dev/null || true
  fi
}

# Unset DW3_LOG is soft, not off. The menu's debug.logs is the player's choice.
DW3_LOG_LEVEL="off"
if [ -f ./settings.json ]; then
  DW3_LOG_LEVEL=$(sed -n 's/.*"logs"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' ./settings.json | head -n 1)
fi
case "$DW3_LOG_LEVEL" in
  soft|heavy) export DW3_LOG="$DW3_LOG_LEVEL" ;;
  *) export DW3_LOG=off ;;
esac

# Tester diagnostic. Off unless the player asked for heavy logs.
if [ "$DW3_LOG_LEVEL" = "heavy" ] && [ -r "$GAMEDIR/probe.sh" ]; then
  sh "$GAMEDIR/probe.sh" || true
fi

# SDL2 build ignores settings.json's pad map unless this is set.
export DW3_PAD_REMAP=1
export DW3_PORTMASTER=1

# Run with $ESUDO when PortMaster requires privilege escalation (e.g. ArkOS user 'ark'),
# explicitly preserving runtime environment variables across sudo.
run_with_env() {
  if [ -n "${ESUDO:-}" ]; then
    $ESUDO env \
      LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}" \
      SDL_GAMECONTROLLERCONFIG="${SDL_GAMECONTROLLERCONFIG:-}" \
      SDL_GAMECONTROLLERCONFIG_FILE="${SDL_GAMECONTROLLERCONFIG_FILE:-}" \
      SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-}" \
      SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-}" \
      SDL_VIDEO_EGL_DRIVER="${SDL_VIDEO_EGL_DRIVER:-}" \
      SPA_PLUGIN_DIR="${SPA_PLUGIN_DIR:-}" \
      PIPEWIRE_MODULE_DIR="${PIPEWIRE_MODULE_DIR:-}" \
      LIBGL_DRIVERS_PATH="${LIBGL_DRIVERS_PATH:-}" \
      WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
      XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
      DISPLAY_WIDTH="${DISPLAY_WIDTH:-}" \
      DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-}" \
      CFW_NAME="${CFW_NAME:-}" \
      DW3_VIDEO="${DW3_VIDEO:-}" \
      DW3_DEFAULT_RENDERER="${DW3_DEFAULT_RENDERER:-}" \
      DW3_FORCE_RENDERER="${DW3_FORCE_RENDERER:-}" \
      DW3_GAME_BIN="${DW3_GAME_BIN:-}" \
      DW3_LOG="${DW3_LOG:-}" \
      DW3_PAD_REMAP="${DW3_PAD_REMAP:-}" \
      DW3_PORTMASTER="${DW3_PORTMASTER:-}" \
      "$@"
  else
    "$@"
  fi
}

# Kill switch only. The game reads the pad; no .ini. Backgrounded, or this script blocks.
$GPTOKEYB2 "$BINARY" > /dev/null 2>&1 &

set -- --window --fullscreen --watchdog 0
if [ -f ./settings.json ]; then
  set -- --config ./settings.json "$@"
fi
set -- --disc "$DISC" "$@"
if [ -n "${DW3_FORCE_RENDERER:-}" ]; then
  set -- "$@" --renderer "$DW3_FORCE_RENDERER"
elif [ "${DW3_DEFAULT_RENDERER:-}" = "gles" ] && [ ! -f ./settings.json ]; then
  set -- "$@" --renderer gles
fi

game_rc=3
if [ "${DW3_SKIP_MENU:-0}" != "1" ] && [ -x "./$LAUNCHER" ]; then
  echo "menu: $LAUNCHER ($DW3_VIDEO)" > ./menu.log
  launcher_flag="--fb"
  [ "$DW3_VIDEO" = "sdl2" ] && launcher_flag="--sdl"
  pm_platform_helper "$GAMEDIR/$LAUNCHER"
  pm_platform_helper "$GAMEDIR/$BINARY"
  run_with_env "./$LAUNCHER" "$launcher_flag" >> ./menu.log 2>&1
  game_rc=$?
else
  echo "menu skipped" >> ./menu.log
  pm_platform_helper "$GAMEDIR/$BINARY"
fi

# 3: the launcher found no screen or menu was skipped; run the game straight from the settings.
if [ "$game_rc" = 3 ]; then
  run_with_env "./$BINARY" "$@" >> ./logs/game.log 2>&1
  game_rc=$?
fi

blank_fb
pm_finish
exit "$game_rc"
