# 自定义软件包，其定义方式与 nixpkgs 中的类似
# 你可以使用 'nix build .#example' 来构建它们
pkgs: {
  # example = pkgs.callPackage ./example { };
  nextai-translator = pkgs.callPackage ./nextai-translator { };
}
