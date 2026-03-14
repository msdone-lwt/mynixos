{
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/mynixos/home-manager/AstroNvim";
  };
}
