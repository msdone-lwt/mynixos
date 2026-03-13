{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libGL,
  libgbm,
  libxkbcommon,
  nspr,
  nss,
  pango,
  udev,
  xorg,
  e2fsprogs,
  xdotool,
  openssl,
  webkitgtk_4_1,
  libsoup_3,
  libayatana-appindicator, # ⬇️ 1. 新增：系统托盘图标依赖库
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nextai-translator";
  version = "0.6.9";

  src = fetchurl {
    url = "https://github.com/nextai-translator/nextai-translator/releases/download/v${finalAttrs.version}/NextAI.Translator_${finalAttrs.version}_amd64.deb";
    hash = "sha256-rw9ITdoZSWrmG14JcCYhcd+ghy3CqZc1p/5eB2GWDHQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib at-spi2-atk cairo cups dbus expat glib gtk3
    libGL libgbm libxkbcommon nspr nss pango udev
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxcb
    (lib.getLib stdenv.cc.cc)
    e2fsprogs
    xdotool
    openssl
    webkitgtk_4_1
    libsoup_3
    libayatana-appindicator # ⬇️ 2. 将它加入构建环境
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share $out/lib

    # 抓取主程序
    cp usr/bin/app $out/bin/nextai-translator
    chmod +x $out/bin/nextai-translator

    # 拷贝资源
    if [ -d "usr/lib/NextAI Translator" ]; then
      cp -r "usr/lib/NextAI Translator" $out/lib/nextai-translator
    fi
    cp -r usr/share/* $out/share/

    # 修复桌面快捷方式
    mv "$out/share/applications/NextAI Translator.desktop" "$out/share/applications/nextai-translator.desktop"
    sed -i 's|^Exec=app|Exec=nextai-translator|g' "$out/share/applications/nextai-translator.desktop"
    sed -i 's|^Icon=app|Icon=nextai-translator|g' "$out/share/applications/nextai-translator.desktop"

    runHook postInstall
  '';

  preFixup = ''
    patchelf --add-needed libGL.so.1 $out/bin/nextai-translator
  '';

  postFixup = ''
    # ⬇️ 3. 核心修复：将托盘库的路径强行塞进环境变量里，程序启动时就能瞬间找到！
    wrapProgram $out/bin/nextai-translator \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libayatana-appindicator ]}" \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
      --add-flags "--no-sandbox" \
      --add-flags "--disable-gpu-sandbox" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations"
  '';

  meta = with lib; {
    description = "NextAI Translator";
    homepage = "https://github.com/nextai-translator/nextai-translator";
    mainProgram = "nextai-translator";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
