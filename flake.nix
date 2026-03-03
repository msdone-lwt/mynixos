{
  description = "msdone's nix config";
  # todo :
  # 1. 整合 config hardware ✅
  # 2. starter config 目录结构什么意思  ✅
  # 3. 覆盖 clash verge rev 2.3.5 版本 ✅
  # 4. 怎么提交 clash party 到 nixpkgs
  # 5. hm 定义软件配置, git 的作者邮箱等 ✅
  # 6. gnome 配置 fira code 字体 ✅
  # 7. hm配置 pinyin,nvim、lazygit、git、zsh(api key 如何处理)、tmux、alactirry、google(油猴脚本)
  # 8. rebuild alias: cd /etc/nixos && sudo git add . && sudo nix flake update && sudo nixos-rebuild switch --flake .#nixos-msdone   # sudo nix-collect-garbage -d 删除旧生成   # nix-store --optimise   删除重复文件 ✅
  # 9. https://github.com/IvanoiuAlexandruPaul/MSI-Dragon-Center-for-Linux/blob/main/README.md ✅
  # 10. vide coding 把 nextai-translator 贡献到 nixpkgs,  tmuxPlugins 贡献到 nixpkgs

  inputs = {
    # Nixpkgs 软件源:  你可以同时访问来自不同 nixpkgs 版本的软件包和模块。这里是一个运行示例：
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # 另请参阅 'overlays/default.nix' 中的 'unstable-packages' 覆盖层。

    # Home manager 配置管理
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # ghostty flake
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    # 你的 flake 软件包、shell 等支持的系统架构。
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # 这是一个辅助函数，通过为你传递给它的函数提供每个系统架构作为参数来生成属性。
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # 你的自定义软件包
    # 可通过 'nix build', 'nix shell' 等命令访问
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    
    # 你的 nix 文件格式化工具，可通过 'nix fmt' 访问
    # 除了 'alejandra'，其他选项还包括 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # 你的自定义软件包和修改，作为覆盖层 (Overlays) 导出
    overlays = import ./overlays {inherit inputs;};
    
    # 你可能想要导出的可重用 nixos 模块
    # 这些通常是你想要提交到 nixpkgs 官方仓库的内容
    nixosModules = import ./modules/nixos;
    
    # 你可能想要导出的可重用 home-manager 模块
    # 这些通常是你想要提交到 home-manager 官方仓库的内容
    homeManagerModules = import ./modules/home-manager;

    # NixOS 配置入口点
    # 可通过 'nixos-rebuild --flake .#your-hostname' 使用
    nixosConfigurations = {
      # 替换为你自己的主机名 (hostname)
      nixos-msdone = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          # > nixos 配置文件 <
          ./nixos/configuration.nix
	  # 集成 home-manager 配置: 导入 Home Manager NixOS 模块
	  home-manager.nixosModules.home-manager
            {
	      home-manager.useGlobalPkgs = true;   # 使用系统级的 nixpkgs 实例
	      home-manager.useUserPackages = true; # 软件包安装到用户的 profile 中
              home-manager.extraSpecialArgs = { inherit inputs; }; # 传递参数给 home.nix
	      # 关联你的用户名和配置文件
	      home-manager.users.msdone = import ./home-manager/home.nix;
            }
        ];
      };
    };

    # 独立的 home-manager 配置入口点
    # 可通过 'home-manager --flake .#your-username@your-hostname' 使用
    # homeConfigurations = {
    #   # 替换为你的 用户名@主机名
    #   "msdone@nixos-msdone" = home-manager.lib.homeManagerConfiguration {
    #     # Home-manager 需要 'pkgs' 实例 根据你的架构替换 x86_64-linux
    #     pkgs = nixpkgs.legacyPackages.x86_64-linux;
    #     extraSpecialArgs = {inherit inputs;};
    #     modules = [
    #       # > home-manager 配置文件 <
    #       ./home-manager/home.nix
    #     ];
    #   };
    # };
  };
}
