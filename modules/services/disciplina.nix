{ config, lib, pkgs, ... }: with lib;

let
  cfg = config.services.disciplina;

  attrsToFlags = set:
    let
      render = name: value:
        "--" + name + (optionalString (isString value) (" " + value));

      renderList = name: value:
        if isList value
        then map (render name) value
        else [ (render name value) ];
    in
    concatStringsSep " " (concatLists (mapAttrsToList renderList set));
in

{
  options.services.disciplina = {
    enable = mkEnableOption "Disciplina witness";

    type = mkOption {
      type = types.enum [ "witness" "faucet" "educator" ];
      default = "witness";
      description = ''
        The type of node to spawn. Sets the systemd unit name to
        `disciplina-<type>`, state dir to `/var/lib/disciplina-<type>`, and
        runs `dscp-<type>`.
      '';
    };

    args = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Set of arguments passed to witness CLI
      '';
    };

    keyFiles = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        list of files from /run/keys to copy to /tmp
      '';
    };
  };

  config = mkIf cfg.enable {

    systemd.services.disciplina-witness = let
      cfgfile = "${stateDir}/config.yaml";
      stateDir = "/var/lib/disciplina-${cfg.type}";
    in
      {
      after = [ "network.target" ] ++ (map (x: "${x}-key.service") cfg.keyFiles);
      requires = [ "network.target" ] ++ (map (x: "${x}-key.service") cfg.keyFiles);
      wantedBy = [ "multi-user.target" ];

      preStart = concatMapStringsSep "\n" (x: "cp /run/keys/${x} /tmp/${x}; chmod 444 /tmp/${x}") cfg.keyFiles;

      environment.HOME = stateDir;

      script = ''
        ${pkgs.disciplina}/bin/dscp-${cfg.type} ${attrsToFlags cfg.args}
      '';

      serviceConfig = {
        PermissionsStartOnly = "true";
        DynamicUser = "true";
        StateDirectory = "disciplina-${cfg.type}";
        WorkingDirectory = stateDir;
      };
    };
  };
}