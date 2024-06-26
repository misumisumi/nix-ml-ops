topLevel@{ inputs, flake-parts-lib, ... }: {
  imports = [
    ./common.nix
    ./vscode.nix
    ./python-vscode.nix
    ./python-package.nix
    ./runtime.nix
    ./poetry2nix.nix
    ./devcontainer-poetry.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.pythonEnvsPoetry = flakeModule: {
    imports = [
      topLevel.config.flake.flakeModules.common
      topLevel.config.flake.flakeModules.vscode
      topLevel.config.flake.flakeModules.pythonVscode
      topLevel.config.flake.flakeModules.pythonPackage
      topLevel.config.flake.flakeModules.runtime
      topLevel.config.flake.flakeModules.poetry2nix
      topLevel.config.flake.flakeModules.devcontainerPoetry
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption
      ({ lib, system, pkgs, ... }: {
        ml-ops.runtime = runtime: {
          options.poetryEnvArgs = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          config.poetryEnvArgs = runtime.config.poetry2nix.args;
          options.poetryEnv = lib.mkOption {
            type = lib.types.package;
            default = runtime.config.poetry2nix.poetry2nixLib.mkPoetryEnv runtime.config.poetryEnvArgs;
          };
          config.devenvShellModule.packages = lib.mkIf (builtins.pathExists "${flakeModule.self}/poetry.lock") [
            runtime.config.poetryEnv
          ];
        };
      });
  };
}
