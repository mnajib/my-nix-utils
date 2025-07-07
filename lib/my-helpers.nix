# my-nix-utils/lib/my-helpers.nix
# This file now takes `nixConfigRoot` as an argument to its overall function
{ lib, nixConfigRoot, ... }:

let
  # Function to recursively import all .nix files under a given path (relative to nixConfigRoot)
  importAllModules = path:
    let
      fullPath = "${nixConfigRoot}/${path}"; # Prepend nixConfigRoot
      go = dir:
        lib.filterAttrs (n: v: v != null) (lib.mapAttrs (name: type:
          let
            currentPath = "${dir}/${name}";
          in
          if type == "directory"
          then (go currentPath)
          else if lib.hasSuffix ".nix" name
          then import currentPath
          else null
        ) (lib.readDir dir));
    in
    go fullPath;

  # Scans profiles/hosts to get paths to host *directories*.
  # The calling module (systems.nix) will then look for default.nix, configuration.nix, etc. inside.
  # Returns: { hostname = "/absolute/path/to/nix/profiles/hosts/hostname"; ... }
  scanHostDirs = path:
    let fullPath = "${nixConfigRoot}/${path}"; in # Prepend nixConfigRoot
    lib.filterAttrs (name: type: type == "directory") (lib.readDir fullPath)
    // lib.mapAttrs (name: type: "${fullPath}/${name}") (lib.readDir fullPath);

  # Scans profiles/users to get paths to user default.nix files and host-specific user files.
  # Returns absolute paths for the config files.
  scanUserConfigs = usersPath:
    let fullUsersPath = "${nixConfigRoot}/${usersPath}"; in # Prepend nixConfigRoot
    lib.mapAttrs (userName: userType:
      let
        userDir = "${fullUsersPath}/${userName}";
        userCommonConfig = if lib.pathExists "${userDir}/default.nix"
                           then "${userDir}/default.nix"
                           else null;
        userHostConfigs = lib.filterAttrs (hostName: hostType:
          hostType == "directory" && lib.pathExists "${userDir}/${hostName}/default.nix"
        ) (lib.readDir userDir) // lib.mapAttrs (hostName: hostType: "${userDir}/${hostName}/default.nix") (lib.readDir userDir);
      in
      {
        common = userCommonConfig;
        hosts = userHostConfigs;
      }
    ) (lib.filterAttrs (name: type: type == "directory") (lib.readDir fullUsersPath));

in {
  inherit importAllModules scanHostDirs scanUserConfigs;
  # Also expose nixConfigRoot in helpers for debugging or direct path construction if needed
  inherit nixConfigRoot;
}
