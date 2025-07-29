{
  plugins.avante = {
    enable = true;

    settings = {
      # Provider Configuration
      provider = "claude";

      # Vendor Models Configuration
      providers = rec {
        claude = {
          endpoint = "https://api.anthropic.com";
          model = "claude-3-7-sonnet-20250219";
          extra_request_body.temperature = 0;
          extra_request_body.max_tokens = 9116;
          api_key_name = "ANTHROPIC_API_KEY";
        };
        openai = {
          endpoint = "https://api.deepinfra.com/v1/openai";
          model = "deepseek-ai/DeepSeek-R1";
          extra_request_body.temperature = 0;
          extra_request_body.max_tokens = 8092;
          api_key_name = "OPENAI_API_KEY";
        };

        deepseek-v3 = {
          __inherited_from = "openai";
          endpoint = "https://api.deepinfra.com/v1/openai";
          model = "deepseek-ai/DeepSeek-V3";
          api_key_name = "OPENAI_API_KEY";
          extra_request_body.temperature = 0;
          extra_request_body.max_tokens = 8092;
          disable_tools = true;
        };

        qwenCoder = deepseek-v3 // { model = "Qwen/Qwen3-235B-A22B"; };

        llma-31-405b = deepseek-v3 // {
          model = "meta-llama/Meta-Llama-3.1-405B-Instruct";
          disable_tools = true;
        };

        claude-35 = {
          __inherited_from = "claude";
          endpoint = "https://api.anthropic.com";
          model = "claude-3-5-sonnet-20241022";
          api_key_name = "ANTHROPIC_API_KEY";
          extra_request_body.temperature = 0;
          extra_request_body.max_tokens = 8092;
          disable_tools = true;
        };

        claude-4 = {
          __inherited_from = "claude";
          endpoint = "https://api.anthropic.com";
          model = "claude-sonnet-4-20250514";
          api_key_name = "ANTHROPIC_API_KEY";
          extra_request_body.temperature = 1;
          extra_request_body.max_tokens = 8092;
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
