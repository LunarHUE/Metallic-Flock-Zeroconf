{
  description = "Flake for the Metallic Flock Zeroconf Library";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    nixpkgs.lib.recursiveUpdate
      (flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # Toolchain shared by local dev and CI.
          corePackages = with pkgs; [
            # Golang tooling
            go
            gopls
            gotools
            golangci-lint

            # Protobuf tooling
            buf

            # Node.js tooling
            nodejs_22
            pnpm

            # System/build tooling
            docker
            gcc
            postgresql

            claude-code
          ];

          # Interactive-only tools.
          devOnlyPackages = with pkgs; [
            bashInteractive
            bash-completion
            nix-bash-completions

            claude-code
            opencode
          ];
        in {
          devShells = {
            default = pkgs.mkShell {
              packages = corePackages ++ devOnlyPackages;

              BASH_COMPLETION_PATH =
                "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh";

              shellHook = ''
                echo "Nix devShell ready. Tools: $(go version 2>/dev/null)"
              '';
            };

            ci = pkgs.mkShell {
              packages = corePackages;
            };
          };
        }))
      {
        
      };
}