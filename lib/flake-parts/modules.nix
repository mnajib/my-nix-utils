# my-nix-utils/lib/flake-parts/modules.nix
{ inputs, lib, helpers, ... }: # Add 'helpers' here

let
  # These paths are now relative to the 'nixConfigRoot' managed by 'helpers'
  modulesNixosPath = "modules/nixos";
  modulesHomeManagerPath = "modules/home-manager";
in {
  flake = {
    nixosModules = helpers.importAllModules modulesNixosPath;
    homeManagerModules = helpers.importAllModules modulesHomeManagerPath;
  };
}
