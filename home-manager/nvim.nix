{
  pkgs,
  config,
  ...
}:

{
  home.file.".config/nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/msdone/mynixos/home-manager/AstroNvim";
  };
}
