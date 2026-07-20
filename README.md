# vu-proton

[Venice Unleashed](https://veniceunleashed.net) (BF3 mod platform) on Linux,
running inside BF3's Steam **Proton** prefix. Needs
[nix](https://nixos.org/download) — everything else is checked/automated.

## TL;DR

1. Install **BF3 via Steam** and launch it once, then quit — straight from
   the CLI, no Steam UI browsing:
   ```sh
   steam steam://install/1238820      # install BF3
   steam steam://rungameid/1238820    # launch it once, then quit
   ```
   (Windows game — enable Proton/Steam Play in Steam settings if you never
   have.) The EA app stays open — leave it running for step 2.
2. `nix run github:VileEnd/vu-proton#vu-setup`
3. `nix run github:VileEnd/vu-proton#vu` — play.

That's it. Extras:

```sh
nix run github:VileEnd/vu-proton#vu-setup -- --check   # ✓/✗ preflight of every prereq
nix run github:VileEnd/vu-proton#vu -- --verify        # re-check BF3 ownership
nix run github:VileEnd/vu-proton#vu-server             # dedicated server (add -headless)
```

Steam (native or flatpak) and BF3's library are auto-detected; override with
`STEAM_LIBRARY=/path/to/Steam`. Steam/Proton themselves can't come from nix —
Steam is your distro's job, and Steam downloads Proton itself.

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
