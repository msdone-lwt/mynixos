# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).


# 这是你的系统配置文件。
# 使用此文件配置你的系统环境（它替代了 /etc/nixos/configuration.nix）
{
  inputs, # 这里的 input 是自己的 flake 的输出
  lib,
  config,
  pkgs,
  ...
}:
# 1. 在这里定义你的全局变量
let
  myFont = "FiraCode Nerd Font";
  myMonoFont = "FiraCode Nerd Font Mono";
  myFontSize = "12";
in
{
  # 你可以在这里导入其他的 NixOS 模块
  imports = [
    # 如果你想使用你自己的 flake 导出的模块（来自 modules/nixos）：
    # inputs.self.nixosModules.example

    # 或者来自其他 flake 的模块（例如 nixos-hardware）：
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # 你也可以将配置拆分并在这里导入片段：
    # ./users.nix

    # 导入自动生成的硬件配置
    ./hardware-configuration.nix
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

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # 启用实验性功能: flakes 功能和新的 'nix' 命令
      experimental-features = "nix-command flakes";
      # 偏好设置：禁用全局注册表
      flake-registry = "";
      # 针对 https://github.com/NixOS/nix/issues/9574 的权宜之计
      nix-path = config.nix.nixPath;
    };
    # 偏好设置：禁用 channel (渠道)
    channel.enable = false;
    # 偏好设置：使 flake 注册表和 nix path 与 flake 输入匹配
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # 1: Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true; # UEFI
  # boot.kernelPackages = pkgs.linuxPackages_latest; # 使用最新的linux 内核

  # 2: Network
  networking.hostName = "nixos-msdone"; # 设置你的主机名
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  
  # 3: Time zone
  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # 4: Internationalisation
  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-with-addons 
      qt6Packages.fcitx5-chinese-addons # pinyin
      fcitx5-gtk
      fcitx5-lua
      fcitx5-pinyin-zhwiki
    ];
  };

  # 5: Font
  fonts = {
    packages = with pkgs; [
      # nredfont
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];     
    fontconfig = {
      enable = true;
      defaultFonts = {
	monospace = [ "${myMonoFont}" ];
        sansSerif = [ "${myFont}" ];
        serif     = [ "${myFont}" ];
        emoji     = [ "${myFont}" ];
      };
    };
  };
  # 6: Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver = {      
    # Enable the X11 window ing system.
    enable = true;          
    # Configure keymap in X11
    xkb = {
      layout = "cn";
      variant = "";
    };
  };
  # 覆盖 GNOME 的默认 GSettings 设置
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.interface]
    font-name='${myFont} ${myFontSize}'
    document-font-name='${myFont} ${myFontSize}'
    monospace-font-name='${myMonoFont} ${myFontSize}'

    [org.gnome.desktop.wm.preferences]
    titlebar-font='${myFont} Bold ${myFontSize}'
  '';
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=${myFont} ${myFontSize}
  '';

  # 7: 系统级软件包与程序
  programs.firefox.enable = false;
  programs.nano.enable = false;
  # 启用 CoolerControl 守护进程和图形界面
  programs.coolercontrol.enable = true;
  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    htop
  ];

  # 8: 打印机 Enable CUPS to print documents.
  services.printing.enable = true;

  # 9: 音频 Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # 10: 用户
  users.users.msdone = {
    isNormalUser = true;
    description = "msdone";
    # 确保添加你需要的任何其他组（如 networkmanager, audio, docker 等）
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      # 如果你打算使用 SSH 连接，请在这里添加你的 SSH 公钥
    ];
  };
  programs.git = {
    enable = true;
    # 这会生成全系统通用的 /etc/gitconfig
    config = {
      user = {
        name = "msdone";
        email = "lwt6077@gmail.com";
      };
      safe = {
        directory = "/etc/nixos";
      };
      core = {
        editor = "nvim";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  # 11: ssh
  # 这里设置 SSH 服务器。如果你正在设置无头系统（服务器），这非常重要。
  # 如果你不需要，可以随意删除。
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     # 偏好设置：禁止通过 SSH 进行 root 登录。
  #     PermitRootLogin = "no";
  #     # 偏好设置：仅使用密钥。
  #     # 如果你想使用密码进行 SSH，请删除此行。
  #     PasswordAuthentication = false;
  #   };
  # };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # 状态版本。关于何时更新请参考：https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11"; # Did you read the comment?
}
