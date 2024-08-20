topLevel@{ flake-parts-lib, inputs, lib, ... }: {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    ./common.nix
  ];
  flake.flakeModules.devcontainer = {
    imports = [
      topLevel.config.flake.flakeModules.common
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption (perSystem @{ system, pkgs, ... }: {
      options.ml-ops.devcontainer = lib.mkOption {
        description = ''
          Configuration for the development environment.
        '';
        default = { };
        type = lib.types.submoduleWith {
          modules = [
            (devcontainer: {
              imports = [ perSystem.config.ml-ops.common ];
              options.nixago.copiedFiles = lib.mkOption {
                type = lib.types.listOf lib.types.str;
              };
              options.nixago.requests = lib.mkOption {
                type = lib.types.submoduleWith {
                  modules = [{
                    _module.freeformType = lib.types.attrsOf lib.types.deferredModule;
                  }];
                };
                default = { };
              };
              options.gitignore = lib.mkOption {
                type = lib.types.listOf lib.types.str;
              };
              config.gitignore = [
                ".direnv/"
                ".devenv/"
                ".envrc.private"
                "result"
                ".pre-commit-config.yaml"
              ];
              options.gitattributes = lib.mkOption {
                type = lib.types.lines;
              };
              config.gitattributes = lib.mkMerge
                (
                  [
                    ''
                      # Generated by devenv when running `direnv reload`
                      .devcontainer.json linguist-generated
                    ''
                  ] ++
                  (builtins.map
                    (fileName: ''
                      # Generated by nixago when running `direnv reload`
                      ${fileName} linguist-generated
                    '')
                    devcontainer.config.nixago.copiedFiles
                  )
                );

              config.nixago.copiedFiles = [ ".gitattributes" ".envrc" ];
              config.nixago.requests.".gitattributes" = {
                data = devcontainer.config.gitattributes;

                engine = { data, output, ... }: pkgs.writeTextFile {
                  name = output;
                  text = data;
                };
              };
              config.nixago.requests.".envrc" = {
                data = ''
                  if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
                    source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="
                  fi

                  nix_direnv_watch_file flake.nix
                  nix_direnv_watch_file flake.lock

                  DEVENV_ROOT_FILE="$(mktemp)"
                  printf %s "$PWD" > "$DEVENV_ROOT_FILE"

                  dotenv_if_exists .env
                  source_env_if_exists .envrc.private

                  use flake . ${devcontainer.config.rawNixDirenvFlakeFlags}
                '';
                engine = { data, output, ... }: pkgs.writeTextFile {
                  name = output;
                  text = data;
                };
              };
              options.rawNixDirenvFlakeFlags = lib.mkOption {
                type = lib.types.separatedString " ";
                default = "--override-input nix-ml-ops/devenv-root \"file+file://$DEVENV_ROOT_FILE\" ${lib.escapeShellArgs devcontainer.config.nixDirenvFlakeFlags}";
              };
              options.nixDirenvFlakeFlags = lib.mkOption {
                type = lib.types.listOf lib.types.str;
              };
              config.nixDirenvFlakeFlags = [
                # Disable Nix's eval-cache so that we can always see error messages if any.
                "--no-eval-cache"

                # Environment variables are cached by direnv, so we don't need Nix's eval-cache.
                "--show-trace"
              ];
              options.mountVolumeWithSudo = lib.mkOption {
                default = true;
              };
              config.devenvShellModule = {
                name = "devcontainer";

                devcontainer.enable = true;
                devcontainer.settings.updateContentCommand = "direnv allow";

                packages = [
                  pkgs.git
                  pkgs.openssh
                ];
                enterShell =
                  lib.mkMerge
                    ([
                      (lib.escapeShellArgs (
                        [
                          (lib.getExe' pkgs.git-extras "git-ignore")
                        ] ++ devcontainer.config.gitignore
                      ))

                      (inputs.nixago.lib.${system}.makeAll (
                        lib.attrsets.mapAttrsToList
                          (output: request: {
                            imports = [ request ];
                            config.output = output;
                            config.hook.mode = lib.mkIf (builtins.elem output devcontainer.config.nixago.copiedFiles) "copy";
                          })
                          devcontainer.config.nixago.requests
                      )).shellHook
                    ] ++ (
                      builtins.concatMap
                        (lib.attrsets.mapAttrsToList
                          (mountPath: protocolConfig:
                            if devcontainer.config.mountVolumeWithSudo then
                              lib.escapeShellArgs [
                                "sudo"
                                "bash"
                                "-c"
                                protocolConfig.mountScript
                              ]
                            else
                              protocolConfig.mountScript)
                        )
                        (builtins.attrValues (devcontainer.config.volumeMounts or { }))
                    ));
              };
            })
          ];
        };
      };

      config = {
        devenv.shells.default = {
          imports = [ perSystem.config.ml-ops.devcontainer.devenvShellModule ];
        };
      };
    });
  };
}
