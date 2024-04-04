topLevel@{ inputs, flake-parts-lib, ... }: {
  imports = [
    ./devcontainer.nix
    ./kubernetes.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.volumeMountLocal = {
    imports = [
      topLevel.config.flake.flakeModules.devcontainer
      topLevel.config.flake.flakeModules.kubernetes
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption (perSystem@{ lib, pkgs, ... }: {

      ml-ops.runtime = {
        options.volumeMounts.local = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (lib.types.submoduleWith {
            modules = [
              (volumeMount: {
                options.path = lib.mkOption {
                  example = "/ml_data";
                  type = lib.types.str;
                };
                options.nodeAffinity = lib.mkOption {
                  type = lib.types.attrsOf lib.types.anything;
                  default = {
                    required.nodeSelectorTerms = [
                      {
                        matchExpressions = [
                          # Dummy expression to make the volume mount work on any node, only useful for single node clusters
                          { key = "kubernetes.io/hostname"; operator = "Exists"; }
                        ];
                      }
                    ];
                  };
                };
                options.kubernetesVolume = lib.mkOption {
                  defaultText = lib.literalMD "";
                  default = {
                    volumeMode = "Filesystem";
                    storageClassName = "local-storage";
                    local = {
                      inherit (volumeMount.config) path;
                    };
                    inherit (volumeMount.config) nodeAffinity;
                  };
                };
              })
            ];
          });
        };
      };
    });
  };
}
