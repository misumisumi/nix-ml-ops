topLevel@{ inputs, flake-parts-lib, ... }: {
  imports = [
    ./devcontainer.nix
    ./vscode.nix
    inputs.flake-parts.flakeModules.flakeModules
  ];
  flake.flakeModules.nixIde = {
    imports = [
      topLevel.config.flake.flakeModules.devcontainer
      topLevel.config.flake.flakeModules.vscode
    ];
    options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, lib, system, ... }: {
      ml-ops.devcontainer = {
        nixago.requests = {
          ".vscode/settings.json".data = {
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = lib.getExe pkgs.nil;
            "nix.serverSettings" = {
              nil.formatting.command = lib.mkForce [
                (lib.getExe pkgs.nixpkgs-fmt)
              ];
            };
          };
          ".vscode/extensions.json".data = {
            "recommendations" = [
              "jnoortheen.nix-ide"
            ];
          };
        };
        devenvShellModule = {
          languages.nix.enable = true;
        };
      };

      # TODO: Other IDE settings
    });
  };
}
