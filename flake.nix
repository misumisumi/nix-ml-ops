{
  inputs = {
    poetry2nix = {
      url = "github:Atry/poetry2nix/jupyter-existing-provisioner-vllm";
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
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    systems.url = "github:nix-systems/default";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    devenv = {
      # TODO: Switch to `github:cachix/devenv` when https://github.com/cachix/devenv/pull/718, https://github.com/cachix/devenv/pull/820, https://github.com/cachix/devenv/pull/872 and https://github.com/cachix/devenv/pull/873 get merged
      # url = "github:cachix/devenv";
      url = "github:Atry/devenv/nix-ml-ops";
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
  };
  outputs = inputs:
    let
      bootstrap = inputs.flake-parts.lib.mkFlake { inherit inputs; moduleLocation = ./flake.nix; } ({ lib, ... }: {
        imports = (lib.trivial.pipe ./flake-modules [
          builtins.readDir
          (lib.attrsets.filterAttrs (name: type: type == "regular" && lib.strings.hasSuffix ".nix" name))
          builtins.attrNames
          (builtins.map (name: ./flake-modules/${name}))
        ]);
        systems = import inputs.systems;
      });
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      imports = [
        bootstrap.flakeModules.lib
        bootstrap.flakeModules.nixIde
        bootstrap.flakeModules.devserver
        bootstrap.flakeModules.devcontainerGcpCliTools
        bootstrap.flakeModules.devcontainerAzureCliTools
        bootstrap.flakeModules.nixLd
        bootstrap.flakeModules.ldFallbackManylinux
        bootstrap.flakeModules.optionsDocument
      ];
      flake = bootstrap;
    });
}
