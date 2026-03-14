{ 
  pkgs,
  config,
  lib,
  ...
}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      hdc = "hdc.exe";
      python = "python3";
      v = "nvim";
      v5 = "NVIM_APPNAME=astronvim5 nvim";
      ae = "aichat -e";
      ".." = "cd ..";
      "..." = "cd ../..";
      avante = "nvim -c \"lua vim.defer_fn(function()require(\\\"avante.api\\\").zen_mode()end, 100)\"";
      updaterebuild = "git -C /home/msdone/mynixos add . && sudo nix flake update && sudo nixos-rebuild switch --flake /home/msdone/mynixos#nixos-msdone";
      rebuild = "git -C /home/msdone/mynixos add . && sudo nixos-rebuild switch --flake /home/msdone/mynixos#nixos-msdone";
      deletegen = "sudo nix-collect-garbage -d";
      optimise = "nix-store --optimise";
      listfd = "sysctl fs.file-nr";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "tmux"
        "z"
      ];
    };

    initContent = lib.mkMerge [
      ( lib.mkBefore ''
        # Enable Powerlevel10k instant prompt.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
      '')
      (lib.mkAfter ''
        # --- 敏感数据加载 ---
        if [ -f "$HOME/.zshrc.private" ]; then
          source "$HOME/.zshrc.private"
        fi

        # --- 自定义函数 hilog ---
        hilog() {
          local cmd="hdc.exe shell hilog -v color | grep"
          for pattern in "$@"; do
              cmd+=" -e $pattern"
          done
          eval "$cmd"
        }

	# --- zsh-vi-mode 自定义按键映射 ---
	function zvm_after_init() {
          zvm_bindkey vicmd 'H' vi-beginning-of-line
          zvm_bindkey vicmd 'L' vi-end-of-line
          zvm_bindkey visual 'H' vi-beginning-of-line
          zvm_bindkey visual 'L' vi-end-of-line
        }

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '')
    ];

    plugins = [
      {
        name = "zsh-powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
    ];
  };

  home.packages = with pkgs; [
    zsh-powerlevel10k
    zsh-you-should-use
    zsh-history-substring-search
    zsh-vi-mode
  ];

  home.file.".p10k.zsh" = {
    source = ./p10k.zsh;
  };
}
