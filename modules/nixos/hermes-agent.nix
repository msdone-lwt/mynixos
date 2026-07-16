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
          name = "黑与白-grok-4.5";
          base_url = "https://ai.hybgzs.com/v1";
          key_env = "HYB_GROK";
          default_model = "grok-4.5";
          models = {
            "grok-4.5" = {};
            "deepseek-ai/DeepSeek-V4-Pro" = {};
          };
        };
      };
    };

    # Share HERMES_HOME state with the interactive login user.
    users.users.msdone.extraGroups = [ "hermes" ];
  };
}
