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
  mySansFont = "Adwaita Sans";
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

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
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
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # NOTE: 1: Bootloader.

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true; # UEFI
  # 每次开机时清理 /tmp 目录，避免临时文件长期堆积。
  boot.tmp.cleanOnBoot = true;

  # boot.supportedFilesystems = [ "ntfs" ];
  # boot.kernelPackages = pkgs.linuxPackages_latest; # 使用最新的linux 内核

  # NOTE: 2: Network

  networking.hostName = "nixos-msdone"; # 设置你的主机名
  networking.nameservers = [
    "1.1.1.1" # CF
    "223.5.5.5" # 阿里
  ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "mihomo" ];

  # NOTE: 3: Time zone

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";
  time.hardwareClockInLocalTime = true;

  # NOTE: 4: Internationalisation

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
      fcitx5-material-color # 包含暗黑主题 Material-Color-Black
    ];
  };

  # NOTE: 5: Font

  fonts = {
    packages = with pkgs; [
      # nredfont
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "${myMonoFont}"
          "Noto Sans CJK SC"
        ];
        sansSerif = [
          "${mySansFont}"
          "Noto Sans CJK SC"
        ];
        serif = [
          "${myFont}"
          "Noto Serif CJK SC"
        ];
        emoji = [
          "Noto Color Emoji"
          "${myFont}"
        ];
      };
    };
  };
  # NOTE: 6: Desktop Environment.

  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;
  # services.xserver = {
  #   # Enable the X11 window ing system.
  #   enable = true;
  #   # Configure keymap in X11
  #   xkb = {
  #     layout = "cn";
  #     variant = "";
  #   };
  # };
  # 覆盖 GNOME 的默认 GSettings 设置
  # services.desktopManager.gnome.extraGSettingsOverrides = ''
  #   [org.gnome.desktop.interface]
  #   font-name='${myFont} ${myFontSize}'
  #   document-font-name='${myFont} ${myFontSize}'
  #   monospace-font-name='${myMonoFont} ${myFontSize}'
  #
  #   [org.gnome.desktop.wm.preferences]
  #   titlebar-font='${myFont} Bold ${myFontSize}'
  # '';
  environment.etc."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-font-name=${myFont} ${myFontSize}
  '';
  # NOTE: dms + niri

  # 禁用 X11（niri 是纯 Wayland）
  services.xserver.enable = false;
  # XWayland 支持（如果需要运行 X11 应用）
  programs.xwayland.enable = true;
  # 禁用完整的 GNOME 桌面
  services.desktopManager.gnome.enable = false;
  services.displayManager.gdm.enable = false;
  # 保留密钥环服务
  services.gnome.gnome-keyring.enable = true;
  # 启用自动挂载服务（让文件管理器可以挂载 Windows 分区等）
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  # support webdav
  services.davfs2.enable = false;
  fileSystems."/home/msdone/webdav" = {
    device = "https://msdone1.com/dav/baidu";
    fsType = "davfs";
    options = [
      "user"
      "rw"
      "noauto"
      "x-systemd.automount"
      "uid=msdone"
      "gid=users"
    ];
  };
  # 桌面环境 - niri + dms
  programs.dms-shell.enable = true; # 启用 DankMaterialShell
  programs.niri.enable = true; # 启用 Niri
  programs.dms-shell.systemd.restartIfChanged = true; # 当 dms-shell 配置文件更改时，自动重启 dms-shell 服务
  programs.dms-shell.quickshell.package = pkgs.quickshell; # quickshell 的安装包来源, options: pkgs.unstable.quickshell
  programs.dms-shell.package = pkgs.dms-shell; # dms 的安装包来源, options: pkgs.unstable.dms-shell
  programs.niri.package = pkgs.niri; # niri 的安装包来源, options: pkgs.unstable.niri
  # services.greetd.useTextGreeter = true; # 启用文本登录界面 - tuiGreet
  services.displayManager.dms-greeter.enable = true; # 启用 DankMaterialShell 的登录界面
  services.displayManager.dms-greeter.compositor.name = "niri"; # 用于运行 greeter 的 Wayland compositor
  # services.displayManager.dms-greeter.configFiles   FIXME:
  # services.displayManager.dms-greeter.configHome    FIXME:

  # NOTE: 7: 系统级软件包与程序

  programs.firefox.enable = false;
  programs.nano.enable = false;
  programs.steam.enable = true;
  # 启用 CoolerControl 守护进程和图形界面
  programs.coolercontrol.enable = true;
  programs.nix-ld.enable = true; # NOTE: 用于支持非 NixOS 二进制程序
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    zstd
    glib
    brotli
    unixodbc
    openssl
    curl
    expat
    libxml2
  ];
  environment.variables.EDITOR = "nvim";
  # 基于 Chromium 和 Electron 架构的应用程序原生运行在 Wayland 显示服务器上，而不是通过 XWayland（X11 的兼容层）运行。
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    htop
    mihomo
  ];

  # NOTE: 8: 打印机 Enable CUPS to print documents.

  services.printing.enable = true;

  # NOTE: 9: 音频 Enable sound with pipewire.

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
  # NOTE: 10: 用户

  users.users.msdone = {
    isNormalUser = true;
    description = "msdone";
    # 确保添加你需要的任何其他组（如 networkmanager, audio, docker 等）
    extraGroups = [
      "networkmanager"
      "wheel"
      "davfs2" # 允许挂载 WebDAV
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # 如果你打算使用 SSH 连接，请在这里添加你的 SSH 公钥
    ];
  };
  # 系统层 git 配置
  programs.git = {
    enable = true;
    # 这会生成全系统通用的 /etc/gitconfig
    config = {
      user = {
        name = "msdone";
        email = "lwt6077@gmail.com";
      };
      credential = {
        helper = "store";
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
  programs.zsh.enable = true;

  # NOTE: 11: ssh

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

  # 提权包装器
  security.wrappers.mihomo = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_admin,cap_net_bind_service+ep";
    source = "${pkgs.mihomo}/bin/mihomo";
  };
  # boot.kernelModules = [ "tun" ];

  # sops-nix: decrypt secrets/sops-env.yaml → /run/secrets/sops-env
  sops = {
    defaultSopsFile = ../secrets/sops-env.yaml;
    # Private key MUST stay off the Nix store. Create with age-keygen (Task 4).
    age.keyFile = "/home/msdone/.config/sops/age/keys.txt";
    secrets."sops-env" = {
      # owner=msdone so interactive zsh can source it; root still reads for systemd/hermes.
      owner = "msdone";
      mode = "0400";
    };
    # secrets."xxx" = {
    #   owner = "msdone";
    #   mode = "0400";
    # };
  };

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
