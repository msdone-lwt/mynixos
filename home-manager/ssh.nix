{
  pkgs,
  ...
}:

{
  programs.ssh = {
    enable = true;
    settings = {
      "Host msdone1" = {
        HostName = "43.172.84.26";
        User = "msdone";
        IdentityFile = "~/Downloads/nixosserver.pem";
      };
    };
  };
}
