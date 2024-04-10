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
      config = lib.optionalAttrs (system != "aarch64-darwin")
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.cudaSupport = true;
        }
      // {
        ml-ops.common = common:
          let
            version = if common.config.cuda.version == null then "" else "_${builtins.replaceStrings [ "." ] [ "_" ] common.config.cuda.version}";
            cudaVerPackages = pkgs."cudaPackages${version}";
            cudaPackages = common.config.cuda.packages cudaVerPackages;
          in
          {
            options.cuda.home = lib.mkOption {
              type = lib.types.package;
              default = pkgs.symlinkJoin {
                name = "cuda-home";
                paths = cudaPackages;
              };
            };
            options.cuda.version = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            options.cuda.packages = lib.mkOption {
              type = lib.types.functionTo (lib.types.listOf lib.types.package);
              default = cp: with cp; [
                # TODO: Figure out if we can use `pkgs.cudaPackages.cuda_nvcc.lib` instead of `pkgs.cudaPackages.cuda_nvcc`. The `.lib` one is smaller.
                cuda_nvcc

                # TODO: Remove `pkgs.cudaPackages.cudatoolkit` in favor of fine-grained packages.
                cudatoolkit

                # TODO: Figure out if we can use `pkgs.cudaPackages.cuda_cudart.lib` instead of `pkgs.cudaPackages.cuda_cudart`. The `.lib` one is smaller.
                cuda_cudart

                # TODO: Figure out if we can use `pkgs.cudaPackages.libcublas.lib` instead of `pkgs.cudaPackages.libcublas`. The `.lib` one is smaller.
                libcublas

                nccl

                # TODO: Figure out if we can use `pkgs.cudaPackages.cudnn.lib` instead of `pkgs.cudaPackages.cudnn`. The `.lib` one is smaller.
                cudnn
              ];
            };
          } // lib.optionalAttrs (system != "aarch64-darwin") {
            config.LD_LIBRARY_PATH = lib.mkMerge [
              "/run/opengl-driver/lib"
              # bitsandbytes need to search for CUDA libraries
              "${common.config.environmentVariables.CUDA_HOME}/lib"
            ];
            config.devenvShellModule.packages = [
              common.config.cuda.home
            ];

            config.environmentVariables.CUDA_HOME = toString (common.config.cuda.home);

            config.devenvShellModule.containers.processes.layers =
              lib.mkBefore (
                builtins.map (cudaPackage: { deps = [ cudaPackage ]; }) cudaPackages
              );
          };
      };
    });
  };
}
