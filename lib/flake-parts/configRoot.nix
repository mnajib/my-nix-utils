# my-nix-utils/lib/flake-parts/configRoot.nix
{ lib, ... }: {
  options.flake.config.nixConfigRoot = lib.mkOption {
    type = lib.types.str;
    default = "./";
    description = "Root directory for Nix configurations in the consumer flake (e.g., ./nix)";
  };
}
