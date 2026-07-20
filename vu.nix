# Venice Unleashed via protontricks inside BF3's Proton prefix.
# Based on Envii's guide (enviipv, BF3: Reality Mod).
{ pkgs }:
let
  appid = "1238820"; # BF3 — constant

  # find steam (native/flatpak), the library holding BF3, and vu.exe
  # sets: steamroot, bf3lib, pfx, exe
  findSteamLib = ''
    find_steam_root() {
      for d in "''${STEAM_LIBRARY:-}" \
               "$HOME/.local/share/Steam" \
               "$HOME/.steam/steam" \
               "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
        if [ -n "$d" ] && [ -d "$d/steamapps" ]; then echo "$d"; return 0; fi
      done
      return 1
    }
    find_bf3_lib() {
      { echo "$1"
        sed -n 's/.*"path"[[:space:]]*"\([^"]*\)".*/\1/p' \
          "$1/steamapps/libraryfolders.vdf" 2>/dev/null || true
      } | while IFS= read -r lib; do
        if [ -f "$lib/steamapps/appmanifest_${appid}.acf" ]; then
          echo "$lib"
          break
        fi
      done
    }
    locate_vu() {
      steamroot="$(find_steam_root)" || {
        echo "Steam not found (looked in ~/.local/share/Steam, ~/.steam and" >&2
        echo "flatpak; override with STEAM_LIBRARY=/path/to/Steam)." >&2
        echo "Install Steam first — NixOS: programs.steam.enable = true;" >&2
        echo "Arch: pacman -S steam. Proton then comes via Steam itself." >&2
        return 1
      }
      bf3lib="$(find_bf3_lib "$steamroot")"
      pfx="''${bf3lib:+$bf3lib/steamapps/compatdata/${appid}/pfx}"
      exe="''${pfx:+$pfx/drive_c/users/steamuser/AppData/Local/VeniceUnleashed/client/vu.exe}"
    }
    # prefer the distro's protontricks: the nixpkgs build has the Steam
    # Runtime patched off — fine on NixOS, no GPU on other distros
    PT_LAUNCH="$(command -v protontricks-launch)"
    PT="$(command -v protontricks)"
    for p in "$HOME/.local/bin" /usr/local/bin /usr/bin; do
      if [ -x "$p/protontricks-launch" ]; then
        PT_LAUNCH="$p/protontricks-launch"
        [ -x "$p/protontricks" ] && PT="$p/protontricks"
        break
      fi
    done
    export PT PT_LAUNCH
  '';
in
{
  vu-setup = pkgs.writeShellApplication {
    name = "vu-setup";
    runtimeInputs = with pkgs; [
      protontricks
      curl
      procps
      findutils
    ];
    text = ''
      ${findSteamLib}
      # --check: walk the prereqs, print what's missing
      if [ "''${1:-}" = "--check" ]; then
        locate_vu || exit 1
        echo "✓ Steam:          $steamroot"
        case "$PT_LAUNCH" in
          /nix/store/*) echo "- protontricks:   nix copy (fine on NixOS; other distros: install your distro's protontricks for GPU access)" ;;
          *) echo "✓ protontricks:   $PT_LAUNCH (host)" ;;
        esac
        if [ -n "$bf3lib" ]; then
          echo "✓ BF3 installed:  $bf3lib/steamapps"
        else
          echo "✗ BF3 not installed — run: steam steam://install/${appid}"
        fi
        if [ -n "$pfx" ] && [ -d "$pfx" ]; then
          echo "✓ Proton prefix:  BF3 was launched at least once"
        else
          echo "✗ Proton prefix missing — run: steam -applaunch ${appid} singleplayer"
        fi
        if find "''${pfx:-/nonexistent}/drive_c/Program Files/Electronic Arts" \
             -name EADesktop.exe -print -quit 2>/dev/null | grep -q .; then
          echo "✓ EA Desktop:     present in the prefix"
        else
          echo "✗ EA Desktop not set up — the first BF3 launch installs it"
        fi
        if pgrep -f EADesktop.exe >/dev/null 2>&1; then
          echo "✓ EA app:         running (needed during vu-setup only)"
        else
          echo "- EA app:         not running (start BF3 briefly before vu-setup)"
        fi
        if [ -n "$exe" ] && [ -f "$exe" ]; then
          echo "✓ VU:             installed"
        else
          echo "✗ VU not installed — run vu-setup"
        fi
        if grep -qs d3dcompiler_47 "''${pfx:-}/winetricks.log"; then
          echo "✓ d3dcompiler_47: installed"
        else
          echo "- d3dcompiler_47: not confirmed (vu-setup installs it)"
        fi
        exit 0
      fi

      # install — the EA app only needs to run during this, not for playing
      locate_vu || exit 1
      if [ -z "$bf3lib" ]; then
        echo "BF3 is not installed — run: steam steam://install/${appid}" >&2
        echo "Full preflight: vu-setup --check" >&2
        exit 1
      fi
      if [ ! -d "$pfx" ]; then
        echo "BF3 Proton prefix missing — launch it once first (skips Battlelog):" >&2
        echo "  steam -applaunch ${appid} singleplayer" >&2
        exit 1
      fi
      if ! pgrep -f EADesktop.exe >/dev/null 2>&1; then
        echo "WARNING: EA app not running — setup may fail. Launch BF3 briefly" >&2
        echo "(steam -applaunch ${appid} singleplayer — EA stays open after" >&2
        echo "quitting), then re-run vu-setup." >&2
      fi
      installer="''${XDG_CACHE_HOME:-$HOME/.cache}/vu-installer.exe"
      echo ">> Downloading the latest VU installer..."
      curl -fLo "$installer" https://veniceunleashed.net/files/vu.exe
      echo ">> Running the installer inside the BF3 prefix (keep default paths)..."
      "$PT_LAUNCH" --appid ${appid} "$installer"
      echo ">> Installing d3dcompiler_47 into the prefix..."
      "$PT" ${appid} d3dcompiler_47
      echo ">> Done. Launch: vu (NixOS) / nix run github:VileEnd/vu-proton#vu"
      echo ">> Non-NixOS + graphics errors on launch? See README Troubleshooting."
    '';
  };

  vu-server = pkgs.writeShellApplication {
    name = "vu-server";
    runtimeInputs = [ pkgs.protontricks ];
    text = ''
      ${findSteamLib}
      # dedicated server — mods: Admin/Mods/<name> + line in Admin/ModList.txt
      locate_vu || exit 1
      if [ -z "$exe" ] || [ ! -f "$exe" ]; then
        echo "vu.exe not found — run vu-setup first (or vu-setup --check)." >&2
        exit 1
      fi
      # VU default: My Documents\Battlefield 3\Server
      inst="$pfx/drive_c/users/steamuser/Documents/Battlefield 3/Server"
      mkdir -p "$inst/Admin/Mods"
      echo "Server instance dir: $inst"
      if [ ! -f "$inst/server.key" ]; then
        echo "NOTE: no server key yet — create one at https://veniceunleashed.net/keys" >&2
        echo "      and save it as: $inst/server.key" >&2
      fi
      # args pass through, e.g. -headless
      exec "$PT_LAUNCH" --appid ${appid} "$exe" -server -dedicated "$@"
    '';
  };

  vu = pkgs.writeShellApplication {
    name = "vu";
    runtimeInputs = [ pkgs.protontricks ];
    text = ''
      ${findSteamLib}
      # --verify: re-check BF3 ownership
      locate_vu || exit 1
      if [ -z "$exe" ] || [ ! -f "$exe" ]; then
        echo "vu.exe not found — run vu-setup first (or vu-setup --check)." >&2
        exit 1
      fi
      if [ "''${1:-}" = "--verify" ]; then
        shift
        exec "$PT_LAUNCH" --appid ${appid} "$exe" -console -wait -activate -lsx "$@"
      fi
      exec "$PT_LAUNCH" --appid ${appid} "$exe" "$@"
    '';
  };
}
