{
  description = "A Nix-flake-based development environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    checks = forAllSystems (system: {
      pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          commitizen.enable = true;
        };
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;

        # create an environment with nushell
        packages = let
          # https://lazamar.co.uk/nix-versions/?package=nushell&version=0.95.0&fullName=nushell-0.95.0&keyName=nushell&revision=05bbf675397d5366259409139039af8077d695ce&channel=nixpkgs-unstable#instructions
          pkgs = import (builtins.fetchGit {
            name = "nushell-0.95.0";
            url = "https://github.com/NixOS/nixpkgs/";
            ref = "refs/heads/nixpkgs-unstable";
            rev = "05bbf675397d5366259409139039af8077d695ce";
          }) {};
        in [
          pkgs.nushell
        ];
      };
    });
  };
}
