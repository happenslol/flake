-- TODO: Find a solution for libuv segfaults
-- and add this back

require "neo-tree".setup {
  close_if_last_window = false,
  window = {
    width = 30,
    mappings = {
      ["<cr>"] = "open_with_window_picker",
      ["o"] = "open_with_window_picker",
    },
  },
  filesystem = {
    follow_current_file = true,
    hijack_netrw_behavior = "open_current",
    use_libuv_file_watcher = true,
    filtered_items = { visible = true },
  },
  event_handlers = {
    {
      event = "neo_tree_buffer_enter",
      handler = function(_)
        vim.opt_local.signcolumn = "auto"
      end
    },
  },
}
