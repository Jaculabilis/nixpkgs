{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.immich-public-proxy;
  inherit (lib)
    types
    mkIf
    mkOption
    mkEnableOption
    ;
in
{
  options.services.immich-public-proxy = {
    enable = mkEnableOption "Immich Public Proxy";
    package = lib.mkPackageOption pkgs "immich-public-proxy" { };

    immich-url = mkOption {
      type = types.str;
      description = "URL of the Immich instance";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "The port that IPP will listen on.";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the IPP port in the firewall";
    };
    user = mkOption {
      type = types.str;
      default = "ipp";
      description = "The user IPP should run as.";
    };
    group = mkOption {
      type = types.str;
      default = "ipp";
      description = "The group IPP should run as.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.immich-public-proxy = {
      description = "Immich public proxy for sharing albums publicly without exposing your Immich instance";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      #path = [ pkgs.immich-public-proxy ];
      environment = {
        IMMICH_URL = cfg.immich-url;
        IPP_PORT = builtins.toString cfg.port;
      };
      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        StateDirectory = "ipp"; # TODO wat do
        SyslogIdentifier = "ipp";
        RuntimeDirectory = "ipp"; # TODO wat do
        CacheDirectory = "ipp"; # TODO wat do
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 3;

        # Hardening
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateUsers = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateMounts = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    users.users = mkIf (cfg.user == "ipp") {
      ipp = {
        name = "ipp";
        group = cfg.group;
        isSystemUser = true;
      };
    };
    users.groups = mkIf (cfg.group == "ipp") { ipp = { }; };

    meta.maintainers = with lib.maintainers; [ jaculabilis ];
  };
}
