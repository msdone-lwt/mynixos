{
  copyDesktopItems,
  electron_40,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeDesktopItem,
  makeWrapper,
  nodejs,
  pnpm_10_29_2,
  pnpmConfigHook,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "any-listen";
  version = "0.7.0-beta.28";

  src = fetchFromGitHub {
    owner = "any-listen";
    repo = "any-listen-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IGb96chZ9tOMkUOIPbTMoyCDeEsV299paHRmNeW6I8w=";
    fetchSubmodules = true;
  };

  sourceRoot = "source/any-listen";

  patches = [
    # Show the main window explicitly on initial Linux launch. Otherwise it can
    # remain hidden until a second instance calls showWindow().
    ./show-window-after-load.patch
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10_29_2;
    fetcherVersion = 3;
    sourceRoot = "source/any-listen";
    hash = "sha256-vvkrTNM4sUJ5W9Mrcomkci7U0OZ116RMLju5zYvyBrQ=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    nodejs
    pnpm_10_29_2
    pnpmConfigHook
  ];

  env = {
    ELECTRON_OVERRIDE_DIST_PATH = "${electron_40}/libexec/electron";
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  postPatch = ''
    substituteInPlace packages/desktop/build-config/build-pack.cjs \
      --replace-fail "const options = {" "const options = {
      electronDist: '${electron_40}/libexec/electron',
      electronVersion: '${electron_40.version}',"
  '';

  buildPhase = ''
    runHook preBuild

    export ELECTRON_BUILDER_CACHE="$TMPDIR/electron-builder-cache"
    for electronPackage in node_modules/electron packages/desktop/node_modules/electron; do
      if [ -d "$electronPackage" ]; then
        echo "electron" > "$electronPackage/path.txt"
      fi
    done

    pnpm --offline -F @shared/scripts build:desktop:dir

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/${finalAttrs.pname}"
    cp -r build/linux-unpacked/resources "$out/share/${finalAttrs.pname}/"

    makeWrapper "${electron_40}/bin/electron" "$out/bin/any-listen" \
      --inherit-argv0 \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --add-flags "$out/share/${finalAttrs.pname}/resources/app.asar" \
      --add-flags "-dt"

    for icon in packages/desktop/resources/icons/*x*.png; do
      size="''${icon##*/}"
      size="''${size%.png}"
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/any-listen.png"
    done

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "any-listen";
      exec = "any-listen %u";
      icon = "any-listen";
      desktopName = "Any Listen";
      comment = "Cross-platform private music playback service";
      categories = [
        "AudioVideo"
        "Audio"
        "Player"
        "Music"
      ];
      mimeTypes = ["x-scheme-handler/anylisten"];
    })
  ];

  meta = {
    description = "Cross-platform private music playback service";
    homepage = "https://github.com/any-listen/any-listen-desktop";
    changelog = "https://github.com/any-listen/any-listen-desktop/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.unfreeRedistributable;
    maintainers = with lib.maintainers; [msdone];
    mainProgram = "any-listen";
    platforms = ["x86_64-linux"];
  };
})
