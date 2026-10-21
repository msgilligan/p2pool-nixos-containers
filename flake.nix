{
  description = "Nix Bitcoin RegTest VM Flake";

  inputs = {
    bitcoinix.url = "github:bitcoinix/bitcoinix/master"; # Continuation of nix-bitcoin
    nixpkgs.follows = "bitcoinix/nixpkgs";
    nixpkgs-unstable.follows = "bitcoinix/nixpkgs-unstable";
    extra-container.follows = "bitcoinix/extra-container";
  };

  outputs = { bitcoinix, nixpkgs, nixpkgs-unstable, extra-container, ... }:
    extra-container.lib.eachSupportedSystem (system: {
      packages.default = extra-container.lib.buildContainers {
        inherit system;

        config = let
          localConfig = import ./local-config.nix;
          in {
          # We are currently not using bitcoinix (nix-bitcoin) for testnet4
          # See: https://github.com/bitcoinix/bitcoinix/issues/17
          containers.btctestnet4 = {
            autoStart = true; # Always start container along with the container host

            config = { config, pkgs, ... }: {

              services.bitcoind.testnet4 = {
                enable = true;
                extraConfig = ''
                  chain=testnet4
                  [testnet4]
                '';
                rpc.users = {
                  btcrpc.passwordHMAC = localConfig.rpcHMAC;
                };
              };
            };
          };
        };
      };
    });
}