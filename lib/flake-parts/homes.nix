# lib/flake-parts/homes.nix
#
# Currently there isn't an implicit "hostname" context. If you want host-specific user configurations
# in standalone mode, you'd typically need to create distinct outputs like homeConfigurations.username@hostname1
# and homeConfigurations.username@hostname2. This requires more complex logic in homes.nix to iterate over users
# and their hosts. For simplicity, the example below will only include the globalUserCommonModule and
# userSpecificCommonModule for standalone configs. If you require host-specific standalone configurations,
# you'll need to expand this module or define those outputs manually in flake.nix.
#

{ inputs, lib, helpers, ... }: # Add 'helpers' here

let
  profilesUsersPath = "profiles/users";
  allUserConfigs = helpers.scanUserConfigs profilesUsersPath;
in {
  perSystem = { system, pkgs, ... }: {
    homeConfigurations = lib.mapAttrs' (userName: userConfig:
      lib.nameValuePair userName (
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = lib.cleanFilter (x: x != null) [
            "${helpers.nixConfigRoot}/${profilesUsersPath}/common/default.nix" # Global common user config
            userConfig.common                   # User-specific common config
            # Host-specific user configs are generally not included in generic standalone outputs.
            # If needed, you'd define separate outputs like homeConfigurations."username-hostname".
            # inputs.self.homeManagerModules.my-custom-hm-app # Example custom module
          ];
          specialArgs = { inherit inputs; };
        }
      )
    ) allUserConfigs;
  };
}
