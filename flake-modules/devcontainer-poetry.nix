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
              projectDir = pkgs.fetchFromGitHub {
                owner = "tddschn";
                repo = "poetry-add-requirements.txt";
                rev = "710dde128b3746e7269e423f46f1e0e432c47043";
                hash = "sha256-BpryyfhKTNPDYIZXHTfHexVPZMhl76L81tsfOGvQKto=";
              };
              preferWheels = true;
            };
          };
          config.gitattributes = ''
            # Avoid merge conflicts in poetry.lock due to conflicting content-hash
            # See https://github.com/python-poetry/poetry/issues/496
            poetry.lock merge=theirs
          '';
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

            pre-commit = {
              hooks.amend-poetry-lock = {
                enable = true;
                stages = [ "post-merge" ];
                entry = lib.getExe (pkgs.writeShellApplication {
                  name = "amend-poetry-lock.sh";
                  runtimeInputs = [
                    pkgs.git
                    pkgs.poetry
                    pkgs.coreutils
                  ];
                  text = ''
                    set -ex
                    if ! git diff --exit-code HEAD^@ -- poetry.lock
                    then
                      poetry lock --no-update &&
                      git add poetry.lock &&
                      GITDIR="$(git rev-parse --git-dir)" &&
                      mv "$GITDIR"/MERGE_HEAD "$GITDIR"/MERGE_HEAD.bak &&
                      git commit --amend --no-edit --no-verify &&
                      mv "$GITDIR"/MERGE_HEAD.bak "$GITDIR"/MERGE_HEAD
                    fi
                  '';
                });
                always_run = true;
              };
            };

            enterShell = ''
              git config --local --replace-all merge.theirs.driver "git merge-file --theirs --marker-size %L %A %O %B"
            '';
          };
        };

      });
  };
}
