{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchNpmDeps,
  makeWrapper,
  nodejs,
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
  '';

  nativeBuildInputs = [
    makeWrapper
    nodejs
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
