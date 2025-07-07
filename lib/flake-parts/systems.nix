# my-nix-utils/lib/flake-parts/systems.nix
{ inputs, lib, helpers, ... }: # Add 'helpers' here

let
  # These paths are now relative to the 'nixConfigRoot' managed by 'helpers'
  profilesHostsPath = "profiles/hosts";
  profilesUsersPath = "profiles/users";

  # Discover all host directories (excluding 'common')
  # Returns: { hostname = "/absolute/path/to/nix/profiles/hosts/hostname"; ... }
  hostDirs = lib.filterAttrs (n: v: n != "common") (helpers.scanHostDirs profilesHostsPath);

  # Discover all user configurations
  allUserConfigs = helpers.scanUserConfigs profilesUsersPath;

in {
  perSystem = { system, pkgs, ... }: {
    nixosConfigurations = lib.mapAttrs' (hostName: hostDirPath: # hostDirPath is now the absolute path to the host's directory
      let
        # Construct full paths to config files within the host's directory
        hostDefaultNix = "${hostDirPath}/default.nix";
        hostConfigurationNix = "${hostDirPath}/configuration.nix";
        hardwareConfigPath = "${hostDirPath}/hardware-configuration.nix";

        # Dynamically load host modules if they exist
        hostSpecificModules = lib.cleanFilter (x: x != null) [
          (if lib.pathExists hostDefaultNix then import hostDefaultNix else null)
          (if lib.pathExists hostConfigurationNix then import hostConfigurationNix else null)
          (if lib.pathExists hardwareConfigPath then import hardwareConfigPath else null)
        ];

        # Construct home-manager.users for this specific host
        hostUsers = lib.mapAttrs (userName: userConfig:
          let
            # Global common user configuration path (absolute)
            globalUserCommonModule = "${helpers.nixConfigRoot}/${profilesUsersPath}/common/default.nix";

            # Combine all relevant modules for this user on this host
            userModulesForHost = lib.cleanFilter (x: x != null) [
              globalUserCommonModule
              userConfig.common                   # User-specific common config (already absolute path)
              userConfig.hosts.${hostName}        # User-specific host config (already absolute path)
              # You can also include custom Home-Manager modules here
              # Example: inputs.self.homeManagerModules.my-custom-hm-app
            ];
          in
          { imports = userModulesForHost; }
        ) allUserConfigs;
      in
      lib.nameValuePair hostName (
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Global common host configuration (absolute path)
            "${helpers.nixConfigRoot}/${profilesHostsPath}/common/default.nix"
            # ADD THIS LINE for `nix/nixos/common/default.nix`
            "${helpers.nixConfigRoot}/nixos/common/default.nix"
          ] ++ hostSpecificModules ++ [ # Concatenate the dynamically found host modules
            # Integrate Home-Manager for this host
            inputs.home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users = hostUsers;
            }
            # Example: Enable custom NixOS modules from 'my-modules'
            # inputs.self.nixosModules.my-custom-service.enable = true;
          ];
          # Pass special arguments to all modules in the system configuration
          specialArgs = { inherit inputs; };
        }
      )
    ) hostDirs; # Use hostDirs to iterate through found host directories
  };
}
