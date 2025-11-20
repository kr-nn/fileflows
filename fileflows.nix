#./result/bin/fileflows --base-dir $PWD/base
{ config, lib, pkgs, fileflowPkg, ... }:
let
  cfg = config.services.fileflows;
in
{
  options.services.fileflows = {
    enable = lib.mkEnableOption "FileFlows media processing server";

    package = lib.mkOption {
      type = lib.types.package;
      description = "FileFlows package providing the fileflows binary.";
      example = "inputs.fileflows.packages.${config.nixpkgs.hostPlatform.system}.fileflows";
      default = fileflowPkg.fileflows;
    };

    baseDir = lib.mkOption {
      type = lib.types.path;
      description = "Writable base directory for FileFlows (Data, Logs, Plugins, Templates).";
      example = "/var/lib/fileflows";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "fileflows";
      description = "User under which FileFlows runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "fileflows";
      description = "Group under which FileFlows runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.baseDir;
      createHome = true;
    };

    systemd.tmpfiles.rules = [
      # baseDir and expected subdirs
      "d ${cfg.baseDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.fileflows = {
      description = "FileFlows server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.baseDir;
        ExecStart = "${cfg.package}/bin/fileflows --base-dir ${cfg.baseDir}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
