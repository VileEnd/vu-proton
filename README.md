# vu-proton

[Venice Unleashed](https://veniceunleashed.net) (BF3 mod platform) on Linux,
running inside BF3's Steam **Proton** prefix. Needs
[nix](https://nixos.org/download) and BF3 installed via Steam — launch BF3
once first, and keep the EA app running during `vu-setup` (only then).

```sh
nix run github:VileEnd/vu-proton#vu-setup   # one-time install (+ d3dcompiler_47)
nix run github:VileEnd/vu-proton#vu         # play  (--verify re-checks ownership)
nix run github:VileEnd/vu-proton#vu-server  # dedicated server (add -headless)
```

Not sure where you stand? Run the preflight:

```sh
nix run github:VileEnd/vu-proton#vu-setup -- --check
```

```
✓ Steam:          /home/you/.local/share/Steam
✓ BF3 installed:  ...
✗ Proton prefix missing — launch BF3 once via Steam
...
```

It finds Steam (native or flatpak) and BF3 in any Steam library
automatically; override with `STEAM_LIBRARY=/path/to/Steam`. Steam and
Proton themselves can't come from nix — Steam is your distro's job, and
Steam downloads Proton itself.

## Server: hosting & mod dev

`vu-server` creates the instance dir on first run and prints its path
(`My Documents/Battlefield 3/Server` inside the prefix):

```
Server/
├─ server.key                 # from veniceunleashed.net/keys
└─ Admin/
   ├─ Startup.txt             # vars.serverName "..." etc.
   ├─ MapList.txt             # MP_Subway ConquestLarge0 1
   ├─ ModList.txt             # one mod folder name per line — required!
   └─ Mods/my-mod/mod.json    # your mods
```

Mod dev loop: `vu-server` in one terminal, `vu` in another, connect to
localhost. Details: [VU docs](https://docs.veniceunleashed.net).

## Credits

Thanks to **Envii** (`enviipv` on Discord, BF3: Reality Mod) for the
Proton guide and help. Not affiliated with VU/EA/DICE. MIT license.
