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

          metallicFlock = pkgs.callPackage ./apps/metallic-flock/package.nix {
            workspaceRoot = ./.;
            gitCommit = self.shortRev or self.dirtyShortRev or "unknown";
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
          packages = rec {
            metallic-flock = metallicFlock;
            default = metallic-flock;
          };

          devShells = {
            default = pkgs.mkShell {
              inputsFrom = [ metallicFlock ];

              packages = corePackages ++ devOnlyPackages;

              BASH_COMPLETION_PATH =
                "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh";

              shellHook = ''
                echo "Nix devShell ready. Tools: $(go version 2>/dev/null)"
              '';
            };

            ci = pkgs.mkShell {
              inputsFrom = [ metallicFlock ];

              packages = corePackages;
            };
          };
        }))
      {
        nixosModules = rec {
          metallic-flock = import ./apps/metallic-flock/system.nix {
            inherit self;
          };

          default = metallic-flock;
        };

        packages.x86_64-linux.metallic-image =
          let
            system = "x86_64-linux";
            releaseRef = import ./apps/metallic-image/release-ref.nix;
          in
          (nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              metallic-flock-pkg = self.packages.${system}.metallic-flock;
              clusterConfig = import ./apps/metallic-image/default-config.nix;
              inherit releaseRef;
            };

            modules = [
              {
                nixpkgs.config.allowUnfree = true;
              }

              self.nixosModules.metallic-flock
              ./apps/metallic-image/image.nix
            ];
          }).config.system.build.isoImage;
      };
}