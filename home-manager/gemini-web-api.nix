{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
  projectDir = "${homeDir}/.gemini-web-api";
  runtimeDir = "${projectDir}/runtime";
  python = "${pkgs.python312}/bin/python";
  secure1psid = "$(${pkgs.coreutils}/bin/printenv SECURE_1PSID 2>/dev/null || true)";
  secure1psidts = "$(${pkgs.coreutils}/bin/printenv SECURE_1PSIDTS 2>/dev/null || true)";
  apiKey = "$(${pkgs.coreutils}/bin/printenv API_KEY 2>/dev/null || true)";
  port = 8765;
  systemctl = "${pkgs.systemd}/bin/systemctl";

  gemi2apiSrc = pkgs.fetchFromGitHub {
    owner = "zhiyu1998";
    repo = "Gemi2Api-Server";
    rev = "554cf4f8c4ae3a9d5e52f556168637155fc81c7b";
    sha256 = "0xxwlpf0a64y056pq6cbh9lk2xa1q8ll7j3lf8vh5f8rsvb0kagy";
  };

  startScript = pkgs.writeShellScript "start-gemi2api-server" ''
    set -eu

    secure_1psid="${secure1psid}"
    secure_1psidts="${secure1psidts}"
    api_key="${apiKey}"

    if [ -n "$secure_1psid" ] && [ -z "''${SECURE_1PSID:-}" ]; then
      export SECURE_1PSID="$secure_1psid"
    fi

    if [ -n "$secure_1psidts" ] && [ -z "''${SECURE_1PSIDTS:-}" ]; then
      export SECURE_1PSIDTS="$secure_1psidts"
    fi

    if [ -n "$api_key" ] && [ -z "''${API_KEY:-}" ]; then
      export API_KEY="$api_key"
    fi

    exec ${pkgs.uv}/bin/uv run --python ${python} uvicorn main:app --host 127.0.0.1 --port ${toString port}
  '';
in {
  home.activation.geminiWebApi = lib.hm.dag.entryAfter ["writeBoundary"] ''
        config_file="${projectDir}/.env"
        rm -rf ${projectDir}
        mkdir -p ${projectDir}
        cp -R ${gemi2apiSrc}/. ${projectDir}/
        chmod -R u+w ${projectDir}

        mkdir -p ${runtimeDir}/cookies ${runtimeDir}/logs
        if [ ! -f "$config_file" ]; then
          cat >"$config_file" <<'EOF'
    ENABLE_THINKING=false
    TEMPORARY_CHAT=false
    AUTO_DELETE_CHAT=true
    PUBLIC_BASE_URL=
    SECURE_1PSID=
    SECURE_1PSIDTS=
    API_KEY=
    EOF
          chmod 0600 "$config_file"
        fi
  '';

  home.activation.startGeminiWebApi = lib.hm.dag.entryAfter ["geminiWebApi" "reloadSystemd"] ''
    run ${systemctl} --user enable --now gemini-web-api.service
  '';

  systemd.user.services.gemini-web-api = {
    Unit = {
      Description = "Local OpenAI-compatible Gemini Web API";
      After = ["network-online.target"];
    };

    Service = {
      Type = "simple";
      WorkingDirectory = projectDir;
      Environment = [
        "GEMINI_COOKIE_PATH=${runtimeDir}/cookies"
        "PYTHONUNBUFFERED=1"
      ];
      EnvironmentFile = "-${projectDir}/.env";
      ExecStart = "${startScript}";
      Restart = "on-failure";
      RestartSec = 5;
      StandardOutput = "append:${runtimeDir}/logs/service.log";
      StandardError = "append:${runtimeDir}/logs/service.log";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
