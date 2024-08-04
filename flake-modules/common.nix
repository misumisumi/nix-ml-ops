topLevel@{ inputs, flake-parts-lib, ... }: {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    ./nixpkgs.nix
  ];
  flake.flakeModules.common = flakeModule: {
    imports = [
      topLevel.config.flake.flakeModules.nixpkgs
      inputs.devenv.flakeModule
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ lib, ... }: {
      config.nixpkgs.config.allowUnsupportedSystem = true;

      options.ml-ops.common = lib.mkOption {
        default = { };
        type = lib.types.deferredModuleWith {
          staticModules = [
            ({ config, ... }: {
              options.version = lib.mkOption {
                type = lib.types.str;
                defaultText = lib.literalMD "1.0.0+<lastModifiedDate>.<git-revision>.<narHash>";
                default = "1.0.0+${
                  flakeModule.self.lastModifiedDate
                }.${
                  flakeModule.self.shortRev or flakeModule.self.dirtyShortRev
                }.${
                  # Don't use `convertHash` because it is not available in the latest stable nix version 2.18
                  # builtins.convertHash {
                  #   hash = flakeModule.self.narHash;
                  #   toHashFormat = "nix32";
                  # }

                  # semver only allows alphanumeric characters and hyphens
                  builtins.replaceStrings ["=" "+" "/"] ["" "-" "-"] flakeModule.self.narHash
                }";
                description = ''
                  Version of job or service.
                  This will be used as the image tag.
                '';
              };
              options.LD_LIBRARY_PATH = lib.mkOption {
                type = lib.types.envVar;
                default = "";
              };
              options.environmentVariables = lib.mkOption {
                type = lib.types.lazyAttrsOf lib.types.str;
                default = { };
                description = ''
                  Environment variables for either devcontainer, jobs or services.

                  For devcontainer, these variables will be copied to via `devenv`'s [env](https://devenv.sh/reference/options/#env) config.
                  For kubernetes jobs and services, these variables will be copied to the Pods' `spec.containers.*.env` field.
                '';
              };
              options.devenvShellModule = lib.mkOption {
                description = ''
                  Common config that will be copied to `config.devenv.shells.`*<shell_name>*`.config` for each shell.

                  See [devenv options](https://devenv.sh/reference/options/) for supported nested options.
                '';
                default = { };
                type = lib.types.deferredModuleWith {
                  staticModules = [ ];
                };
              };
              config.devenvShellModule.env = config.environmentVariables;
              config.devenvShellModule.devenv.root =
                let
                  devenvRootFileContent = builtins.readFile inputs.devenv-root.outPath;
                in
                lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

              config.devenvShellModule.enterShell = ''
                export LD_LIBRARY_PATH=${config.LD_LIBRARY_PATH}:''${LD_LIBRARY_PATH:-}
              '';
            })
          ];
        };
        description = ''
          Settings shared between devcontainer and all jobs and services.
          For example, config of `perSystem.ml-ops.common.xxx` will be copied to `perSystem.ml-ops.devcontainer.xxx`, all `perSystem.ml-ops.jobs.<name>.xx` and all `perSystem.ml-ops.services.<name>.xxx`.
        '';
      };
    });
  };
}
