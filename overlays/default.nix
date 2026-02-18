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
  };

  # 应用后，在 flake input 中声明的 unstable nixpkgs 集将可以通过 'pkgs.unstable' 访问 
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
