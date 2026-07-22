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

  # ─── egress reverse proxy (declared once, used if enableReverseProxy=true) ─
  # Inline Python so Nix keeps it self-contained and reproducible. Dependencies
  # (aiohttp + aiohttp_socks) come from the hermes-agent-env venv, so we reuse
  # that python at runtime rather than packing yet another derivation.
  #
  # cfg.socks5Info.url and cfg.socks5Info.listenPort are interpolated by Nix
  # directly into the generated Python source, so the script is a pure,
  # self-contained artifact in /nix/store (no env-var fallback needed).
  revproxyScript = pkgs.writeText "hermes-revproxy.py" ''
    #!/usr/bin/env python3
    """Origin reverse proxy for geo-blocked Hermes providers via SOCKS5.

    Path layout: http://127.0.0.1:LISTEN_PORT/<key>/<rest>
    is forwarded to <upstreams[key]>/<rest> through the configured SOCKS5 exit.

    Upstreams are read at runtime from HERMES_REVERSE_PROXY_UPSTREAMS as JSON
    { key: upstreamBaseUrl } - set by the systemd unit.
    """
    import asyncio, json, os
    from aiohttp import web, ClientSession, ClientTimeout
    from aiohttp_socks import ProxyConnector

    LISTEN_HOST = "127.0.0.1"
    LISTEN_PORT = ${toString cfg.socks5Info.listenPort}
    SOCKS5 = "${cfg.socks5Info.url}"
    UPSTREAMS = json.loads(os.environ.get("HERMES_REVERSE_PROXY_UPSTREAMS", "{}"))

    HOP_BY_HOP = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
                  "te", "trailers", "transfer-encoding", "upgrade", "host"}
    STRIP_RESPONSE = HOP_BY_HOP | {"content-encoding", "content-length"}

    if not SOCKS5:
        raise SystemExit("socks5Info.url is empty - set services.msdone-hermes.socks5Info.url")
    if not UPSTREAMS:
        raise SystemExit("HERMES_REVERSE_PROXY_UPSTREAMS not set (expected JSON dict)")


    async def handle(request):
        parts = request.path.lstrip("/").split("/", 1)
        if not parts or not parts[0] or parts[0] not in UPSTREAMS:
            return web.Response(status=404, text="unknown provider key")
        key = parts[0]
        rest = "/" + (parts[1] if len(parts) > 1 else "")
        upstream_url = UPSTREAMS[key].rstrip("/") + rest
        if request.query_string:
            upstream_url += "?" + request.query_string

        fwd_headers = {k: v for k, v in request.headers.items() if k.lower() not in HOP_BY_HOP}
        body = await request.read()

        connector = ProxyConnector.from_url(SOCKS5)
        timeout = ClientTimeout(total=180, connect=30, sock_connect=30, sock_read=180)
        async with ClientSession(connector=connector, timeout=timeout, auto_decompress=True) as sess:
            async with sess.request(
                request.method, upstream_url,
                headers=fwd_headers, data=body if body else None,
                allow_redirects=False, ssl=False,
            ) as up_resp:
                out = web.StreamResponse(status=up_resp.status, reason=up_resp.reason)
                for k, v in up_resp.headers.items():
                    if k.lower() in STRIP_RESPONSE:
                        continue
                    out.headers[k] = v
                await out.prepare(request)
                async for chunk in up_resp.content.iter_chunked(8192):
                    await out.write(chunk)
                await out.write_eof()
                return out


    async def main():
        app = web.Application(client_max_size=32 * 1024 * 1024)
        app.router.add_route("*", "/{tail:.*}", handle)
        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, LISTEN_HOST, LISTEN_PORT)
        await site.start()
        print(f"[revproxy] listening {LISTEN_HOST}:{LISTEN_PORT} via {SOCKS5}; upstreams={list(UPSTREAMS)}", flush=True)
        while True:
            await asyncio.sleep(3600)


    asyncio.run(main())
  '';
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
    # Provider egress proxy: route geo-blocked providers (e.g. chybenzun.top)
    # through a SOCKS5 upstream while keeping all other providers direct.
    #
    # Architecture (verified end-to-end on this host, 2026-07-20):
    #   hermes httpx ──HTTP──► revproxy:127.0.0.1:8443 ──socks5──► remote exit
    #                                                       └──HTTPS──► upstream
    #   hybgzs & all other providers stay on their own base_url, no proxy.
    #
    # The revproxy is a tiny aiohttp + aiohttp_socks origin reverse proxy that
    # strips Content-Encoding/Content-Length so downstream httpx sees plain JSON.
    # Only providers whose Hermes base_url is rewritten to
    # http://127.0.0.1:${listenPort}/... actually traverse this proxy.
    # ─────────────────────────────────────────────────────────────────────────
    enableReverseProxy = lib.mkEnableOption "Reverse proxy that routes only geo-blocked Hermes providers through an external SOCKS5 upstream (enable when a custom provider returns `geo_blocked` from your region).";

    socks5Info = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "socks5h://host:port" + " or socks5h://user:pass@host:port";
        description = ''
          The SOCKS5 upstream URL used by the reverse proxy, e.g.
          socks5h://host:port or socks5h://user:pass@host:port.
          Written verbatim into the generated /nix/store script, so this is
          NOT a place for secrets you don't want world-readable. If it must
          stay secret, keep enableReverseProxy off and configure outside this
          module.
        '';
      };

      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 8443;
        description = "Local loopback port the reverse proxy listens on.";
      };

      # Map of provider-key → upstream base URL. Only providers listed here are
      # routed through the reverse proxy (i.e. only this provider's SOCKS5
      # egress is enabled). All other providers stay direct.
      upstreams = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { chy = "https://chybenzun.top"; };
        description = ''
          Provider-key → upstream base URL. A request to
          http://127.0.0.1: listenPort / <key> / XYZ is forwarded to
          <base URL>/XYZ via the SOCKS5 upstream. Update Hermes config to set
          that provider's base_url to http://127.0.0.1: listenPort / <key>.
        '';
      };
    };
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
        {
          assertion = !(cfg.enableReverseProxy && cfg.socks5Info.url == "");
          message = ''
            services.msdone-hermes.enableReverseProxy = true requires
            socks5Info.url to be set (e.g. socks5h://host:port).
          '';
        }
        {
          assertion = !(cfg.enableReverseProxy && cfg.socks5Info.upstreams == { });
          message = ''
            services.msdone-hermes.enableReverseProxy = true requires
            socks5Info.upstreams to list at least one provider to route
            (e.g. { chy = "https://chybenzun.top"; }).
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
          base_url = "https://ai.hybgzs.com/v1";
          default = "grok-4.5-claude";
          provider = "custom:hyb-grok";
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
          # base_url = "http://127.0.0.1:8443/chy/v1";
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

    (lib.mkIf cfg.enableReverseProxy {
      # Reverse proxy that forwards only enableReverseProxy-routed providers
      # through the configured SOCKS5. chdaemons as the hermes user so its
      # /nix/store-bound script and venv python are accessible.
      systemd.services.hermes-revproxy = {
        description = "Reverse proxy for geo-blocked Hermes providers via SOCKS5";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          # Upstream map as JSON so the python script can route by provider key.
          HERMES_REVERSE_PROXY_UPSTREAMS = builtins.toJSON cfg.socks5Info.upstreams;
        };

        serviceConfig = {
          Type = "simple";
          # The hermes-agent package exposes its sealed uv2nix venv via passthru.
          # That venv already contains aiohttp + aiohttp_socks, so we reuse it
          # instead of building another Python environment just for the proxy.
          ExecStart = "${config.services.hermes-agent.package.hermesVenv}/bin/python3 ${revproxyScript}";
          User = "hermes";
          Group = "hermes";
          Restart = "on-failure";
          RestartSec = "5s";
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    })

    (lib.mkIf (cfg.enableReverseProxy && cfg.socks5Info.upstreams ? chy) {
      # Rewrite the chy provider's base_url to point at the local reverse proxy.
      # Everything else in services.hermes-agent.settings stays untouched; the
      # merge list above provides the original definition, and this mkIf
      # override is applied last (lib.mkMerge honours right-most priority for
      # non-{lib.mkDefault,...} values).
      services.hermes-agent.settings.providers.chy.base_url =
        "http://127.0.0.1:${toString cfg.socks5Info.listenPort}/chy/v1";
    })
  ]);
}
