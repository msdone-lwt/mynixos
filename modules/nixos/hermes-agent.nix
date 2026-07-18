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
  agnesImagePlugin = pkgs.runCommand "agnes-image" { } ''
    mkdir -p $out
    cp ${agnesPluginsSrc}/image_gen/agnes/plugin.yaml $out/
    cp ${agnesPluginsSrc}/image_gen/agnes/__init__.py $out/
  '';

  agnesVideoPlugin = pkgs.runCommand "agnes-video" { } ''
    mkdir -p $out
    cp ${agnesPluginsSrc}/video_gen/agnes/plugin.yaml $out/
    cp ${agnesPluginsSrc}/video_gen/agnes/__init__.py $out/
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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.sops.secrets ? "hermes-env";
        message = ''
          services.msdone-hermes.enable requires sops.secrets."hermes-env".
          Define it in nixos/configuration.nix (see design spec).
          Also put AGNES_API_KEY=... into that secret for Agnes image/video.
        '';
      }
    ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [ config.sops.secrets."hermes-env".path ];

      # Community Agnes image_gen + video_gen backends (symlinked as nix-managed-*).
      extraPlugins = [
        agnesImagePlugin
        agnesVideoPlugin
      ];

      settings = {
        terminal.cwd = "/var/lib/hermes/workspace";
        model = {
          base_url = "https://ai.hybgzs.com/v1";
          default = "z-ai/glm-5.2";
        };

        providers.hyb-grok = {
          name = "黑与白-grok";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_GROK_KEY";
          default_model = "grok-4.5";
          models = {
            "grok-4.5" = { };
            "grok-4.5-claude" = { };
          };
        };
        providers.hyb-default = {
          name = "黑与白-default";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "OPENAI_API_KEY";
          default_model = "z-ai/glm-5.2";
          models = {
            "z-ai/glm-5.2" = { };
            "deepseek-ai/DeepSeek-V4-Pro" = { };
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

        # Enable user/nix-managed Agnes backends.
        # Keys are path-derived (nix-managed-agnes-image / nix-managed-agnes-video);
        # bare name "agnes" also matches plugin.yaml name for both.
        plugins.enabled = [
          "agnes"
          "nix-managed-agnes-image"
          "nix-managed-agnes-video"
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

        # Image understanding via Agnes multimodal chat model
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
  };
}
