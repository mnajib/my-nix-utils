# my-nix-utils/lib/my-helpers.nix
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
        ) (builtins.readDir dir));  # <-- FIXED HERE
    in go fullPath;

  scanHostDirs = path:
    let fullPath = "${nixConfigRoot}/${path}"; in
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir fullPath)  # <-- FIXED
    // lib.mapAttrs (name: type: "${fullPath}/${name}") (builtins.readDir fullPath);  # <-- FIXED

    scanUserConfigs = usersPath:
      let
        fullUsersPath = "${nixConfigRoot}/${usersPath}";
        userDirs = lib.filterAttrs (_: type: type == "directory") (lib.readDir fullUsersPath);
      in
      lib.mapAttrs (userName: _:
        let
          userDir = "${fullUsersPath}/${userName}";
          entries = lib.readDir userDir;
          userCommonConfig =
            if entries ? "default.nix"
            then "${userDir}/default.nix"
            else null;

          hostDirs = lib.filterAttrs (name: type:
            type == "directory" &&
            lib.pathExists "${userDir}/${name}/default.nix"
          ) entries;

          hostConfigs = lib.mapAttrs (hostName: _:
            "${userDir}/${hostName}/default.nix"
          ) hostDirs;
        in {
          common = userCommonConfig;
          hosts = hostConfigs;
        }
      ) userDirs;


in {
  inherit importAllModules scanHostDirs scanUserConfigs nixConfigRoot;

  # For REPL/flake show visibility
  greeting = name: "Hello, ${name} from my-nix-utils!";
  version = "0.1.0";
}
