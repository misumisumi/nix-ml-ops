topLevel@{ flake-parts-lib, inputs, ... }: {
  imports = [
    ./ld-fallback.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.ldFallbackManylinux = {
    imports = [
      topLevel.config.flake.flakeModules.ldFallback
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ system, lib, pkgs, ... }: {
      ml-ops.common = { config, ... }: {

        config.ldFallback.libraries = builtins.filter (package: !package.meta.unsupported) [
          pkgs.glibc
          pkgs.libgcc.lib
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
