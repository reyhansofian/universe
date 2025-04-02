{
  plugins.avante = {
    enable = true;

    settings = {
      # Provider Configuration
      provider = "claude";
      openai = {
        endpoint = "https://api.deepinfra.com/v1/openai";
        model = "deepseek-ai/DeepSeek-R1";
        temperature = 0;
        max_tokens = 8092;
        api_key_name = "OPENAI_API_KEY";
      };

      claude = {
        endpoint = "https://api.anthropic.com";
        model = "claude-3-7-sonnet-20250219";
        temperature = 0;
        max_tokens = 9116;
        api_key_name = "ANTHROPIC_API_KEY";
      };

      copilot.model = "claude-3.5-sonnet";
      copilot.temperature = 0;
      copilot.max_tokens = 4096;

      # Vendor Models Configuration
      vendors = rec {
        deepseek-v3 = {
          __inherited_from = "openai";
          endpoint = "https://api.deepinfra.com/v1/openai";
          model = "deepseek-ai/DeepSeek-V3";
          api_key_name = "OPENAI_API_KEY";
          temperature = 0;
          max_tokens = 8092;
        };

        qwenCoder = deepseek-v3 // { model = "Qwen/Qwen2.5-72B-Instruct"; };

        llma-31-405b = deepseek-v3 // {
          model = "meta-llama/Meta-Llama-3.1-405B-Instruct";
        };

        claude-35 = {
          __inherited_from = "claude";
          endpoint = "https://api.anthropic.com";
          model = "claude-3-5-sonnet-20241022";
          api_key_name = "ANTHROPIC_API_KEY";
          temperature = 0;
          max_tokens = 8092;
        };
      };

      # UI Configuration
      hints.enabled = true;
      windows = {
        wrap = true;
        width = 30;
        sidebar_header = {
          align = "center";
          rounded = true;
        };
      };

      # Diff Configuration
      highlights.diff = {
        current = "DiffText";
        incoming = "DiffAdd";
      };
      diff = {
        debug = false;
        autojump = true;
        list_opener = "copen";
      };
    };
  };
}
