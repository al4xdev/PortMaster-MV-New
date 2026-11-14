What this port ships, and what each licence here covers.

  dw2003, dw3-launcher        the port binary: the game's own decompiled C with the PlayStation's hardware
  Digimon World 3.sh,         reimplemented for the host, built from github.com/al4xdev/digimon-world-3-definitive-edition (a fork of the
  ledd.py                     dw2003recomp decompilation). LICENSE - MIT.
                              It contains no game data: it reads the player's own disc.
                              dw3-launcher embeds stb_truetype (public domain / MIT) and Liberation Sans (SIL OFL 1.1).

  SDL2.txt                    SDL2, linked from the device's firmware (or from PortMaster's own copy when
                              the firmware has none). zlib licence.

  EGL, GLESv2, libgbm         the handheld's vendor graphics libraries, loaded at run time from the
                              firmware. Not redistributed here; their licences ship with the device.

  Psy-Q                      not included. The port declares the API it needs and implements every call
                              itself; no Sony file is present in the binary or in this package.

The game, Digimon World 2003, is the property of its publisher. This package carries nothing of it.
