topLevel@{ inputs, flake-parts-lib, ... }: {
  imports = [
    ./devcontainer.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.devcontainerPoetry = flakeModule: {
    imports = [
      topLevel.config.flake.flakeModules.devcontainer
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption
      ({ lib, system, pkgs, ... }: {
        ml-ops.devcontainer = devcontainer: {
          options.poetry-add-requirements-txt = lib.mkOption {
            type = lib.types.package;
            default = devcontainer.config.poetry2nix.poetry2nixLib.mkPoetryApplication {
              projectDir = inputs.poetry-add-requirements-txt;
              preferWheels = true;
            };
          };
          config.devenvShellModule = {
            scripts.import-requirements-to-poetry.exec = ''
              if [ ! -f ./pyproject.toml ]
              then
                poetry init --no-interaction
              fi
              if [ ! -f ./poetry.lock ]
              then
                if [ -f ./requirements.txt ]
                then
                  ${devcontainer.config.poetry-add-requirements-txt}/bin/poeareq ./requirements.txt
                fi
                if [ -f ./requirements-dev.txt ]
                then
                  ${devcontainer.config.poetry-add-requirements-txt}/bin/poeareq -D ./requirements-dev.txt
                fi
              fi
            '';
            languages.python.enable = true;
            languages.python.poetry.enable = true;
          };
        };

      });
  };
}
