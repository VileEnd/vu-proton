{
  description = "Venice Unleashed (BF3 mod platform) on Linux via Steam Proton — install, launch and dedicated-server helpers";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      # BF3/Proton is x86_64-only
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      vuPkgs = import ./vu.nix { inherit pkgs; };
    in
    {
      packages.x86_64-linux = vuPkgs // {
        default = vuPkgs.vu;
      };
      formatter.x86_64-linux = pkgs.nixfmt-tree;
    };
}
