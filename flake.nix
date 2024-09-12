{
  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    conda-channels = {
      url = "github:davhau/conda-channels";
      flake = false;
    };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
      flake = false;
    };
    mach-nix = {
      url = "github:Preemo-Inc/mach-nix";
      flake = false;
    };
    nixpkgs_22_05.url = "nixpkgs/nixos-22.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:Atry/flake-parts/patch-3";
    flake-parts.inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    systems.url = "github:nix-systems/default";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    devenv = {
      # Switch to the upstream devenv flake once the following PRs are merged:
      # - https://github.com/cachix/devenv/pull/1415
      # - https://github.com/cachix/devenv/pull/1418
      # url = "github:cachix/devenv";
      url = "github:Atry/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };
    mk-shell-bin = {
      url = "github:rrbutani/nix-mk-shell-bin";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixago = {
      url = "github:Preemo-Inc/nixago?ref=no-gitignore";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld-rs.url = "github:nix-community/nix-ld-rs";
    nix-gl-host = {
      url = "github:Atry/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;

      # TODO: remove moduleLocation as it is not needed since using partitions
      moduleLocation = ./flake.nix;
    }
    ({ lib, config, ... }: {
      imports = [
        inputs.flake-parts.flakeModules.partitions
      ] ++ (
        lib.pipe ./flake-modules [
          builtins.readDir
          (lib.attrsets.filterAttrs (name: type: type == "regular" && lib.strings.hasSuffix ".nix" name))
          builtins.attrNames
          (builtins.map (name: ./flake-modules/${name}))
        ]
      );
      systems = import inputs.systems;
      partitionedAttrs.devShells = "dev";
      partitionedAttrs.lib = "dev";
      partitions.dev = {
        module = {
          imports = [
            config.flake.flakeModules.lib
            config.flake.flakeModules.nixIde
            config.flake.flakeModules.devserver
            config.flake.flakeModules.devcontainerNix
            config.flake.flakeModules.devcontainerGcpCliTools
            config.flake.flakeModules.devcontainerAzureCliTools
            config.flake.flakeModules.nixLd
            config.flake.flakeModules.ldFallbackManylinux
            config.flake.flakeModules.optionsDocument
          ];
        };
      };
    });
}
