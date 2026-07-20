# vu-proton

[Venice Unleashed](https://veniceunleashed.net) (BF3 mods) on Linux without
hating yourself. Runs inside BF3's Steam Proton prefix — you need
[nix](https://nixos.org/download), the rest is automated.

## how to

1. Get BF3 via Steam and start it once so the EA app sets itself up, then
   quit (EA stays open — leave it):
   ```sh
   steam steam://install/1238820
   steam -applaunch 1238820 singleplayer   # skips the broken Battlelog browser
   ```
2. `nix run github:VileEnd/vu-proton#vu-setup`
3. `nix run github:VileEnd/vu-proton#vu` — play.

Stuck? `nix run github:VileEnd/vu-proton#vu-setup -- --check` tells you
exactly which step you're missing. Ownership complaints: `#vu -- --verify`.
Steam library somewhere weird: prefix with `STEAM_LIBRARY=/path/to/Steam`
(usually not needed, it auto-detects).

## own server / mods

`nix run github:VileEnd/vu-proton#vu-server` (add `-headless` for no
window). First run creates the instance dir and prints its path:

```
Server/
├─ server.key              # from veniceunleashed.net/keys
└─ Admin/
   ├─ Startup.txt  MapList.txt
   ├─ ModList.txt          # one mod name per line — nothing loads otherwise
   └─ Mods/my-mod/mod.json
```

Dev loop: vu-server in one terminal, vu in the other, connect to localhost.
More in the [VU docs](https://docs.veniceunleashed.net).

## when it instantly dies (OpenGL / DXVK errors)

Not your drivers. On non-NixOS the nix-packaged protontricks can't use the
Steam Runtime container, so Proton runs blind. Fix: install your distro's
protontricks (Arch: `pacman -S protontricks`) — the scripts automatically
prefer it. Also: nix caches github flakes for an hour, so after an update
run once with `nix run --refresh github:VileEnd/vu-proton#vu`.

## fresh machine, full sequence

Arch (or similar):

```sh
sudo pacman -S steam protontricks nix
sudo systemctl enable --now nix-daemon.socket
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
# steam: log in, enable Proton for all titles (Settings → Compatibility)
steam steam://install/1238820
steam -applaunch 1238820 singleplayer    # once — EA login happens here, then quit
nix run github:VileEnd/vu-proton#vu-setup
nix run github:VileEnd/vu-proton#vu
```

NixOS: add `programs.steam.enable = true;` to your config (protontricks not
needed — the nix one works there), then the same steam steps and the same
two `nix run` commands.

## credits

Thanks **Envii** (`enviipv` on Discord, BF3: Reality Mod) for the original
guide and the help. Not affiliated with VU/EA/DICE. MIT.
