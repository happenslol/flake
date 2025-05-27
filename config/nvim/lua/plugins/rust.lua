---@type LazySpec
return {
  {
    "mrcjkb/rustaceanvim",
    lazy = false,
    version = "^6",
    ft = { "rust" },

    ---@module "rustaceanvim"
    ---@type rustaceanvim.Config
    opts = {
      tools = {
        code_actions = {
          keys = {
            confirm = { "<cr>", "<space>" },
            quit = { "q", "<esc>" },
          },
        },

        float_win_config = {
          border = "rounded",
        },
      },

      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>dR", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })

          vim.keymap.set("n", "grm", function()
            vim.cmd.RustLsp("expandMacro")
          end, { desc = "Expand Macro", buffer = bufnr })

          vim.keymap.set("n", "gra", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Actions", buffer = bufnr })

          vim.keymap.set("n", "K", function()
            vim.cmd.RustLsp({ "hover", "actions" })
          end, { desc = "", buffer = bufnr })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              features = "all",
              targetDir = true,
            },

            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
            },
          },
        },
      },

      dap = {
        adapter = {
          type = "server",
          port = "${port}",
          host = "127.0.0.1",
          executable = { command = "codelldb", args = { "--port", "${port}" } },
        },
      },

      was_g_rustaceanvim_sourced = nil,
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable("rust-analyzer") == 0 then
        vim.notify("rust-analyzer not found in PATH", vim.log.levels.ERROR)
      end
    end,
  },
}
