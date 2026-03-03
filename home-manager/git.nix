{ 
  pkgs, 
  ... 
}: 
{
  programs.git = {
    enable = true;
    settings = { 
      # aliases = {
      #   st = "status";
      #   co = "checkout";
      #   br = "branch";
      # };
      user = {
        name = "msdone";
	email = "lwt6077@gmail.com";
      };
      credential = {
	helper = "store";
      };
      safe = {
        directory = "/etc/nixos";
      };
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };
}
