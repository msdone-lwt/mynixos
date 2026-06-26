{
  pkgs,
  ...
}:

{
  # 配置自动申请 HTTPS 证书所需的邮箱和同意条款 (全局生效)
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "lwt6077@gmail.com";

  services.nginx = {
    enable = true;
    # 推荐的安全代理和网络层设置
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;

    virtualHosts."disk.msdone1.com" = {

      forceSSL = true; # 强制 HTTP 跳转到 HTTPS
      enableACME = true; # 自动向 Let's Encrypt 申请/续期证书

      locations."/" = {
        proxyPass = "http://127.0.0.1:5244";
        proxyWebsockets = true;
        # NOTE:取消 Nginx 上传大小限制，否则在网盘中上传大文件会报 413 错误
        extraConfig = ''
          client_max_body_size 0;
        '';
      };
    };
  };
  
  # 防火墙放行 Web 端口
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
