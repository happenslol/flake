return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    opts = {
      provider = "gemini",
      cursor_applying_provider = "groq",

      behaviour = {
        -- enable_claude_text_editor_tool_mode = true,
        enable_cursor_planning_mode = true,
      },

      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-3-7-sonnet-20250219",
        timeout = 30000,
        temperature = 0,
        max_tokens = 20480,
      },

      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o",
        timeout = 30000,
        temperature = 0,
        max_tokens = 8192,
      },

      gemini = {
        endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
        model = "gemini-2.0-flash",
        timeout = 30000,
        temperature = 0,
        max_tokens = 20480,
      },

      vendors = {
        groq = {
          __inherited_from = "openai",
          api_key_name = "GROQ_API_KEY",
          endpoint = "https://api.groq.com/openai/v1/",
          model = "llama-3.3-70b-versatile",
          max_tokens = 32768,
        },
      },

      hints = { enabled = false },
      web_search_engine = { provider = "kagi" },

      windows = { sidebar_header = { enabled = false } },

      system_prompt = function()
        return require("mcphub").get_hub_instance():get_active_servers_prompt()
      end,
      custom_tools = function()
        return { require("mcphub.extensions.avante").mcp_tool() }
      end,
    },

    build = "make",

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",

      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
          },
        },
      },

      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
  },

  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "MCPHub",
    build = "bundled_build.lua",
    config = function()
      require("mcphub").setup({
        use_bundled_binary = true,
        extensions = {
          avante = {
            make_slash_commands = true,
          },
        },
      })
    end,
  },
}
