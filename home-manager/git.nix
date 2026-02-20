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
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };
}
