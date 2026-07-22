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
      v6 = "NVIM_APPNAME=astronvim6 nvim";
      ae = "aichat -e";
      ".." = "cd ..";
      "..." = "cd ../..";
      avante = "nvim -c \"lua vim.defer_fn(function()require(\\\"avante.api\\\").zen_mode()end, 100)\"";
      updaterebuild = "git -C ${config.home.homeDirectory}/mynixos add . && sudo nix flake update && sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/mynixos#nixos-msdone";
      rebuild = "git -C ${config.home.homeDirectory}/mynixos add . && sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/mynixos#nixos-msdone";
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
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        export ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
        # nvidia 显卡的动态链接库
	      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        bindkey -r '^l'
      '')
      (lib.mkAfter ''
         # --- 敏感数据加载（sops-nix 解密的共享 dotenv；勿写进 nix store）---
         # 路径由 sops.secrets."sops-env" 提供，默认 /run/secrets/sops-env
         if [ -r /run/secrets/sops-env ]; then
           set -a
           # shellcheck disable=SC1091
           source /run/secrets/sops-env
           set +a
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

         # --- mihomo：本机 REST API（更新订阅 / 切节点，无需 GUI）---
         # 对应 services.msdone-mihomo：provider=hk，策略组=PROXY，controller=127.0.0.1:9090
         export MIHOMO_API="''${MIHOMO_API:-http://127.0.0.1:9090}"
         export MIHOMO_SECRET="''${MIHOMO_SECRET:-mihomo-local}"

         mihomo-api() {
           curl -s -H "Authorization: Bearer ''${MIHOMO_SECRET}" "$@"
         }

         mihomo-update() {
           mihomo-api -X PUT "''${MIHOMO_API}/providers/proxies/hk"
         }

         mihomo-list() {
           if command -v jq >/dev/null 2>&1; then
             mihomo-api "''${MIHOMO_API}/proxies/PROXY" | jq .all
           else
             mihomo-api "''${MIHOMO_API}/proxies/PROXY"
           fi
         }

         mihomo-now() {
           if command -v jq >/dev/null 2>&1; then
             mihomo-api "''${MIHOMO_API}/proxies/PROXY" | jq -r .now
           else
             mihomo-api "''${MIHOMO_API}/proxies/PROXY"
           fi
         }

         mihomo-use() {
           if [ -z "''${1:-}" ]; then
             echo "usage: mihomo-use <node-name-or-substring>" >&2
             echo "  tip: copy exact name from mihomo-list / mihomo-test-hk (incl. emoji)" >&2
             return 1
           fi
           local want="$1" resolved=""
           # 1) exact match on PROXY group members
           if command -v jq >/dev/null 2>&1; then
             resolved="$(
               mihomo-api "''${MIHOMO_API}/proxies/PROXY" \
                 | jq -r --arg w "$want" '
                     (.all // [])
                     | map(select(. == $w))
                     | .[0] // empty
                   '
             )"
             # 2) unique substring match (e.g. without flag emoji)
             if [ -z "$resolved" ]; then
               resolved="$(
                 mihomo-api "''${MIHOMO_API}/proxies/PROXY" \
                   | jq -r --arg w "$want" '
                       (.all // [])
                       | map(select(contains($w)))
                       | if length == 1 then .[0]
                         elif length == 0 then empty
                         else
                           ("AMBIGUOUS\n" + join("\n")), halt_error(2)
                         end
                     ' 2>/dev/null
               )"
               if [ "''${resolved%%$'\n'*}" = "AMBIGUOUS" ]; then
                 echo "mihomo-use: multiple matches for '$want':" >&2
                 printf '%s\n' "''${resolved#AMBIGUOUS$'\n'}" | sed 's/^/  /' >&2
                 echo "use the exact full name" >&2
                 return 1
               fi
             fi
           else
             resolved="$want"
           fi
           if [ -z "$resolved" ]; then
             echo "mihomo-use: no proxy named/matching '$want'" >&2
             echo "try: mihomo-list   or   mihomo-test-hk" >&2
             return 1
           fi
           echo "selecting: $resolved"
           mihomo-api -X PUT -H "Content-Type: application/json" \
             -d "{\"name\":\"$resolved\"}" "''${MIHOMO_API}/proxies/PROXY"
           mihomo-now
         }

         # 筛选名称含 香港/HK/hongkong 的节点，测延迟后按 ms 升序输出
         # 可选环境变量：MIHOMO_TEST_TIMEOUT_MS（默认 5000）、MIHOMO_TEST_URL
         mihomo-test-hk() {
           if ! command -v jq >/dev/null 2>&1; then
             echo "mihomo-test-hk: need jq" >&2
             return 1
           fi
           local timeout_ms="''${MIHOMO_TEST_TIMEOUT_MS:-5000}"
           local test_url="''${MIHOMO_TEST_URL:-http://www.gstatic.com/generate_204}"
           local proxies_json names name enc delay type udp alive hist
           local -a rows=()
           local n=0 ok=0 fail=0

           proxies_json="$(mihomo-api "''${MIHOMO_API}/proxies")" || {
             echo "mihomo-test-hk: failed to fetch /proxies (is mihomo-chy up?)" >&2
             return 1
           }

           # 名称匹配：香港 / HK(词边界) / hongkong / hong kong（大小写不敏感）
           names="$(
             printf '%s' "$proxies_json" | jq -r '
               .proxies
               | to_entries[]
               | select(
                   (.value.type | test("^(Selector|URLTest|Fallback|LoadBalance|Relay)$") | not)
                   and (
                     (.key | test("香港"; "i"))
                     or (.key | test("hong\\s*kong"; "i"))
                     or (.key | test("(^|[^A-Za-z])HK([^A-Za-z]|$)"; "i"))
                   )
                 )
               | .key
             '
           )"

           if [ -z "$names" ]; then
             echo "mihomo-test-hk: no nodes matched 香港/HK/hongkong" >&2
             return 1
           fi

           echo "Testing HK-like nodes (timeout=''${timeout_ms}ms url=''${test_url})..."
           while IFS= read -r name; do
             [ -z "$name" ] && continue
             n=$((n + 1))
             enc="$(printf '%s' "$name" | jq -sRr @uri)"
             delay="$(
               mihomo-api \
                 "''${MIHOMO_API}/proxies/''${enc}/delay?timeout=''${timeout_ms}&url=$(printf '%s' "$test_url" | jq -sRr @uri)" \
                 | jq -r '.delay // empty' 2>/dev/null
             )"
             type="$(printf '%s' "$proxies_json" | jq -r --arg n "$name" '.proxies[$n].type // "?"')"
             udp="$(printf '%s' "$proxies_json" | jq -r --arg n "$name" 'if .proxies[$n].udp == true then "udp" else "-" end')"
             if [ -n "$delay" ] && [ "$delay" != "null" ]; then
               ok=$((ok + 1))
               # 固定宽度字段便于 sort -n
               rows+=("$(printf '%8s\t%s\t%s\t%s\t%s' "$delay" "$type" "$udp" "ok" "$name")")
               printf '  [%2d] %5sms  %-10s  %s\n' "$n" "$delay" "$type" "$name"
             else
               fail=$((fail + 1))
               rows+=("$(printf '%8s\t%s\t%s\t%s\t%s' "999999" "$type" "$udp" "fail" "$name")")
               printf '  [%2d]  timeout  %-10s  %s\n' "$n" "$type" "$name"
             fi
           done <<< "$names"

           echo
           echo "=== HK nodes by latency (ms) ==="
           printf '%s\n' "''${rows[@]}" | LC_ALL=C sort -n -k1,1 | while IFS=$'\t' read -r d t u st nm; do
             d="''${d// /}"
             if [ "$d" = "999999" ]; then
               printf '%8s  %-12s  %-4s  %-4s  %s\n' "fail" "$t" "$u" "$st" "$nm"
             else
               printf '%6sms  %-12s  %-4s  %-4s  %s\n' "$d" "$t" "$u" "$st" "$nm"
             fi
           done
           echo
           echo "tested=$n ok=$ok fail=$fail  (use: mihomo-use '<name>')"
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
