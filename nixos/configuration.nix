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
    inputs.self.nixosModules.openlist
    inputs.self.nixosModules.hermes-agent
    inputs.self.nixosModules.mihomo
    inputs.self.nixosModules.grok2api

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
        trusted-users = [
          "root"
          "msdone"
        ];
      };
      # 偏好设置：禁用 channel (渠道)
      channel.enable = false;
      # 偏好设置：使 flake 注册表和 nix path 与 flake 输入匹配
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # NOTE: 1: Bootloader.

  boot.loader.grub.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true; # UEFI
  # 每次开机时清理 /tmp 目录，避免临时文件长期堆积。
  boot.tmp.cleanOnBoot = true;
  # 启用 zram 交换空间：用一块压缩内存当作 swap。
  # 内存紧张时通常比直接使用磁盘 swap 更快，但会占用一些 CPU 做压缩。
  # 2G 机默认 50%≈1G 太小；提到 4G 给 nix-daemon/hermes 峰值留缓冲。
  # memoryMax 为未压缩容量上限；真实占用 ≈ 压缩后体积（zstd）。
  zramSwap = {
    enable = true;
    memoryPercent = 250; # 相对 RAM 上限（与 memoryMax 取较小值）
    memoryMax = 4 * 1024 * 1024 * 1024; # 4 GiB
    algorithm = "zstd";
    priority = 5;
  };
  boot.loader.grub.configurationLimit = 5;
  # boot.supportedFilesystems = [ "ntfs" ];
  # boot.kernelPackages = pkgs.linuxPackages_latest; # 使用最新的linux 内核
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  # NOTE: 2: Network

  networking.hostName = "nixos-msdone"; # 设置你的主机名
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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

  # NOTE: 5: Font

  # NOTE: 6: Desktop Environment.
  # 禁用 X11（niri 是纯 Wayland）
  services.xserver.enable = false;

  # NOTE: 7: 系统级软件包与程序

  programs.firefox.enable = false;
  programs.nano.enable = false;
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
  ];

  # NOTE: 8: 打印机 Enable CUPS to print documents.

  services.printing.enable = false;

  # NOTE: 9: 音频 Enable sound with pipewire.

  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   #jack.enable = true;
  #
  #   # use the example session manager (no others are packaged yet so this is enabled by default,
  #   # no need to redefine it in your config for now)
  #   #media-session.enable = true;
  # };

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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDF9GTWS2KVulkigK48DAqngPXlpN3bzVv3Of2eoNQaC+pvdKKqFXwpNf5KL643O51HUjAZNG2PxC6crlxQZb6bZ+K2y1FotslrznNHqJ7VgWJH/GcDVJ0WV6gxu3awqWpLA8fMYYgayV2lPxFkxtOux6ob1l+95D3qZLUKRKw7BLtuHnaKFJBFfHWPCYZvvzL+a/MWEWyOEf0TIeSQBG+AriYLIWkImivt6aCbOqvF7aCOkXaIkUrgzgEm2U3bRMAVe0I6PspVqtyW2PsQpHstLOVGu0irzNICJY/kZefGlA6fga+1b5v5/EhwzmieHGXOK8KJi3VvhCvz/GwMJaV/ skey-632gd18z"
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
  services.openssh = {
    enable = true;
    settings = {
      # 偏好设置：禁止通过 SSH 进行 root 登录。
      PermitRootLogin = "no";
      # 偏好设置：仅使用密钥。
      # 如果你想使用密码进行 SSH，请删除此行。
      PasswordAuthentication = false;
    };
  };
  security.sudo.extraRules = [
    {
      users = [ "msdone" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # NOTE: 12: services
  # 通过命令初始化密码：sudo -u openlist OpenList admin set [password] --data /var/lib/openlist
  services.openlist = {
    enable = true;
    enableNginx = true;
    enableUnlimitedUploadSize = true;
    domain = "disk.msdone1.com";
    acmeEmail = "lwt6077@gmail.com";
    extraGroupUsers = [ "msdone" ];
  };

  # Hermes Agent gateway + CLI (shared HERMES_HOME under /var/lib/hermes)
  services.msdone-hermes = {
    enable = true;
    sharedProjectDir = "/home/msdone/mynixos"; # 给 hermes 读写权限的目录

    # Telegram 等消息平台直接显示上游 provider 错误原文（仍做 secret redaction）。
    # 关掉则恢复 Hermes 默认的 “check gateway logs” 泛化提示。
    exposeProviderErrors = true;
  };

  # Mihomo: only DOMAIN-SUFFIX,chybenzun.top → PROXY (HK nodes from subscription);
  # all other traffic DIRECT. Hermes gets HTTPS_PROXY=http://127.0.0.1:7890.
  # Subscription URL lives in sops secret "mihomo-subscription-url" (one line, URL only).
  services.msdone-mihomo = {
    enable = true;
    proxyDomains = [
      "chybenzun.top"
      "cdk.hybgzs.com"
      "x.ai"
      "grok.com"
      "ipinfo.io"
    ];
    mixedPort = 7890;
    configureHermes = true;
    subscriptionUrlFile = config.sops.secrets."mihomo-subscription-url".path;
  };

  # grok2api: Docker 容器 + nginx 反代到 grok.msdone1.com
  # config.yaml 由 sops 管理（secrets/sops-env.yaml 里的 grok2api-config 键）
  services.msdone-grok2api = {
    enable = true;
    domain = "grok.msdone1.com";
  };

  # sops-nix: decrypt secrets/sops-env.yaml → /run/secrets/sops-env
  # Shared dotenv for Hermes (environmentFiles) + msdone zsh (source).
  sops = {
    defaultSopsFile = ../secrets/sops-env.yaml;
    # Private key MUST stay off the Nix store. Create with age-keygen (Task 4).
    age.keyFile = "/home/msdone/.config/sops/age/keys.txt";
    secrets."sops-env" = {
      # owner=msdone so interactive zsh can source it; root still reads for systemd/hermes.
      owner = "msdone";
      mode = "0400";
    };
    # One-line Clash/Mihomo subscription URL for services.msdone-mihomo (not in git plaintext).
    secrets."mihomo-subscription-url" = {
      owner = "msdone";
      mode = "0400";
    };
    # grok2api config.yaml (multi-line, contains jwtSecret/credentialEncryptionKey/adminPassword)
    # owner=hermes 让 grok-register 脚本能读取并自动同步到 config.json
    secrets."grok2api-config" = {
      owner = "hermes";
      mode = "0400";
    };
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
  system.stateVersion = "23.11"; # Did you read the comment?
}
