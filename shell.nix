{ pkgs ? import ./pkgs.nix, accessKeyId ? "staging" }: with pkgs;

let
  overlay = runCommand "nixpkgs-overlays" {} ''
    mkdir -p $out && ln -s ${toString ./.}/pkgs $_
  '';

  nixops = callPackage ./pkgs/nixops {};
in

stdenv.mkDerivation {
  name = "disciplina-nixops";
  nativeBuildInputs = [ git-crypt nixops sqlite ];

  AWS_ACCESS_KEY_ID = accessKeyId;
  AWS_SHARED_CREDENTIALS_FILE = "${toString ./.}/keys/${accessKeyId}/aws-credentials";

  NIX_PATH = lib.concatStringsSep ":" [
    "nixpkgs=${toString pkgs.path}"
    "nixpkgs-overlays=${overlay}"
  ];
}
