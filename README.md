# vu-proton — Venice Unleashed on Linux, the nix way

[Venice Unleashed](https://veniceunleashed.net) (VU) is the Battlefield 3
modding platform. It runs great on Linux inside BF3's **Steam Proton prefix**
— but the setup is fiddly. This flake turns the whole thing into three
commands. Works on any x86_64 Linux with [nix](https://nixos.org/download)
installed (NixOS not required).

```sh
nix run github:VileEnd/vu-proton#vu-setup   # one-time install
nix run github:VileEnd/vu-proton#vu         # play
nix run github:VileEnd/vu-proton#vu-server  # dedicated server / mod dev
```

## Prerequisites

1. Steam with **Battlefield 3 installed via Proton** (appid 1238820).
2. Launch BF3 once (e.g. start the campaign) so the EA app gets set up.
   Buying/linking on ea.com from Linux may need a spoofed browser User-Agent.
3. The EA app must be running **during `vu-setup` only** — it conveniently
   still is right after you close BF3. Normal VU launches don't need it.

## What the commands do

- **`vu-setup`** — downloads the latest official installer from
  veniceunleashed.net, runs it inside BF3's Proton prefix (keep the default
  paths), and installs `d3dcompiler_47` into the prefix. Uses
  [protontricks](https://github.com/Matoking/protontricks) under the hood —
  provided by nix, nothing to install.
- **`vu [args]`** — launches the VU client. `vu --verify` re-checks BF3
  ownership with EA (`-console -wait -activate -lsx`).
- **`vu-server [args]`** — starts a dedicated server (`-server -dedicated`;
  add `-headless` for no window). Creates the instance dir on first run and
  prints its path.

Steam library somewhere else? Prefix any command with
`STEAM_LIBRARY=/path/to/Steam`.

## Server / mod development layout

The server reads everything from its instance directory
(`My Documents/Battlefield 3/Server` inside the prefix — `vu-server` prints
the real path):

```
Server/
├─ server.key              # your key from veniceunleashed.net/keys
└─ Admin/
   ├─ Startup.txt          # vars.serverName "My server" ...
   ├─ MapList.txt          # MP_Subway ConquestLarge0 1
   ├─ ModList.txt          # one mod folder name per line — REQUIRED,
   │                       # VU loads no mods unless listed here
   └─ Mods/
      └─ my-mod/mod.json   # your mods
```

Dev loop: `vu-server` in one terminal, `vu` in another, connect to
localhost. See the [VU docs](https://docs.veniceunleashed.net) for modding
and server configuration details.

## Optional: desktop entry

`~/.local/share/applications/venice-unleashed.desktop`:

```ini
[Desktop Entry]
Name=Venice Unleashed
Exec=nix run github:VileEnd/vu-proton#vu
Terminal=false
Type=Application
Categories=Game;
```

(You can also add that to Steam via "Add a Game".)

## Credits

Big thanks to **Envii** (`enviipv` on Discord) from **BF3: Reality Mod** for
the Proton/protontricks guide and help on Discord — this flake automates
those setup steps. Also based on the official
[VU docs](https://docs.veniceunleashed.net).
Not affiliated with Venice Unleashed, EA or DICE. BF3 ownership required.
