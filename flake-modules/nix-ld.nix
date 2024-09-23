topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    ./common.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.nixLd = {
    imports = [
      topLevel.config.flake.flakeModules.common
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ system, lib, config, pkgs, ... }: {
      ml-ops.common = common: {
        options.nixLdLibraries = lib.mkOption {
          description = ''
            The list of paths to be added to the `NIX_LD_LIBRARY_PATH` environment variable.

            This option should always be kept empty. Set `flakeModules.ldFallback.libraries` instead when you want any non-empty library path. See discussion at https://github.com/NixOS/nixpkgs/pull/248547#issuecomment-1995469926 about why nix-ld is not a good idea for libraries used in a project.

            Note that `nix-ld` is still a good idea for executing non-Nix binaries in the case of https://github.com/nix-community/NixOS-WSL/issues/222. When there are system level `NIX_LD_LIBRARY_PATH` set for `nix-ld`, this option should be kept as empty in order to disable the system level `NIX_LD_LIBRARY_PATH`.
          '';

          type = lib.types.listOf lib.types.path;
          default = [ ];

        };

        config.environmentVariables = {
          NIX_LD = "${pkgs.runCommand "ld.so" { } ''
            mkdir -p "$out/lib"
            ln -s "$(< ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" "$out"/lib/ld.so
          ''}/lib/ld.so";
          NIX_LD_LIBRARY_PATH = lib.makeLibraryPath common.config.nixLdLibraries;
        };

      };

    });
  };
}
