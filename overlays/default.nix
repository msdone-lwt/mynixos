 # 此文件用于定义覆盖层 (Overlays) 
{inputs, ...}: {
  # 此层从 'pkgs' 目录引入我们的自定义软件包 
  additions = final: _prev: import ../pkgs final.pkgs;

  # 此层包含任何你想要覆盖的内容
  # 你可以更改版本、添加补丁、设置编译标志，几乎任何内容都可以。 
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # sparkle 开启 tun 模式
    sparkle = prev.sparkle.overrideAttrs (oldAttrs: {
      postFixup = (oldAttrs.postFixup or "") + ''
        echo "正在 Overlay 中替换 Sparkle 内核..."
        
        target="$out/opt/sparkle/resources/sidecar/mihomo"
        
        # 1. 删除自带的无权限内核
        rm -f "$target"
        
        # 2. 创建软链接指向系统 Wrapper（/run/wrappers/bin/mihomo）
        ln -s /run/wrappers/bin/mihomo "$target"
      '';
    });
    # 覆盖 clash-verge-rev 软件包
    # FIXME: 更新版本或者使用 nixpkgs 官方包
    clash-verge-rev = prev.clash-verge-rev.overrideAttrs (oldAttrs: rec {
      # 如果该版本的依赖或构建脚本没有显著变化，通常只需要覆盖 version 和 src 即可
      version = "2.4.6"; # 你指定的版本
      src = prev.fetchurl {
        # 构造对应的 GitHub 下载链接
        url = "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${version}/Clash.Verge_${version}_amd64.deb";
        # 这是一个占位哈希值。当你第一次运行构建时，Nix 会报错并告诉你正确的哈希值。
        hash = "sha256-QXPb6H/wLzg3m6h522WhKOzm2LPmbU0sB636mJq3Rx0=";  
      };
      # 1. 添加自动修复工具和解压工具
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ 
        prev.autoPatchelfHook 
        prev.dpkg 
	prev.makeWrapper
      ];

      # 2. 添加运行时依赖库（Clash Verge 运行必须的库）
      buildInputs = (oldAttrs.buildInputs or [ ]) ++ (with prev; [
        gtk3
        webkitgtk_4_1 # 2.4.x 版本通常需要 4.1 版本的 webkit
        networkmanager
        libayatana-appindicator
        libglvnd # 提供 libGL.so.1
      ]);

      unpackPhase = "dpkg-deb -x $src .";

      installPhase = ''
        mkdir -p $out
        cp -r usr/* $out/
         
        # 2. 包装二进制文件，显式指定库查找路径 (LD_LIBRARY_PATH)
        # 这能解决 dlopen 找不到 libayatana-appindicator3.so 的问题
        wrapProgram $out/bin/clash-verge \
        --prefix LD_LIBRARY_PATH : "${prev.lib.makeLibraryPath [ prev.libayatana-appindicator prev.gtk3 ]}"
        
        chmod +x $out/bin/*
      '';

      sourceRoot = ".";
    });
  };

  # 应用后，在 flake input 中声明的 unstable nixpkgs 集将可以通过 'pkgs.unstable' 访问 
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
