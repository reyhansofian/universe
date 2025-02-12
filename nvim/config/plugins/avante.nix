{
  plugins.avante.enable = true;
  plugins.avante.luaConfig.pre = ''
    vim.env.OPENAI_API_KEY = ""
  '';
  plugins.avante.settings.provider = "openai";
  plugins.avante.settings.openai = {
    endpoint = "https://api.deepinfra.com/v1/openai";
    model = "deepseek-ai/DeepSeek-R1";
    temperature = 0;
    max_tokens = 4096;
  };
  plugins.avante.settings.vendors = rec {
    deepseek-v3 = {
      __inherited_from = "openai";
      endpoint = "https://api.deepinfra.com/v1/openai";
      model = "deepseek-ai/DeepSeek-V3";
      api_key_name = "OPENAI_API_KEY";
      temperature = 0;
      max_tokens = 4096;
    };

    qwenCoder = deepseek-v3 // {
      model = "Qwen/Qwen2.5-72B-Instruct";
    };

    llma-31-405b = deepseek-v3 // {
      model = "meta-llama/Meta-Llama-3.1-405B-Instruct";
    };
  };

  plugins.avante.settings.hints.enabled = true;
  plugins.avante.settings.windows = {
    wrap = true;
    width = 30;
    sidebar_header = {
      align = "center";
      rounded = true;
    };
  };

  plugins.avante.settings.highlights.diff = {
    current = "DiffText";
    incoming = "DiffAdd";
  };

  plugins.avante.settings.diff = {
    debug = false;
    autojump = true;
    list_opener = "copen";
  };
}
