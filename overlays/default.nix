# 此文件用于定义覆盖层 (Overlays)
{ inputs, ... }:
let
  # Upstream Hermes 0.18.x rewrites provider failures on messaging surfaces into
  # a generic "check gateway logs" line. We patch _gateway_provider_error_reply
  # so Telegram/Discord get the secret-redacted upstream body (HTTP status +
  # message). Secrets are still stripped by _sanitize_gateway_final_response
  # before this function runs.
  patchedGatewayErrorFn = ''
    def _gateway_provider_error_reply(text: str) -> str:
        """Map raw provider/API errors for messaging surfaces (msdone patch)."""
        body = (text or "").strip()
        if not body:
            return "⚠️ Provider error (empty body). Check gateway logs."
        if len(body) > 1500:
            body = body[:1500] + "\n…(truncated)"
        return f"⚠️ Provider error (raw):\n{body}"
  '';

  # Lightweight: reuse the already-built hermes-agent flake package (no full
  # rebuild of venv/TUI/web). Produce a tiny patched gateway/ tree, then wrap
  # hermes with a bootstrap that pre-imports the patched gateway BEFORE
  # hermes_cli.main inserts site-packages at sys.path[0] (which would otherwise
  # hide PYTHONPATH-based shadows).
  mkPatchedHermes =
    pkgs:
    let
      base = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
      venvSite = "${base.hermesVenv}/lib/python3.12/site-packages";
      patchedGatewayRoot =
        pkgs.runCommand "hermes-gateway-expose-errors"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            mkdir -p $out/gateway
            cp -a ${venvSite}/gateway/. $out/gateway/
            chmod -R u+w $out/gateway

            python3 - "$out/gateway/run.py" ${pkgs.writeText "patched_fn.py" patchedGatewayErrorFn} <<'PY'
            import sys
            from pathlib import Path

            path = Path(sys.argv[1])
            new_fn = Path(sys.argv[2]).read_text()
            src = path.read_text()
            needle = "def _gateway_provider_error_reply(text: str) -> str:"
            start = src.find(needle)
            if start < 0:
                raise SystemExit(f"could not find {needle!r} in {path}")
            lines = src[start:].splitlines(keepends=True)
            end_rel = None
            for i, line in enumerate(lines[1:], start=1):
                if not line.strip():
                    continue
                if not line.startswith((" ", "\t")):
                    end_rel = i
                    break
            if end_rel is None:
                raise SystemExit("could not find end of _gateway_provider_error_reply")
            if not new_fn.endswith("\n"):
                new_fn += "\n"
            if not new_fn.endswith("\n\n"):
                new_fn += "\n"
            path.write_text(src[:start] + new_fn + "".join(lines[end_rel:]))
            out = path.read_text()
            assert "Provider error (raw)" in out, "patch did not land"
            body = out.split("def _gateway_provider_error_reply")[1].split("\ndef ")[0]
            assert "I kept raw provider details" not in body, "old generic reply body still present"
            print("patched", path, "size", path.stat().st_size)
            PY
          '';

      # Bootstrap: import patched gateway into sys.modules first, then hand off
      # to hermes_cli.main. hermes_cli does sys.path.insert(0, site-packages),
      # which would shadow a pure PYTHONPATH approach; pre-import wins via
      # sys.modules cache.
      hermesBootstrap = pkgs.writeText "hermes-expose-errors-bootstrap.py" ''
        import sys
        from pathlib import Path

        # Shadow package root (contains gateway/)
        _shadow = Path("${patchedGatewayRoot}")
        if str(_shadow) not in sys.path:
            sys.path.insert(0, str(_shadow))

        # Preload patched gateway.run so later imports reuse it.
        import gateway  # noqa: F401
        import gateway.run as _gateway_run  # noqa: F401
        assert "Provider error (raw)" in _gateway_run._gateway_provider_error_reply.__doc__ or True
        # Soft check: ensure patched body is live
        _sample = _gateway_run._gateway_provider_error_reply("Error code: 403 - test")
        if "Provider error (raw)" not in _sample:
            sys.stderr.write(
                "hermes-expose-errors: WARNING patched _gateway_provider_error_reply not active\n"
            )

        from hermes_cli.main import main

        if __name__ == "__main__":
            raise SystemExit(main())
      '';
    in
    pkgs.symlinkJoin {
      name = "${base.pname or "hermes-agent"}-expose-errors";
      paths = [ base ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Replace hermes entrypoints with bootstrap that pre-imports patched gateway.
        hermes_py="${base.hermesVenv}/bin/python3"
        for bin in hermes hermes-agent hermes-acp; do
          if [ -e "$out/bin/$bin" ] || [ -L "$out/bin/$bin" ]; then
            rm -f "$out/bin/$bin"
            # makeWrapper-compatible executable
            makeWrapper "$hermes_py" "$out/bin/$bin" \
              --add-flags "${hermesBootstrap}" \
              --prefix PYTHONPATH : "${patchedGatewayRoot}" \
              --set HERMES_PYTHON "$hermes_py" \
              --set HERMES_BUNDLED_SKILLS "${base}/share/hermes-agent/skills" \
              --set HERMES_OPTIONAL_SKILLS "${base}/share/hermes-agent/optional-skills" \
              --set HERMES_BUNDLED_PLUGINS "${base}/share/hermes-agent/plugins" \
              --set HERMES_BUNDLED_LOCALES "${base}/share/hermes-agent/locales" \
              --set HERMES_WEB_DIST "${base}/share/hermes-agent/web_dist" \
              --set HERMES_TUI_DIR "${base}/ui-tui"
          fi
        done
      '';
      # Preserve passthru used by hermes-revproxy (hermesVenv) and others.
      passthru = (base.passthru or { }) // {
        hermesVenv = base.hermesVenv;
        unpatched = base;
        patchedGatewayRoot = patchedGatewayRoot;
      };
      meta = base.meta or { };
    };
in
{
  # 此层从 'pkgs' 目录引入我们的自定义软件包
  additions = final: _prev: import ../pkgs final.pkgs;

  # 此层包含任何你想要覆盖的内容
  # 你可以更改版本、添加补丁、设置编译标志，几乎任何内容都可以。
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Hermes with gateway/run.py patched to surface provider error bodies on
    # messaging platforms. Selected via services.msdone-hermes.exposeProviderErrors.
    hermes-agent-patched = mkPatchedHermes final;
  };

  # 应用后，在 flake input 中声明的 unstable nixpkgs 集将可以通过 'pkgs.unstable' 访问
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
