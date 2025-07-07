# my-nix-utils/flake.nix
#
# This flake is itself a flake-parts flake. It defines its flake.flakePartsModules
# output attribute, which contains the my-systems, my-homes, and my-modules definitions.
# These are essentially "sub-modules" that know how to generate specific parts of a
# larger flake's outputs.
#
# your-configs/flake.nix: When you specify my-nix-utils.inputs.flakePartsModules.<name>
# in your imports list, flake-parts takes these imported modules and applies them to
# your flake's definition. This effectively runs the logic from your helper flake's
# systems.nix (which scans your local profiles/ directory) and wires everything up
# automatically.
#

{
  description = "Reusable NixOS and Home-Manager Flake Utilities by YourName";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin" # Add macOS if your helpers support it
        "aarch64-darwin"
      ];

      # Define an option for the root directory of the consuming flake's Nix files
      options.flake.config.nixConfigRoot = lib.mkOption {
        type = lib.types.str;
        default = "./"; # Default to current directory if not specified (for direct usage)
        description = "Root directory for Nix configurations in the consuming flake (e.g., './nix').";
      };

      imports = [
        ({ config, lib, ... }:
          let
            # Pass the configured nixConfigRoot to my-helpers.nix
            helpers = import ./lib/my-helpers.nix { inherit lib; nixConfigRoot = config.nixConfigRoot; };
          in
          {
            flake.flakePartsModules = {
              # Pass the initialized 'helpers' object to your specific flake-parts modules
              my-systems = import ./lib/flake-parts/systems.nix { inherit inputs lib helpers; };
              my-homes = import ./lib/flake-parts/homes.nix { inherit inputs lib helpers; };
              my-modules = import ./lib/flake-parts/modules.nix { inherit inputs lib helpers; };
            };
            # Optionally expose helpers for direct use in the consuming flake
            flake.lib.my-helpers = helpers;
          }
        )
      ];
    };
}
