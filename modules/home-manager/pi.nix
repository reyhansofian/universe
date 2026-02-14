{
  config,
  pkgs,
  lib,
  ...
}:
let
  piDir = ./pi;
  homeDir = config.home.homeDirectory;
in
{
  # Pi auth secrets
  sops.secrets = {
    pi_auth_anthropic_refresh = { };
    pi_auth_anthropic_access = { };
    pi_auth_anthropic_expires = { };
    outline_api_key = { };
  };

  # Templated files with secrets injected at activation
  sops.templates."pi-auth.json" = {
    path = "${homeDir}/.pi/agent/auth.json";
    content = ''
      {
        "anthropic": {
          "type": "oauth",
          "refresh": "${config.sops.placeholder.pi_auth_anthropic_refresh}",
          "access": "${config.sops.placeholder.pi_auth_anthropic_access}",
          "expires": ${config.sops.placeholder.pi_auth_anthropic_expires}
        }
      }
    '';
  };

  sops.templates."pi-mcp.json" = {
    path = "${homeDir}/.pi/agent/mcp.json";
    content = builtins.toJSON {
      settings = {
        idleTimeout = 0;
        directTools = false;
      };
      mcpServers = {
        serena = {
          command = "uvx";
          args = [
            "--from"
            "git+https://github.com/oraios/serena"
            "serena"
            "start-mcp-server"
            "--context"
            "agent"
            "--project-from-cwd"
            "--open-web-dashboard"
            "false"
          ];
          lifecycle = "eager";
          directTools = [
            "read_file"
            "list_dir"
            "find_file"
            "search_for_pattern"
            "get_symbols_overview"
            "find_symbol"
            "find_referencing_symbols"
            "write_memory"
            "read_memory"
            "list_memories"
            "delete_memory"
            "edit_memory"
            "activate_project"
            "get_current_config"
            "onboarding"
          ];
        };
        memory = {
          command = "bun";
          args = [
            "run"
            "${homeDir}/.config/memory/mcp/index.ts"
          ];
          lifecycle = "lazy";
          directTools = true;
        };
        qmd = {
          command = "qmd";
          args = [ "mcp" ];
          lifecycle = "lazy";
          directTools = true;
        };
        context7 = {
          command = "npx";
          args = [
            "-y"
            "@upstash/context7-mcp"
          ];
          lifecycle = "lazy";
          directTools = true;
        };
        linear = {
          url = "https://mcp.linear.app/sse";
          auth = "oauth";
          lifecycle = "lazy";
          directTools = true;
        };
        outline = {
          command = "npx";
          args = [
            "-y"
            "--package=outline-mcp-server@latest"
            "-c"
            "outline-mcp-server-stdio"
          ];
          env = {
            OUTLINE_API_KEY = config.sops.placeholder.outline_api_key;
            OUTLINE_API_URL = "https://app.getoutline.com/api";
          };
          lifecycle = "lazy";
          directTools = true;
        };
      };
    };
  };

  # Static config files
  home.file = {
    # Core config
    ".pi/agent/settings.json".source = "${piDir}/settings.json";
    ".pi/agent/AGENTS.md".source = "${piDir}/AGENTS.md";

    # Custom agents
    ".pi/agent/agents/architect-reviewer.md".source = "${piDir}/agents/architect-reviewer.md";
    ".pi/agent/agents/connector.md".source = "${piDir}/agents/connector.md";
    ".pi/agent/agents/critic.md".source = "${piDir}/agents/critic.md";
    ".pi/agent/agents/pragmatist.md".source = "${piDir}/agents/pragmatist.md";
    ".pi/agent/agents/quality-reviewer.md".source = "${piDir}/agents/quality-reviewer.md";
    ".pi/agent/agents/security-reviewer.md".source = "${piDir}/agents/security-reviewer.md";
    ".pi/agent/agents/test-reviewer.md".source = "${piDir}/agents/test-reviewer.md";
    ".pi/agent/agents/visionary.md".source = "${piDir}/agents/visionary.md";

    # Custom skills
    ".pi/agent/skills/create-linear-ticket/SKILL.md".source =
      "${piDir}/skills/create-linear-ticket/SKILL.md";
    ".pi/agent/skills/gsd-execute-phase/SKILL.md".source = "${piDir}/skills/gsd-execute-phase/SKILL.md";
    ".pi/agent/skills/gsd-new-project/SKILL.md".source = "${piDir}/skills/gsd-new-project/SKILL.md";
    ".pi/agent/skills/gsd-plan-phase/SKILL.md".source = "${piDir}/skills/gsd-plan-phase/SKILL.md";
    ".pi/agent/skills/handoff/SKILL.md".source = "${piDir}/skills/handoff/SKILL.md";
    ".pi/agent/skills/read-linear-ticket/SKILL.md".source =
      "${piDir}/skills/read-linear-ticket/SKILL.md";
    ".pi/agent/skills/read-outline/SKILL.md".source = "${piDir}/skills/read-outline/SKILL.md";
    ".pi/agent/skills/write-outline/SKILL.md".source = "${piDir}/skills/write-outline/SKILL.md";

    # Extensions
    ".pi/agent/extensions/editor-input.ts".source = "${piDir}/extensions/editor-input.ts";
    ".pi/agent/extensions/memory.ts".source = "${piDir}/extensions/memory.ts";
    ".pi/agent/extensions/damage-control/index.ts".source =
      "${piDir}/extensions/damage-control/index.ts";
    ".pi/agent/extensions/damage-control/package.json".source =
      "${piDir}/extensions/damage-control/package.json";
    ".pi/agent/extensions/damage-control/package-lock.json".source =
      "${piDir}/extensions/damage-control/package-lock.json";
    ".pi/agent/extensions/damage-control/patterns.yaml".source =
      "${piDir}/extensions/damage-control/patterns.yaml";
  };

  # Install damage-control node_modules after activation
  home.activation.piDamageControlDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${homeDir}/.pi/agent/extensions/damage-control/node_modules" ]; then
      cd "${homeDir}/.pi/agent/extensions/damage-control"
      ${pkgs.nodejs}/bin/npm install --no-audit --no-fund 2>/dev/null || true
    fi
  '';
}
