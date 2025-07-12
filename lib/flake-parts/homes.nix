# my-nix-utils/lib/flake-parts/homes.nix
#
# Currently there isn't an implicit "hostname" context. If you want host-specific user configurations
# in standalone mode, you'd typically need to create distinct outputs like homeConfigurations.username@hostname1
# and homeConfigurations.username@hostname2. This requires more complex logic in homes.nix to iterate over users
# and their hosts. For simplicity, the example below will only include the globalUserCommonModule and
# userSpecificCommonModule for standalone configs. If you require host-specific standalone configurations,
# you'll need to expand this module or define those outputs manually in flake.nix.
#

{ inputs, lib, helpers, ... }:

let
  profilesUsersPath = "profiles/users";
  allUserConfigs = helpers.scanUserConfigs profilesUsersPath;
in {
  flake.homeConfigurations = lib.mapAttrs' (userName: userConfig:
    lib.nameValuePair "${userName}@${hostname}" (
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        modules = lib.cleanFilter (x: x != null) [
          "${helpers.nixConfigRoot}/${profilesUsersPath}/common/default.nix" # Global common
          userConfig.common
        ];
        extraSpecialArgs = {
          inherit inputs;
        };
      }
    )
  ) allUserConfigs;
}
