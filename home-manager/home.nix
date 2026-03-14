# 这是你的 home-manager 配置文件
# 使用此文件配置你的家目录环境（它替代了 ~/.config/nixpkgs/home.nix）
{
  inputs, # input 为flake 中的输出
  lib,
  config,
  pkgs,
  ...
}: {
  # 你可以在这里导入其他的 home-manager 模块
  imports = [
    # 如果你想使用你自己的 flake 导出的模块（来自 modules/home-manager）：
    # inputs.self.homeManagerMod#ules.example

    # 或者来自其他 flake 导出的模块（例如 nix-colors）：
    # inputs.nix-colors.homeManagerModules.default

    # 你也可以将配置拆分并在这里导入片段：
    # ./nvim.nix
    ./git.nix
    ./fcitx5.nix
    ./zsh.nix
    ./tmux.nix
    ./ghostty.nix
  ];

  home = {
    # 设置你的用户名
    username = "msdone";
    homeDirectory = "/home/msdone";
    # 状态版本。参考：https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.11";
    # 根据你的需求添加用户专属软件包：
    packages = with pkgs; [
      # clash-verge-rev
      sparkle
      wechat
      cryptomator
      tmux
      google-chrome
      steam
      lazygit
      fastfetch
      # ghostty flake, pkgs.stdenv.hostPlatform.system 会自动匹配你的系统架构（如 x86_64-linux）
      inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
      # 硬件监控工具包
      lm_sensors # 通过 sudo sensors-detect 使用, 可以查找出 nct6683 等内核驱动
      # nextai-translator
      nodejs_24
      ripgrep
      gdu
      bottom
      python315
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
    ];
  };

  # 启用 home-manager
  programs.home-manager.enable = true;

  # 在更改配置时，自动优雅地重新加载系统单元
  systemd.user.startServices = "sd-switch";
}
