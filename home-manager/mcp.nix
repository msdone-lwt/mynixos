{
  pkgs,
  ...
}:

{
  programs.mcp = {
    enable = true;
    servers = {
      notion-mcp-server = {
        args = [
          "-y"
          "@orbit-logistics/notion-mcp-server"
          "-t"
          "$NOTION_INTEGRATION_TOKEN"
        ];
        command = "npx";
        description = "MCP server for Notion integration.(install by <npm install -g @orbit-logistics/notion-mcp-server>)";
      };
    };
  };
  programs.codex.enableMcpIntegration = true;
  programs.claude-code.enableMcpIntegration = true;
}
