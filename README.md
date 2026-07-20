# vu-proton

[Venice Unleashed](https://veniceunleashed.net) (BF3 mod platform) on Linux,
running inside BF3's Steam **Proton** prefix. Needs
[nix](https://nixos.org/download) — everything else is checked/automated.

## TL;DR

1. Install **BF3 via Steam** and launch it once, then quit — from the CLI:
   ```sh
   steam steam://install/1238820           # install BF3
   steam -applaunch 1238820 singleplayer   # launch once (campaign), then quit
   ```
   The `singleplayer` argument boots the game directly and skips BF3's
   browser-based Battlelog launcher (broken/painful on Linux); EA stays
   online so saves sync. (Windows game — enable Proton/Steam Play in Steam
   settings if you never have.) The EA app stays open after quitting —
   leave it running for step 2.
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

## Troubleshooting: VU exits instantly (OpenGL/DXVK errors) on non-NixOS

Symptoms: `couldn't initialize OpenGL` / `Failed to initialize DXVK`, VU
exits right after start. Cause: the nix-packaged protontricks has the Steam
Runtime container disabled — correct on NixOS, but on other distros modern
Proton then runs without working GPU drivers. Two fixes:

1. **Install your distro's protontricks** (Arch: `yay -S protontricks`;
   elsewhere: `pipx install protontricks`). The vu commands automatically
   prefer a host protontricks when one exists — no other change needed.
   `vu-setup -- --check` shows which copy is in use.
2. **Or launch through Steam itself** (full Proton container): BF3 →
   Properties → Launch Options:
   ```
   eval $( echo "%command%" | sed 's|steamapps/common/Battlefield 3/bf3.exe|steamapps/compatdata/1238820/pfx/drive_c/users/steamuser/AppData/Local/VeniceUnleashed/client/vu.exe|' )
   ```
   Then BF3's Play button (or `steam -applaunch 1238820`) starts VU.
   Remove the launch options to get vanilla BF3 back.

## Credits

Thanks to **Envii** (`enviipv` on Discord, BF3: Reality Mod) for the
Proton guide and help. Not affiliated with VU/EA/DICE. MIT license.
