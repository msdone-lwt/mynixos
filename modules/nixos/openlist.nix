{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.openlist;
in
{
  options.services.openlist = {
    enable = lib.mkEnableOption "OpenList server";

    package = lib.mkPackageOption pkgs "openlist" { };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/openlist";
      description = "Directory used by OpenList to store its state.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openlist";
      description = "User account used to run OpenList.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openlist";
      description = "Group account used to run OpenList.";
    };

    extraGroupUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "bruse" ];
      description = "Normal users that should be added to the OpenList group.";
    };

    enableNginx = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to configure nginx as an HTTPS reverse proxy for OpenList.";
    };

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "disk.example.com";
      description = "Domain name used by the nginx virtual host.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "admin@example.com";
      description = "Email address used for ACME certificate registration.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5244;
      description = "Local port OpenList listens on.";
    };

    enableUnlimitedUploadSize = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to disable nginx request body size limits for OpenList uploads.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];

        systemd.services.openlist = {
          description = "OpenList Server (AList fork)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            ExecStart = "${cfg.package}/bin/OpenList server --data ${cfg.dataDir}";
            WorkingDirectory = cfg.dataDir;
            StateDirectory = "openlist";
            User = cfg.user;
            Group = cfg.group;
            Restart = "on-failure";
            RestartSec = "5s";
            ProtectHome = true;
            ProtectSystem = "full";
            PrivateTmp = true;
          };
        };

        users.users = {
          ${cfg.user} = {
            isSystemUser = true;
            group = cfg.group;
            home = cfg.dataDir;
          };
        }
        // lib.genAttrs cfg.extraGroupUsers (_: {
          extraGroups = [ cfg.group ];
        });
        users.groups.${cfg.group} = { };
      }

      (lib.mkIf cfg.enableNginx {
        assertions = [
          {
            assertion = cfg.domain != null;
            message = "services.openlist.domain must be set when services.openlist.enableNginx is true.";
          }
          {
            assertion = cfg.acmeEmail != null;
            message = "services.openlist.acmeEmail must be set when services.openlist.enableNginx is true.";
          }
        ];

        security.acme.acceptTerms = true;
        security.acme.defaults.email = cfg.acmeEmail;

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedGzipSettings = true;

          virtualHosts.${cfg.domain} = {
            forceSSL = true;
            enableACME = true;

          locations."/" =
            {
              proxyPass = "http://127.0.0.1:${toString cfg.port}";
              proxyWebsockets = true;
            }
            // lib.optionalAttrs cfg.enableUnlimitedUploadSize {
              extraConfig = ''
                client_max_body_size 0;
              '';
            };
        };
      };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      })
    ]
  );
}
