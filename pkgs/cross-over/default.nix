{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
  python3,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  npmHooks,
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
    runHook postInstall
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
