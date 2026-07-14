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
      };
    };

    # Share HERMES_HOME state with the interactive login user.
    users.users.msdone.extraGroups = [ "hermes" ];
  };
}
