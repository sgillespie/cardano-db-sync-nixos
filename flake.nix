{
  description = "cardano-db-sync";

  inputs = {
    nixpkgs.follows = "dbSync/nixpkgs";
    dbSync.url = github:IntersectMBO/cardano-db-sync;
    utils.url = github:numtide/flake-utils;

    iohkNix = {
      url = "github:input-output-hk/iohk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, dbSync, iohkNix, utils, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
      ];
    in
      utils.lib.eachSystem supportedSystems (system:
        let
          project = dbSync.packages."${system}".project;

          pkgs = import nixpkgs {
            inherit system;

            overlays =
              builtins.attrValues iohkNix.overlays ++ [
              (final: prev: {
                cardano-cli = dbSync.legacyPackages."${system}".cardano-cli;
                cardano-node = dbSync.legacyPackages."${system}".cardano-node;
                cardano-db-sync = dbSync.legacyPackages."${system}".cardano-db-sync;
                cardano-db-tool = dbSync.legacyPackages."${system}".cardano-db-tool;
                cardano-smash-server = dbSync.legacyPackages."${system}".cardano-smash-server;
                cardano-db-sync-src = dbSync.outPath;
                schema = "${dbSync.outPath}/schema";
              })
            ];
          };

          docker = pkgs.callPackage ./docker.nix {
            inherit (inputs.iohkNix.lib) evalService;
          };
          inherit (docker) cardano-db-sync-docker cardano-smash-server-docker;
        in {
          packages = {
            inherit cardano-db-sync-docker cardano-smash-server-docker;
          };

          legacyPackages = pkgs;
      }) // {
        nixosModules = {
          cardano-db-sync = { pkgs, lib, ... }: {
            imports = [ ./nixos/cardano-db-sync-service.nix ];
            services.cardano-db-sync.dbSyncPkgs =
              let
                pkgs' = self.legacyPackages.${pkgs.system};
              in {
                inherit (pkgs')
                  cardanoLib
                  cardano-db-sync
                  schema;

                # cardano-db-tool
                cardanoDbSyncHaskellPackages.cardano-db-tool.components.exes.cardano-db-tool =
                  pkgs'.cardano-db-tool;
              };
          };
        };
      };

  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
    allow-import-from-derivation = true;
    experimental-features = [ "nix-command" "flakes" "fetch-closure" ];
  };
}
