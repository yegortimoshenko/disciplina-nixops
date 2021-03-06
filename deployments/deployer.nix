{ region ? "eu-west-2" }:

{
  network.description = "Disciplina deployer";

  deployer-instance = { config, lib, pkgs, resources, ... }: {
    deployment.targetEnv = "ec2";

    deployment.ec2 = {
      inherit region;

      ebsInitialRootDiskSize = 256;
      instanceType = "t2.xlarge";
      keyPair = resources.ec2KeyPairs.deployer-key;
      securityGroups = [ resources.ec2SecurityGroups.deployer-ssh.name ];
    };

    deployment.keys = {
      buildkite-token.keyFile = ../keys/production/buildkite-token;

      # Continuous delivery secrets
      "aws-credentials".keyFile = ../keys/staging/aws-credentials;
      "faucet-key.json".keyFile = ../keys/staging/faucet-key.json;
      "witness.yaml".keyFile = ../keys/staging/witness.yaml;
    };

    networking.hostName = "disciplina-deployer";

    nix = {
      binaryCaches = [
        "https://cache.nixos.org"
        "https://disciplina.cachix.org"
      ];

      binaryCachePublicKeys = [
        "disciplina.cachix.org-1:zDeIFV5cu22v04EUuRITz/rYxpBCGKY82x0mIyEYjxE="
      ];
    };

    nixpkgs.overlays = [ (import ../pkgs) ];

    services.buildkite-agent = {
      enable = true;
      package = pkgs.buildkite-agent3;

      runtimePackages = with pkgs; [ bash gnutar nix-with-cachix ];

      # TODO: make into an attrset
      tags = lib.concatStringsSep "," [
        "hostname=${config.networking.hostName}"
        "system=${pkgs.system}"
      ];

      tokenPath = "/run/keys/buildkite-token";
    };
  };

  resources.ec2KeyPairs.deployer-key = { inherit region; };

  resources.ec2SecurityGroups.deployer-ssh = {
    inherit region;
    rules = [{
      fromPort = 22;
      toPort = 22;
      sourceIp = "0.0.0.0/0";
    }];
  };
}
