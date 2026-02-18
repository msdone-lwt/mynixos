 # 此文件用于定义覆盖层 (Overlays) 
{inputs, ...}: {
  # 此层从 'pkgs' 目录引入我们的自定义软件包 
  additions = final: _prev: import ../pkgs final.pkgs;

  # 此层包含任何你想要覆盖的内容
  # 你可以更改版本、添加补丁、设置编译标志，几乎任何内容都可以。 
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # 例如 = prev.example.overrideAttrs (oldAttrs: rec { 
    # ...
    # });
    # 覆盖 clash-verge-rev 软件包
    clash-verge-rev = prev.clash-verge-rev.overrideAttrs (oldAttrs: rec {
      # 如果该版本的依赖或构建脚本没有显著变化，通常只需要覆盖 version 和 src 即可
      version = "2.4.5"; # 你指定的版本
      src = prev.fetchurl {
        # 构造对应的 GitHub 下载链接
        url = "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${version}/Clash.Verge_${version}_amd64.deb";
        # 这是一个占位哈希值。当你第一次运行构建时，Nix 会报错并告诉你正确的哈希值。
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";  
      };
      # 关键修复 1：添加 dpkg 工具用于解压 .deb 文件
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.dpkg ];

      # 关键修复 2：定义解压命令
      unpackPhase = "dpkg-deb -x $src .";

      # 关键修复 3：由于 .deb 解压后路径通常在 ./usr 下，需要指定源码根目录
      sourceRoot = ".";
      
      # 如果 2.4.5 版本的内部结构有变，可能还需要调整 postInstall
      # 但通常对于二进制包，保持原有的 postInstall 即可
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
