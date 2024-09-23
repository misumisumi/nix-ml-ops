{
  flake.nixosModules.nixLd = { pkgs, ... }: {
    programs.nix-ld = {
      enable = true;
      libraries = [
        pkgs.stdenv.cc.cc
      ];
    };
  };
}
