{
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      aliases = {
        gerrit-push = "!f() { if [ -z \"$1\" ]; then echo \"Usage: git gerrit-push <remote>/<branch>\"; return 1; fi; remote_branch_pair=\"$1\"; remote=\"\${remote_branch_pair%%/*}\"; branch=\"\${remote_branch_pair#*/}\"; if [ \"$remote\" = \"$branch\" ] && ! echo \"$remote_branch_pair\" | grep -q \"/\"; then echo \"Error: Argument must be in <remote>/<branch> format (e.g., origin/master).\"; echo \"If you meant to push to a branch on 'origin', use 'origin/$branch'.\"; return 1; fi; echo \"Pushing HEAD to $remote for branch $branch (refs/for/$branch)...\"; git push -u \"$remote\" \"HEAD:refs/for/$branch\"; }; f";
      };
      user = {
        name = "msdone";
        email = "lwt6077@gmail.com";
      };
      credential = {
        helper = "store";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
      merge = {
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
        tool = "nvimdiff";
      };
    };
  };
}
