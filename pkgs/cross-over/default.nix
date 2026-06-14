{ lib
, stdenv
, fetchFromGitHub
, fetchNpmDeps
, makeWrapper
, nodejs
, python3
, electron
, copyDesktopItems
, makeDesktopItem
, npmHooks
, libX11
, libXrandr
, libXtst
, libXt
,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "crossover";
  version = "3.4.2";

  src = fetchFromGitHub {
    owner = "lacymorrow";
    repo = "crossover";
    rev = "v${finalAttrs.version}";
    hash = "sha256-dUHKlKdIrbzdSE9BxILX0ptoGAwgiHzNCV9d7YjIUuk=";
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) pname version src;
    hash = "sha256-lqwepQYGexsKE0EZ0OybL6icVXrCXwUlAxYhwvHcZqk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    chmod +w package-lock.json

    # Disable auto-update feature
    substituteInPlace src/main.js \
      --replace-fail "autoUpdate.update()" "// autoUpdate.update() - disabled for Nix" \
      || true

    substituteInPlace src/main/auto-update.js \
      --replace-fail "autoUpdater.checkForUpdates()" "// autoUpdater.checkForUpdates() - disabled for Nix" \
      --replace-fail "autoUpdater.checkForUpdatesAndNotify()" "// autoUpdater.checkForUpdatesAndNotify() - disabled for Nix" \
      || true
  '';

  nativeBuildInputs = [
    makeWrapper
    nodejs
    python3
    npmHooks.npmConfigHook
    copyDesktopItems
  ];

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = 1;

  buildPhase = ''
    runHook preBuild

    npm install
    ./node_modules/.bin/electron-builder \
      --dir \
      -c.electronDist=${electron.dist} \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/crossover"
    cp -r dist/*-unpacked/{locales,resources,resources.pak} "$out/share/crossover"

    # Remove auto-update file
    rm -f "$out/share/crossover/resources/app-update.yml"

    # Install icons
    for size in 256 512; do
      if [ -f "assets/icon-''${size}x''${size}.png" ]; then
        install -Dm644 "assets/icon-''${size}x''${size}.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/crossover.png"
      fi
    done

    # Fallback: try build/icon.png or src/static/icons/icon.png
    if [ ! -f "$out/share/icons/hicolor/256x256/apps/crossover.png" ]; then
      for iconPath in build/icon.png src/static/icons/icon.png resources/icon.png assets/icon.png; do
        if [ -f "$iconPath" ]; then
          install -Dm644 "$iconPath" "$out/share/icons/hicolor/256x256/apps/crossover.png"
          break
        fi
      done
    fi

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${lib.getExe electron} "$out/bin/crossover" \
      --add-flags "$out/share/crossover/resources/app.asar" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          libX11
          libXrandr
          libXtst
          libXt
        ]
      }" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "crossover";
      exec = "crossover";
      icon = "crossover";
      desktopName = "CrossOver";
      comment = "Crosshair overlay for any screen";
      categories = [ "Game" "Utility" ];
      startupWMClass = "crossover";
    })
  ];

  meta = {
    description = "Crosshair overlay for any screen";
    homepage = "https://github.com/lacymorrow/crossover";
    changelog = "https://github.com/lacymorrow/crossover/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ msdone ];
    mainProgram = "crossover";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
  };
})
