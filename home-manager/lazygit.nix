{
  pkgs,
  ...
}:

{
  xdg.configFile."lazygit/config.yml".source = ./lazygit.yml;
}
