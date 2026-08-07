{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.msdone-grok2api;
in
{
  options.services.msdone-grok2api = {
    enable = lib.mkEnableOption "grok2api gateway (Docker OCI container + nginx reverse proxy)";

    domain = lib.mkOption {
      type = lib.types.str;
      example = "grok.example.com";
      description = "Domain name for the nginx virtual host.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "lwt6077@gmail.com";
      description = "Email for ACME certificate registration.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Local port the grok2api container listens on (bound to 127.0.0.1).";
    };

    # secret 文件由 sops 提供，内含两行：jwtSecret / credentialEncryptionKey / adminPassword
    # 这里只接收路径，不把内容写进 nix store
    configSecretFile = lib.mkOption {
      type = lib.types.path;
      default = config.sops.secrets."grok2api-config".path;
      defaultText = "config.sops.secrets.\"grok2api-config\".path";
      description = "Path to the grok2api config.yaml (managed by sops-nix).";
    };
  };

  config = lib.mkIf cfg.enable {
    # ---- Docker 容器 ----
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.grok2api = {
      image = "ghcr.io/chenyme/grok2api:latest";
      autoStart = true;
      # host 网络：容器与宿主机共享 loopback，可直接用 mihomo 的
      # http://127.0.0.1:7890 做 Web→Build / OAuth egress。
      # 不再做 -p 映射；进程在宿主机上听 listenPort（镜像默认 0.0.0.0:8000）。
      # 防火墙只放行 80/443，8000 不对公网开放。
      volumes = [
        "${cfg.configSecretFile}:/run/grok2api/config.yaml:ro"
        "grok2api-data:/app/data"
      ];
      environment.TZ = "Asia/Shanghai";
      extraOptions = [
        "--init"
        "--network=host"
      ];
      # sops.secrets."grok2api-config" 在 configuration.nix 里声明
      # 容器通过 volumes 直接挂 /run/secrets/grok2api-config
    };

    # ---- nginx 反代 ----
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
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.listenPort}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 100m;
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
          '';
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
