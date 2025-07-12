# my-nix-utils/flake.nix
{
  description = "Reusable NixOS and Home-Manager Flake Utilities by Najib";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        # STEP 1: Define config.nixConfigRoot FIRST!
        ./lib/flake-parts/configRoot.nix

        # STEP 2: Then use it when importing helpers
        ({ config, lib, ... }:
          let
            helpers = import ./lib/my-helpers.nix {
              inherit lib;
              nixConfigRoot = config.nixConfigRoot;
            };
          in {
            flake.flakePartsModules = {
              my-systems = import ./lib/flake-parts/systems.nix { inherit inputs lib helpers; };
              my-homes   = import ./lib/flake-parts/homes.nix   { inherit inputs lib helpers; };
              my-modules = import ./lib/flake-parts/modules.nix { inherit inputs lib helpers; };
            };

            flake.lib.my-helpers = helpers;
          }
        )
      ];
    };
}
