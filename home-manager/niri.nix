{
  config,
  ...
}:

{
  xdg.configFile."niri" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/mynixos/home-manager/niri";
  };
}
