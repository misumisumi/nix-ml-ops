topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    ./ld-floxlib.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.ldFloxlibManylinux = {
    imports = [
      topLevel.config.flake.flakeModules.ldFloxlib
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ system, lib, pkgs, ... }: {
      ml-ops.common = { config, ... }: {

        config.ldFloxlib.floxEnvLibraries = builtins.filter (package: !package.meta.unsupported) [
          pkgs.zlib
          pkgs.zstd
          pkgs.stdenv.cc.cc
          pkgs.curl
          pkgs.openssl
          pkgs.attr
          pkgs.libssh
          pkgs.bzip2
          pkgs.libxml2
          pkgs.acl
          pkgs.libsodium
          pkgs.util-linux
          pkgs.xz
          pkgs.systemd
        ];
      };

    });
  };
}
