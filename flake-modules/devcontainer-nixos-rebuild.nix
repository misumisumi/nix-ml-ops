topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    ./devcontainer.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.devcontainerNixosRebuild = {
    imports = [
      topLevel.config.flake.flakeModules.devcontainer
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ lib, config, pkgs, ... }: {
      ml-ops.devcontainer = {
        config.devenvShellModule = devenvShellModule: {

          scripts.nixos-rebuild = {
            description = ''
              A wrapper script of `nix` that will automatically insert the extra arguments configured in `devenv.flakeArgs` when running supported subcommands.
            '';
            exec = ''
              exec ${lib.getExe pkgs.nixos-rebuild} ${lib.escapeShellArgs devenvShellModule.config.devenv.flakeArgs} "$@"
            '';
          };
        };
      };
    });
  };
}
