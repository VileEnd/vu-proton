# Venice Unleashed (BF3 mod platform) helpers — VU lives inside BF3's Proton
# prefix and is driven via protontricks. Adapted from the community Proton
# guide. Also exposed as flake packages: nix run .#vu-setup / .#vu
{ pkgs }:
let
  appid = "1238820"; # BF3's Steam appid — constant, VU always targets it
in
{
  vu-setup = pkgs.writeShellApplication {
    name = "vu-setup";
    runtimeInputs = with pkgs; [
      protontricks
      curl
    ];
    text = ''
      # One-time VU install. Prereqs: BF3 installed via Steam (Proton) and
      # launched once so the EA app is set up; the EA app must be running
      # during THIS setup only (it stays open after closing BF3) — normal
      # VU launches later don't need it.
      steamlib="''${STEAM_LIBRARY:-$HOME/.local/share/Steam}"
      pfx="$steamlib/steamapps/compatdata/${appid}/pfx"
      if [ ! -d "$pfx" ]; then
        echo "BF3 Proton prefix not found: $pfx" >&2
        echo "Install BF3 via Steam and launch it once first." >&2
        echo "(Steam library elsewhere? Re-run with STEAM_LIBRARY=/path/to/Steam)" >&2
        exit 1
      fi
      installer="''${XDG_CACHE_HOME:-$HOME/.cache}/vu-installer.exe"
      echo ">> Downloading the latest VU installer..."
      curl -fLo "$installer" https://veniceunleashed.net/files/vu.exe
      echo ">> Running the installer inside the BF3 prefix (keep default paths)..."
      protontricks-launch --appid ${appid} "$installer"
      echo ">> Installing d3dcompiler_47 into the prefix..."
      protontricks ${appid} d3dcompiler_47
      echo ">> Done. Launch with: vu (or the Venice Unleashed desktop entry)"
    '';
  };

  vu-server = pkgs.writeShellApplication {
    name = "vu-server";
    runtimeInputs = [ pkgs.protontricks ];
    text = ''
      # Dedicated VU server (for hosting / mod development). Uses the default
      # instance dir inside the BF3 prefix; own mods go into Admin/Mods and
      # are activated by listing their folder names in Admin/ModList.txt.
      steamlib="''${STEAM_LIBRARY:-$HOME/.local/share/Steam}"
      pfx="$steamlib/steamapps/compatdata/${appid}/pfx"
      exe="$pfx/drive_c/users/steamuser/AppData/Local/VeniceUnleashed/client/vu.exe"
      # default instance dir per VU docs: "My Documents\Battlefield 3\Server"
      inst="$pfx/drive_c/users/steamuser/Documents/Battlefield 3/Server"
      if [ ! -f "$exe" ]; then
        echo "vu.exe not found — run vu-setup first." >&2
        exit 1
      fi
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
      # Launch Venice Unleashed. --verify: re-check BF3 ownership with EA.
      steamlib="''${STEAM_LIBRARY:-$HOME/.local/share/Steam}"
      exe="$steamlib/steamapps/compatdata/${appid}/pfx/drive_c/users/steamuser/AppData/Local/VeniceUnleashed/client/vu.exe"
      if [ ! -f "$exe" ]; then
        echo "vu.exe not found under $exe — run vu-setup first." >&2
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
