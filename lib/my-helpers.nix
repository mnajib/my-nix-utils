# my-nix-utils/lib/my-helpers.nix
# lib/my-helpers.nix
{ lib, nixConfigRoot ? ./., ... }:

let
  importAllModules = path:
    let
      fullPath = "${nixConfigRoot}/${path}";
      go = dir:
        lib.filterAttrs (n: v: v != null) (lib.mapAttrs (name: type:
          let currentPath = "${dir}/${name}";
          in
          if type == "directory"
          then go currentPath
          else if lib.hasSuffix ".nix" name
          then import currentPath
          else null
        ) (lib.readDir dir));
    in go fullPath;

  scanHostDirs = path:
    let fullPath = "${nixConfigRoot}/${path}"; in
    lib.filterAttrs (name: type: type == "directory") (lib.readDir fullPath)
    // lib.mapAttrs (name: type: "${fullPath}/${name}") (lib.readDir fullPath);

  scanUserConfigs = usersPath:
    let fullUsersPath = "${nixConfigRoot}/${usersPath}"; in
    lib.mapAttrs (userName: userType:
      let
        userDir = "${fullUsersPath}/${userName}";
        userCommonConfig =
          if lib.pathExists "${userDir}/default.nix"
          then "${userDir}/default.nix"
          else null;
        userHostConfigs =
          lib.filterAttrs (hostName: hostType:
            hostType == "directory" &&
            lib.pathExists "${userDir}/${hostName}/default.nix"
          ) (lib.readDir userDir)
          // lib.mapAttrs (hostName: hostType:
              "${userDir}/${hostName}/default.nix"
            ) (lib.readDir userDir);
      in
      {
        common = userCommonConfig;
        hosts = userHostConfigs;
      }
    ) (lib.filterAttrs (name: type: type == "directory") (lib.readDir fullUsersPath));

in {
  inherit importAllModules scanHostDirs scanUserConfigs nixConfigRoot;

  # For REPL/flake show visibility
  greeting = name: "Hello, ${name} from my-nix-utils!";
  version = "0.1.0";
}

