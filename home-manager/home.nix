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
    # inputs.self.homeManagerModules.example

    # 或者来自其他 flake 导出的模块（例如 nix-colors）：
    # inputs.nix-colors.homeManagerModules.default

    # 你也可以将配置拆分并在这里导入片段：
    # ./nvim.nix
  ];

  nixpkgs = {
    # 你可以在这里添加覆盖层 (Overlays)
    overlays = [
      # 添加你自己的 flake 导出的覆盖层（来自 overlays 和 pkgs 目录）：
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages

      # 你也可以添加其他 flake 导出的覆盖层：
      # neovim-nightly-overlay.overlays.default

      # 或者直接以内联方式定义，例如：
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # 配置你的 nixpkgs 实例
    config = {
      # 如果你不需要闭源软件，请禁用此项
      allowUnfree = true;
    };
  };

  # 设置你的用户名
  home = {
    username = "msdone";
    homeDirectory = "/home/msdone";
  };

  # 根据你的需求添加用户专属软件包：
  home.packages = with pkgs; [
    pkgs.unstable.clash-verge-rev
    google-chrome
    steam
  ];

  # 启用 home-manager
  programs.home-manager.enable = true;

  # 在更改配置时，自动优雅地重新加载系统单元
  systemd.user.startServices = "sd-switch";

  # 状态版本。参考：https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
