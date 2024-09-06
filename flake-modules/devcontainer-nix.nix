topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    ./devcontainer.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.devcontainerNix = {
    imports = [
      topLevel.config.flake.flakeModules.devcontainer
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ lib, config, pkgs, ... }: {
      ml-ops.devcontainer = {
        config.devenvShellModule = devenvShellModule: {

          scripts.nix = {
            description = ''
              A wrapper script of `nix` that will automatically insert the extra arguments configured in `devenv.flakeArgs` when running supported subcommands.
            '';
            exec = ''
              case "$1" in
                flake)
                  if [ "$#" -ge 2 ]; then
                    NUMBER_OF_SUB_COMMANDS=2
                  fi
                  ;;
                develop|shell|flake|build|run|check|repl|bundle)
                  NUMBER_OF_SUB_COMMANDS=1
                  ;;
              esac

              if [ -z "''${NUMBER_OF_SUB_COMMANDS+x}" ]; then
                exec ${lib.getExe pkgs.nixVersions.latest} "$@"
              else
                exec ${lib.getExe pkgs.nixVersions.latest} "''${@:1:$NUMBER_OF_SUB_COMMANDS}" ${lib.escapeShellArgs devenvShellModule.config.devenv.flakeArgs} "''${@:$(($NUMBER_OF_SUB_COMMANDS+1))}"
              fi 
            '';
          };
        };
      };
    });
  };
}
