{
  description = "Nix Bitcoin RegTest VM Flake";

  inputs = {
    bitcoinix.url = "github:bitcoinix/bitcoinix/master"; # Continuation of nix-bitcoin
    nixpkgs.follows = "bitcoinix/nixpkgs";
    nixpkgs-unstable.follows = "bitcoinix/nixpkgs-unstable";
    extra-container.follows = "bitcoinix/extra-container";
    p2pool.url = "github:msgilligan/p2poolv2/msgilligan-nix-main";
  };

  outputs = { bitcoinix, nixpkgs, nixpkgs-unstable, extra-container, p2pool, ... }:
    extra-container.lib.eachSupportedSystem (system: {
      packages.default = extra-container.lib.buildContainers {
        inherit system;

        config = let
          localConfig = import ./local-config.nix;
          p2poolPkg = p2pool.packages.${system}.p2poolv2_node;
          in {
          # We are currently not using bitcoinix (nix-bitcoin) for testnet4
          # See: https://github.com/bitcoinix/bitcoinix/issues/17
          containers.p2pool-testnet4 = {
            autoStart = true; # Always start container along with the container host

            config = { config, pkgs, ... }: {
              users.users.p2pool = { isSystemUser = true; group = "p2pool"; };
              users.groups.p2pool = { };

              # Starting point: the sample config from the PR source.
              # Replace with your own file (bitcoind RPC/ZMQ, addresses, network).
              environment.etc."p2pool/config.toml".source = "${p2pool}/config.sample-testnet4.toml";
              environment.systemPackages = [ p2poolPkg ];

              services.bitcoind.testnet4 = {
                enable = true;
                extraConfig = ''
                  chain=testnet4
                  [testnet4]
                '';
                rpc.users = {
                  p2pool.passwordHMAC = localConfig.rpcHMAC;
                };
              };
              systemd.services.p2pool = {
                description = "P2Pool - Bitcoin Mining Pool";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                environment.P2POOL_STATIC_DIR = "${p2pool}/p2poolv2_api/static";
                serviceConfig = {
                  ExecStart = "${p2poolPkg}/bin/p2poolv2 --config /etc/p2pool/config.toml";
                  User = "p2pool";
                  Group = "p2pool";
                  StateDirectory = "p2pool";
                  WorkingDirectory = "/var/lib/p2pool"; # store.db, logs/ go here
                  Restart = "on-failure";
                  RestartSec = 5;
                  LimitNOFILE = 65536;
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectSystem = "strict";
                  ProtectHome = true;
                };
              };
            };
          };
        };
      };
    });
}

