{
  pkgs,
  ...
}:

{
  # 1. 将 openlist 加入系统环境，方便日后在命令行直接执行管理命令
  environment.systemPackages = with pkgs; [ openlist ];

  # 2. 配置 Systemd 守护进程运行 OpenList
  systemd.services.openlist = {
    description = "OpenList Server (AList fork)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # 启动命令，显式指定数据目录
      ExecStart = "${pkgs.openlist}/bin/openlist server --data /var/lib/openlist";

      # 设置工作目录
      WorkingDirectory = "/var/lib/openlist";

      # 使用 systemd 内置的 StateDirectory 自动创建并管理 /var/lib/openlist 及权限
      StateDirectory = "openlist";

      # 降权运行（不使用 root，提升安全性）
      User = "openlist";
      Group = "openlist";

      # 崩溃后自动重启策略
      Restart = "on-failure";
      RestartSec = "5s";

      # 安全沙盒强化 (推荐)
      ProtectHome = true;
      ProtectSystem = "full";
      PrivateTmp = true;
    };
  };

  # 3. 创建独立的用户和组以隔离权限
  users.users.openlist = {
    isSystemUser = true;
    group = "openlist";
    home = "/var/lib/openlist";
  };
  users.groups.openlist = { };
}
