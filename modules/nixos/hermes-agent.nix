{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.msdone-hermes;

  # Community Agnes plugins: https://github.com/Start-Ten/agnes-ai-hermes-plugins
  # Pin commit for reproducibility (main @ 2026-06-28).
  agnesPluginsSrc = pkgs.fetchFromGitHub {
    owner = "Start-Ten";
    repo = "agnes-ai-hermes-plugins";
    rev = "011dfc55f79f5c525c3cf3ade3496e37b0402df0";
    hash = "sha256-KHPViIL+32Px/pujV7cUaWORkv6eJeVqNW0zB2rgP3U=";
  };

  # extraPlugins requires plugin.yaml at package root → split monorepo into two packages.
  # IMPORTANT: both upstream plugin.yaml files use name: agnes. Hermes keys flat
  # user plugins by yaml name, so identical names collide and only one loads.
  # Give unique plugin.yaml names here; Python provider.name stays "agnes"
  # (image_gen.provider / video_gen.provider still use "agnes").
  agnesImagePlugin = pkgs.runCommand "agnes-image" { } ''
        mkdir -p $out
        cp ${agnesPluginsSrc}/image_gen/agnes/__init__.py $out/
        cat > $out/plugin.yaml <<'EOF'
    name: agnes-image
    version: 1.0.0
    description: "Agnes AI image generation backend (Agnes Image 2.1 Flash). Free text-to-image & image-to-image via agnes-ai.com."
    author: Start-Ten / community
    kind: backend
    requires_env:
      - AGNES_API_KEY
    EOF
  '';

  agnesVideoPlugin = pkgs.runCommand "agnes-video" { } ''
        mkdir -p $out
        cp ${agnesPluginsSrc}/video_gen/agnes/__init__.py $out/
        cat > $out/plugin.yaml <<'EOF'
    name: agnes-video
    version: 1.0.0
    description: "Agnes AI video generation backend (Agnes Video V2.0). Free text-to-video & image-to-video via agnes-ai.com."
    author: Start-Ten / community
    kind: backend
    requires_env:
      - AGNES_API_KEY
    EOF
  '';

  # Toolsets for CLI + Telegram (include video understand + video gen).
  hermesMediaToolsets = [
    "browser"
    "clarify"
    "code_execution"
    "computer_use"
    "cronjob"
    "delegation"
    "file"
    "image_gen"
    "kanban"
    "memory"
    "session_search"
    "skills"
    "terminal"
    "todo"
    "tts"
    "video"
    "video_gen"
    "vision"
    "web"
  ];
in
{
  options.services.msdone-hermes = {
    enable = lib.mkEnableOption "Hermes Agent CLI + gateway on this server";

    # Shared project tree hermes may read/write (needs traverse ACL on parent home).
    sharedProjectDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/msdone/mynixos";
      description = ''
        Directory the hermes service user may access and modify.
        ACL is applied declaratively on each NixOS activation:
        - execute-only on the parent home so hermes can traverse into this path
        - recursive rwx + default ACL on the project directory itself
      '';
    };

    # ─────────────────────────────────────────────────────────────────────────
    # Gateway: expose raw provider/API error bodies on messaging platforms
    # (Telegram etc.). Uses pkgs.hermes-agent-patched from the mynixos overlay
    # (gateway/run.py patched at the package layer). Disable to restore the
    # upstream hermes-agent behaviour.
    # ─────────────────────────────────────────────────────────────────────────
    exposeProviderErrors = lib.mkEnableOption ''
      Show raw (secret-redacted) provider/API error bodies on Telegram and other
      messaging platforms instead of the generic "check gateway logs" message.
      Uses the overlay-built pkgs.hermes-agent-patched; leave off in multi-user
      setups if you do not want request IDs / channel errors in chat.
    '';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = config.sops.secrets ? "sops-env";
          message = ''
            services.msdone-hermes.enable requires sops.secrets."sops-env".
            Define it in nixos/configuration.nix (see design spec).
            Also put AGNES_API_KEY=... into that secret for Agnes image/video.
          '';
        }
      ];
    }

    {
      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        environmentFiles = [ config.sops.secrets."sops-env".path ];

        # Community Agnes image_gen + video_gen backends (symlinked as nix-managed-*).
        extraPlugins = [
          agnesImagePlugin
          agnesVideoPlugin
        ];

      settings = {
        terminal.cwd = "/var/lib/hermes/workspace";
        model = {
          # base_url = "https://ai.hybgzs.com/v1";
          # default = "grok-4.5-claude";
          # provider = "custom:hyb-grok";
          base_url = "https://chybenzun.top/v1";
          # default = "gpt-5.6-sol";
          default = "gpt-5.5";
          provider = "custom:chy";
          # hyb 上游对 gpt-5.6-sol 白名单 codex_cli_rs/* UA；OpenAI/Python 等
          # 全部 403 channel:client_restricted (2026-07-22)。default_headers
          # 全局覆盖 openai SDK 自带 UA，per-provider extra_headers 会因多个
          # hyb-* 共享同一 base_url 而按首个匹配失效（hyb-grok 无 extra_headers）。
          default_headers.User-Agent = "codex_cli_rs/0.1.0";
        };

        providers.hyb-grok = {
          name = "黑与白-grok";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_GROK_KEY";
          default_model = "grok-4.5";
          api_mode = "chat_completions";
          models = {
            "grok-4.5" = { };
            "grok-4.5-claude" = { };
          };
        };

        providers.hyb-default = {
          name = "黑与白-default";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_DEFAULT_KEY";
          default_model = "z-ai/glm-5.2";
          api_mode = "chat_completions";
          models = {
            "z-ai/glm-5.2" = { };
            "deepseek-ai/deepseek-v4-pro" = { };
          };
        };

        providers.hyb-gpt = {
          name = "黑与白-gpt";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_GPT_KEY";
          default_model = "gpt-5.6-sol";
          api_mode = "chat_completions";
          models = {
            "gpt-5.6-sol" = { };
            "gpt-5.5" = { };
          };
        };
        
        providers.hyb-kimi = {
          name = "黑与白-kimi";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_KIMI_KEY";
          default_model = "k3";
          api_mode = "chat_completions";
          models = {
            "k3" = {
              context_length = 1048576;
            };
            "gpt-5.6-sol" = { };
          };
        };

        providers.hyb-claude = {
          name = "黑与白-claude";
          base_url = "https://ai.hybgzs.com/claude";
          key_env = "HYB_CLAUDE_KEY";
          default_model = "claude-opus-4-8";
          api_mode = "anthropic_messages";
          models = {
            "claude-opus-4-8" = { };
            "claude-sonnet-4-6" = { };
          };
        };

        providers.chy = {
          name = "chy公益站";
          # Geo egress is handled by services.msdone-mihomo (DOMAIN-SUFFIX rules),
          # not by a local Python reverse proxy. Keep the real HTTPS base_url.
          base_url = "https://chybenzun.top/v1";
          key_env = "CHY_KEY";
          default_model = "gpt-5.6-sol";
          api_mode = "chat_completions";
          models = {
            "gpt-5.6-sol" = { };
            "gpt-5.5" = { };
          };
        };

        providers.anyrouter = {
          name = "anyrouter";
          base_url = "https://a-ocnfniawgw.cn-shanghai.fcapp.run/v1";
          key_env = "ANYROUTER_KEY";
          default_model = "gpt-5.6-sol";
          api_mode = "chat_completions";
          models = {
            "gpt-5.6-sol" = { };
            "gpt-5-codex" = { };
          };
        };

        # Agnes chat/vision endpoint (key via AGNES_API_KEY in hermes-env).
        providers.agnes = {
          name = "agnes";
          base_url = "https://apihub.agnes-ai.com/v1";
          key_env = "AGNES_API_KEY";
          default_model = "agnes-2.0-flash";
          api_mode = "chat_completions";
        };

        # Enable nix-managed Agnes backends (unique plugin.yaml names; see packaging above).
        plugins.enabled = [
          "agnes-image"
          "agnes-video"
        ];

        # Image generation → Agnes Image 2.1 Flash
        image_gen = {
          provider = "agnes";
          model = "agnes-image-2.1-flash";
          agnes = {
            model = "agnes-image-2.1-flash";
          };
        };

        # Video generation → Agnes Video V2.0
        video_gen = {
          provider = "agnes";
          model = "agnes-video-v2.0";
          agnes = {
            model = "agnes-video-v2.0";
          };
        };

        auxiliary.vision = {
          provider = "custom:agnes";
          model = "agnes-2.0-flash";
          timeout = 180;
        };

        platform_toolsets = {
          cli = hermesMediaToolsets;
          telegram = hermesMediaToolsets;
        };
      };
    };

    # Share HERMES_HOME state with the interactive login user.
    users.users.msdone.extraGroups = [ "hermes" ];

    # Declarative ACL so the hermes service user can reach and edit sharedProjectDir.
    # /home/msdone is mode 700; without --x on the home, hermes cannot traverse to mynixos.
    # Do not use `exit` here: activation scripts are concatenated into one bash script.
    system.activationScripts.hermesAccessSharedProject = {
      deps = [
        "users"
        "groups"
      ];
      text = ''
        shared="${cfg.sharedProjectDir}"
        home="$(dirname "$shared")"

        if [ -d "$home" ]; then
          # Traverse only: do not grant list/read of the entire home.
          # Always set mask (m::x): chmod 700 / homeMode rebuilds zero mask and
          # would make user:hermes:--x effective --- without this.
          ${pkgs.acl}/bin/setfacl -m u:hermes:--x,m::x "$home" || echo "hermes ACL: failed to set traverse ACL on $home"
        else
          echo "hermes ACL: home directory $home does not exist yet, skipping"
        fi

        if [ -d "$shared" ]; then
          # Access ACL for existing entries; default ACL for files created later.
          # Ignore errors on special/read-only mount points under the tree.
          ${pkgs.acl}/bin/setfacl -R -m u:hermes:rwx,m::rwx "$shared" || echo "hermes ACL: partial failure setting access ACL on $shared"
          ${pkgs.acl}/bin/setfacl -R -d -m u:hermes:rwx,u:msdone:rwx,m::rwx "$shared" || echo "hermes ACL: partial failure setting default ACL on $shared"
        else
          echo "hermes ACL: shared project $shared does not exist yet, skipping recursive ACL"
        fi
      '';
    };
    }


    (lib.mkIf cfg.exposeProviderErrors {
      # Use the overlay-provided patched hermes-agent so Telegram and other
      # messaging surfaces receive the secret-redacted provider error body.
      # pkgs.hermes-agent-patched is defined in overlays/default.nix.
      # mkForce: beat the hermes-agent module's package default (flake package).
      services.hermes-agent.package = lib.mkForce pkgs.hermes-agent-patched;
    })
  ]);
}
