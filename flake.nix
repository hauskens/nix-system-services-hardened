{
  description = "Hardened systemd service configurations for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      pre-commit-hooks,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      nixosModules.default = import ./default.nix;

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          treefmt = treefmtEval.${system}.config.build.wrapper;
        in
        (import ./tests {
          inherit pkgs;
          lib = nixpkgs.lib;
        })
        // {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            default_stages = [ "pre-commit" ];
            hooks = {
              check-added-large-files.enable = true;
              check-case-conflicts.enable = true;
              check-merge-conflicts.enable = true;
              detect-private-keys.enable = true;
              trim-trailing-whitespace.enable = true;
              end-of-file-fixer.enable = true;

              deadnix = {
                enable = true;
                settings.noLambdaArg = true;
              };

              treefmt = {
                enable = true;
                package = treefmt;
              };
            };
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          checks = self.checks.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (checks.pre-commit-check) shellHook;
            buildInputs = checks.pre-commit-check.enabledPackages;
            nativeBuildInputs = builtins.attrValues {
              inherit (pkgs)
                nix
                git
                just
                pre-commit
                deadnix
                ;
            };
          };
        }
      );
    };
}
