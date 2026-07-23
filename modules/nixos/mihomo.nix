{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.msdone-mihomo;

  # Mihomo/Clash Meta config: ignore any subscription-side rules; only our
  # declarative rules apply. Proxy nodes come from a subscription provider
  # (user-supplied URL) or an optional local provider file.
  mihomoConfig = {
    mixed-port = cfg.mixedPort;
    bind-address = "127.0.0.1";
    allow-lan = false;
    mode = "rule";
    log-level = cfg.logLevel;
    ipv6 = true;
    # Do not pull process rules / geo defaults we don't need
    find-process-mode = "off";
    unified-delay = true;
    tcp-concurrent = true;

    # Local REST API for node switch (curl / metacubexd). Bound to loopback only.
    external-controller = "127.0.0.1:${toString cfg.controllerPort}";
    secret = cfg.controllerSecret;

    dns = {
      enable = true;
      # Prefer system/bootstrap DNS; avoid hijacking global DNS when only
      # a single domain needs proxy egress.
      listen = "127.0.0.1:${toString cfg.dnsPort}";
      enhanced-mode = "fake-ip";
      fake-ip-range = "198.18.0.1/16";
      nameserver = [
        "https://1.1.1.1/dns-query"
        "https://8.8.8.8/dns-query"
      ];
      # Resolve proxy-domain via real DNS so DOMAIN-SUFFIX matches correctly
      fake-ip-filter = map (d: "+.${d}") cfg.proxyDomains ++ cfg.proxyDomains;
    };

    # Subscription / node source. Mihomo fetches this at runtime; credentials
    # stay out of the Nix store when you pass a sops-backed url via
    # subscriptionUrlFile (written into the runtime config by ExecStartPre).
    proxy-providers = lib.optionalAttrs (cfg.subscriptionUrl != null || cfg.subscriptionUrlFile != null) {
      hk =
        {
          type = "http";
          # Placeholder replaced at service start when subscriptionUrlFile is set.
          url = if cfg.subscriptionUrl != null then cfg.subscriptionUrl else "__SUBSCRIPTION_URL__";
          path = "./providers/hk.yaml";
          health-check = {
            enable = true;
            url = "https://www.gstatic.com/generate_204";
            interval = 300;
          };
          # Explicitly do NOT import rules from the subscription.
          # (proxy-providers only supply proxies; rules are only from our `rules`.)
        }
        # interval: 0 / null = no automatic subscription refresh (manual mihomo-update only).
        // lib.optionalAttrs (cfg.subscriptionInterval != null && cfg.subscriptionInterval > 0) {
          interval = cfg.subscriptionInterval;
        };
    };

    proxy-groups = [
      {
        name = "PROXY";
        type = "select";
        # All nodes from the hk provider; user picks HK in the UI / first node.
        use = lib.optional (cfg.subscriptionUrl != null || cfg.subscriptionUrlFile != null) "hk";
        # Fallback if provider empty so mihomo still starts
        proxies = [ "DIRECT" ];
      }
    ];

    # ONLY these domains go via PROXY; everything else DIRECT.
    # This intentionally replaces / ignores any clash subscription rules.
    rules =
      (map (d: "DOMAIN-SUFFIX,${d},PROXY") cfg.proxyDomains)
      ++ (map (d: "DOMAIN,${d},PROXY") cfg.proxyDomains)
      ++ [ "MATCH,DIRECT" ];
  };

  mihomoConfigYaml =
    (pkgs.formats.yaml { }).generate "mihomo.yaml" mihomoConfig;

  runtimeConfigDir = "/var/lib/mihomo";
  runtimeConfigPath = "${runtimeConfigDir}/config.yaml";
in
{
  options.services.msdone-mihomo = {
    enable = lib.mkEnableOption ''
      Mihomo (Clash Meta) local proxy for geo-blocked HTTPS domains.
      Only domains in proxyDomains are routed via the selected proxy group;
      all other traffic is DIRECT. Intended for Hermes → chybenzun.top.
    '';

    package = lib.mkPackageOption pkgs "mihomo" { };

    mixedPort = lib.mkOption {
      type = lib.types.port;
      default = 7890;
      description = "Local mixed HTTP/SOCKS port (127.0.0.1 only).";
    };

    controllerPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Local external-controller REST API port for node switch (127.0.0.1 only).";
    };

    controllerSecret = lib.mkOption {
      type = lib.types.str;
      default = "mihomo-local";
      description = ''
        Bearer secret for external-controller. Not high-security (loopback only);
        change if you expose the controller beyond localhost.
      '';
    };

    dnsPort = lib.mkOption {
      type = lib.types.port;
      default = 1053;
      description = "Local DNS listen port for mihomo (fake-ip).";
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "silent"
        "error"
        "warning"
        "info"
        "debug"
      ];
      default = "info";
    };

    proxyDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "chybenzun.top" ];
      example = [
        "chybenzun.top"
      ];
      description = ''
        Domain suffixes that MUST go through PROXY. Everything else is DIRECT.
        Subscription-provided rules are never used.
      '';
    };

    subscriptionUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Clash/Mihomo subscription URL (public or non-secret). Prefer
        subscriptionUrlFile for secrets so the URL is not world-readable in
        /nix/store.
      '';
    };

    subscriptionUrlFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing the subscription URL only (e.g. sops secret).
        At service start the declarative config template is copied and
        __SUBSCRIPTION_URL__ is replaced with the file contents.
      '';
    };

    subscriptionInterval = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      example = 86400;
      description = ''
        Proxy-provider auto-refresh interval in seconds.
        null or 0 (default): do NOT auto-update the subscription; only
        refresh when you run `mihomo-update` (PUT /providers/proxies/hk)
        or restart mihomo (first fetch on start still happens).
        Set e.g. 3600 / 86400 if you want periodic refresh.
      '';
    };

    # Wire Hermes Agent process to this proxy (HTTPS_PROXY etc.).
    configureHermes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true and services.hermes-agent is enabled, set HTTP(S)_PROXY /
        ALL_PROXY on the hermes-agent systemd unit to this mixed-port.
        Mihomo rules still DIRECT non-proxyDomains, so hybgzs etc. stay direct.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.subscriptionUrl != null || cfg.subscriptionUrlFile != null;
            message = ''
              services.msdone-mihomo.enable requires subscriptionUrl or
              subscriptionUrlFile (Clash subscription that provides HK nodes).
            '';
          }
          {
            assertion = !(cfg.subscriptionUrl != null && cfg.subscriptionUrlFile != null);
            message = "Set only one of subscriptionUrl / subscriptionUrlFile.";
          }
          {
            assertion = cfg.proxyDomains != [ ];
            message = "services.msdone-mihomo.proxyDomains must not be empty.";
          }
        ];

        environment.systemPackages = [ cfg.package ];

        # Runtime state for provider cache + generated config
        systemd.tmpfiles.rules = [
          "d ${runtimeConfigDir} 0750 root root -"
          "d ${runtimeConfigDir}/providers 0750 root root -"
        ];

        systemd.services.mihomo = {
          description = "Mihomo proxy (chy domain-only egress)";
          documentation = [ "https://wiki.metacubex.one/" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          preStart =
            if cfg.subscriptionUrlFile != null then
              ''
                set -euo pipefail
                url=$(tr -d '\n\r ' < ${lib.escapeShellArg (toString cfg.subscriptionUrlFile)})
                if [ -z "$url" ]; then
                  echo "mihomo: subscriptionUrlFile is empty" >&2
                  exit 1
                fi
                ${pkgs.gnused}/bin/sed "s|__SUBSCRIPTION_URL__|$url|g" \
                  ${mihomoConfigYaml} > ${runtimeConfigPath}
                chmod 0600 ${runtimeConfigPath}
              ''
            else
              ''
                set -euo pipefail
                cp ${mihomoConfigYaml} ${runtimeConfigPath}
                chmod 0600 ${runtimeConfigPath}
              '';

          serviceConfig = {
            Type = "simple";
            ExecStart = "${lib.getExe cfg.package} -d ${runtimeConfigDir} -f ${runtimeConfigPath}";
            Restart = "on-failure";
            RestartSec = "3s";
            # Not DynamicUser: need stable path + write provider cache
            User = "root";
            # Hardening (no TUN needed for mixed-port only)
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ runtimeConfigDir ];
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
          };
        };
      }

      # Hermes: use mixed-port as HTTP proxy; mihomo rules keep non-chy DIRECT.
      (lib.mkIf (cfg.configureHermes && config.services.hermes-agent.enable or false) {
        systemd.services.hermes-agent = {
          after = [ "mihomo.service" ];
          wants = [ "mihomo.service" ];
          environment = {
            HTTP_PROXY = "http://127.0.0.1:${toString cfg.mixedPort}";
            HTTPS_PROXY = "http://127.0.0.1:${toString cfg.mixedPort}";
            ALL_PROXY = "http://127.0.0.1:${toString cfg.mixedPort}";
            # Optional belt-and-suspenders: never send localhost through proxy
            NO_PROXY = "127.0.0.1,localhost,::1";
            no_proxy = "127.0.0.1,localhost,::1";
          };
        };
      })
    ]
  );
}
