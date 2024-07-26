# Cardano DB Sync NixOS Modules

This is an attempt to factor out all the non-build logic out of the [Cardano DB
Sync](https://github.com/IntersectMBO/cardano-db-sync) repository.

This Nix flake includes:

 * DB Sync NixOS modules
 * DB Sync Docker builds

## Usage

### NixOS Module

To add this to a NixOS system flake, add flake inputs to the DB Sync source and this flake:

    inputs = {
      cardanoDbSync.url = github:IntersectMBO/cardano-db-sync;
      dbSyncNix = {
        url = github:sgillespie/cardano-db-sync-nixos;
        inputs.dbSync.follows = "cardanoDbSync";
      };

      # <-- Other inputs -->
    };

Then use it like a normal NixOS module:

    outputs = { self, nixpkgs, dbSyncNix, ... }: {
      nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"
        modules = [
          dbSyncNix.nixosModules.cardano-db-sync
          ./configuration
        ];
      };
    };

### Docker Image

To build cardano-db-sync:

    nix build \
      github:sgillespie/cardano-db-sync-nixos#cardano-db-sync-docker

Or, build a specific tag:

    nix build \
      github:sgillespie/cardano-db-sync-nixos#cardano-db-sync-docker \
      --override-input dbSync github:IntersectMBO/cardano-db-sync\?ref=13.3.0.0

Add the image to docker:

    docker load < result
