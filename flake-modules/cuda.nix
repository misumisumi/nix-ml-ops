topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    ./common.nix
    ./link-nvidia-drivers.nix
  ];
  flake.flakeModules.cuda = {
    imports = [
      topLevel.config.flake.flakeModules.common
      topLevel.config.flake.flakeModules.linkNvidiaDrivers
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ lib, pkgs, system, ... }: {
      config = lib.mkIf (system != "aarch64-darwin") {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.config.cudaSupport = true;

        ml-ops.common = common: {
          config.LD_LIBRARY_PATH = lib.mkMerge [
            "/run/opengl-driver/lib"
            # bitsandbytes need to search for CUDA libraries
            "${common.config.environmentVariables.CUDA_HOME}/lib"
          ];
          config.devenvShellModule.packages = [
            common.config.cuda.home
          ];

          config.environmentVariables.CUDA_HOME = toString (common.config.cuda.home);
          options.cuda.home = lib.mkOption {
            type = lib.types.package;
            default = pkgs.symlinkJoin {
              name = "cuda-home";
              paths = common.config.cuda.packages;
            };
          };
          options.cuda.packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
          };
          config.cuda.packages = [
            # TODO: Figure out if we can use `pkgs.cudaPackages.cuda_nvcc.lib` instead of `pkgs.cudaPackages.cuda_nvcc`. The `.lib` one is smaller.
            pkgs.cudaPackages.cuda_nvcc

            # TODO: Remove `pkgs.cudaPackages.cudatoolkit` in favor of fine-grained packages.
            pkgs.cudaPackages.cudatoolkit

            # TODO: Figure out if we can use `pkgs.cudaPackages.cuda_cudart.lib` instead of `pkgs.cudaPackages.cuda_cudart`. The `.lib` one is smaller.
            pkgs.cudaPackages.cuda_cudart

            # TODO: Figure out if we can use `pkgs.cudaPackages.libcublas.lib` instead of `pkgs.cudaPackages.libcublas`. The `.lib` one is smaller.
            pkgs.cudaPackages.libcublas

            pkgs.cudaPackages.nccl

            # TODO: Figure out if we can use `pkgs.cudaPackages.cudnn.lib` instead of `pkgs.cudaPackages.cudnn`. The `.lib` one is smaller.
            pkgs.cudaPackages.cudnn
          ];
          config.devenvShellModule.containers.processes.layers =
            (
              builtins.foldl'
                (layers: cudaPackage: layers ++ [
                  (inputs.nix2container.packages.${system}.nix2container.buildLayer {
                    deps = [
                      cudaPackage
                    ];
                    inherit layers;
                  })
                ])
                [ ]
                common.config.cuda.packages
            );
        };
      };
    });
  };
}
