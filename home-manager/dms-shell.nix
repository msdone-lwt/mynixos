{
  config,
  ...
}:

{
  xdg.configFile."DankMaterialShell" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/mynixos/home-manager/DankMaterialShell";
  };
}
