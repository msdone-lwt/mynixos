{ 
  pkgs,
  config,
  ...
}:
let
  tmux-nerd-font-window-name = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-nerd-font-window-name";
    version = "v3.0.0-beta-1";
    src = pkgs.fetchFromGitHub {
      owner = "joshmedeski";
      repo = "tmux-nerd-font-window-name";
      rev = "v3.0.0-beta-1";
      sha256 = "sha256-i3DT+r7WUvutRhob+tHZOe8TBUxpe4JflS9e1dgkg6s=";
    };
  };
  tmux-nvim = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux.nvim";
    version = "unstable-2025-03-19";
    src = pkgs.fetchFromGitHub {
      owner = "aserowy";
      repo = "tmux.nvim";
      rev = "2c1c3be0ef287073cef963f2aefa31a15c8b9cd8";
      sha256 = "sha256-/XIjqQr9loWVTXZDaZx2bSQgco46z7yam50dCnM5p1U=";
    };
  };
in
{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 65535;
    
    plugins = with pkgs.tmuxPlugins; [
      cpu
      resurrect
      continuum
      tmux-nerd-font-window-name
      tmux-nvim
    ];

    # 3. 核心配置加载逻辑
    extraConfig = ''
      # --- 关键：设置环境变量，让你的脚本能找到路径 ---
      set-environment -g TMUX_CONF "${config.xdg.configHome}/tmux/tmux.oh.conf"
      set-environment -g TMUX_CONF_LOCAL "${config.xdg.configHome}/tmux/tmux.conf.local"
      set-environment -g TMUX_CONF_DIR "${config.xdg.configHome}/tmux"
      set-environment -g EDITOR "nvim"

      # --- 加载 Oh My Tmux 主配置 ---
      source "${config.xdg.configHome}/tmux/tmux.oh.conf"
    '';
  };

  # 4. 部署配置文件和脚本
  xdg.configFile = {
    # 部署基础配置
    "tmux/tmux.oh.conf".source = ./tmux/tmux.conf;
    "tmux/tmux.conf.local".source = ./tmux/tmux.conf.local;
    "tmux/tmux-nerd-font-window-name.yml".source = ./tmux/tmux-nerd-font-window-name.yml;

    # 部署脚本并赋予执行权限
    "tmux/custom/default_buffer.sh" = {
      source = ./tmux/custom/default_buffer.sh;
      executable = true;
    };
    "tmux/custom/toggle_synchronize.sh" = {
      source = ./tmux/custom/toggle_synchronize.sh;
      executable = true;
    };
  };
}
