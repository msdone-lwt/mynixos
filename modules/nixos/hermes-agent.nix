{
  config,
  lib,
  ...
}:
let
  cfg = config.services.msdone-hermes;
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
        '';
      }
    ];

    services.hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [ config.sops.secrets."hermes-env".path ];
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
            "grok-4.5" = {};
            "grok-4.5-claude" = {};
          };
        };
        providers.hyb-default = {
          name = "黑与白-default";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "OPENAI_API_KEY";
          default_model = "z-ai/glm-5.2";
          models = {
            "z-ai/glm-5.2" = {};
            "deepseek-ai/DeepSeek-V4-Pro" = {};
          };
        };
      };
    };

    # Share HERMES_HOME state with the interactive login user.
    users.users.msdone.extraGroups = [ "hermes" ];
  };
}
