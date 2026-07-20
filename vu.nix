# Venice Unleashed (BF3 mod platform) helpers — VU lives inside BF3's Proton
# prefix and is driven via protontricks. Based on the community Proton guide
# by Envii (enviipv, BF3: Reality Mod).
{ pkgs }:
let
  appid = "1238820"; # BF3's Steam appid — constant, VU always targets it

  # Shared discovery: Steam root (native or flatpak, STEAM_LIBRARY override),
  # then whichever Steam library actually holds BF3 (libraryfolders.vdf can
  # point at several). Sets: steamroot, bf3lib, pfx, exe.
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
  '';
in
{
  vu-setup = pkgs.writeShellApplication {
    name = "vu-setup";
    runtimeInputs = with pkgs; [
      protontricks
      curl
      procps
    ];
    text = ''
      ${findSteamLib}
      # --check: preflight only — walk the guide's prerequisites and report.
      if [ "''${1:-}" = "--check" ]; then
        locate_vu || exit 1
        echo "✓ Steam:          $steamroot"
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
        if [ -f "''${pfx:-}/drive_c/Program Files/Electronic Arts/EA Desktop/EA Desktop/EADesktop.exe" ]; then
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

      # Install flow. EA app must be running during THIS setup only (it still
      # is right after closing BF3) — normal VU launches don't need it.
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
      protontricks-launch --appid ${appid} "$installer"
      echo ">> Installing d3dcompiler_47 into the prefix..."
      protontricks ${appid} d3dcompiler_47
      echo ">> Done. Launch with: vu"
    '';
  };

  vu-server = pkgs.writeShellApplication {
    name = "vu-server";
    runtimeInputs = [ pkgs.protontricks ];
    text = ''
      ${findSteamLib}
      # Dedicated VU server (hosting / mod development). Own mods go into
      # Admin/Mods and are activated by name in Admin/ModList.txt.
      locate_vu || exit 1
      if [ -z "$exe" ] || [ ! -f "$exe" ]; then
        echo "vu.exe not found — run vu-setup first (or vu-setup --check)." >&2
        exit 1
      fi
      # default instance dir per VU docs: "My Documents\Battlefield 3\Server"
      inst="$pfx/drive_c/users/steamuser/Documents/Battlefield 3/Server"
      mkdir -p "$inst/Admin/Mods"
      echo "Server instance dir: $inst"
      if [ ! -f "$inst/server.key" ]; then
        echo "NOTE: no server key yet — create one at https://veniceunleashed.net/keys" >&2
        echo "      and save it as: $inst/server.key" >&2
      fi
      # extra args pass through, e.g.: vu-server -headless
      exec protontricks-launch --appid ${appid} "$exe" -server -dedicated "$@"
    '';
  };

  vu = pkgs.writeShellApplication {
    name = "vu";
    runtimeInputs = [ pkgs.protontricks ];
    text = ''
      ${findSteamLib}
      # Launch Venice Unleashed. --verify: re-check BF3 ownership with EA.
      locate_vu || exit 1
      if [ -z "$exe" ] || [ ! -f "$exe" ]; then
        echo "vu.exe not found — run vu-setup first (or vu-setup --check)." >&2
        exit 1
      fi
      if [ "''${1:-}" = "--verify" ]; then
        shift
        exec protontricks-launch --appid ${appid} "$exe" -console -wait -activate -lsx "$@"
      fi
      exec protontricks-launch --appid ${appid} "$exe" "$@"
    '';
  };
}
