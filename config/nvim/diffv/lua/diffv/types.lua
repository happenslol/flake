---@class diffv.Hunk
---@field old_start number -- 1-indexed start line in old file
---@field old_count number -- number of lines in old file
---@field new_start number -- 1-indexed start line in new file
---@field new_count number -- number of lines in new file
---@field lines diffv.Line[]

---@class diffv.Line
---@field type "add" | "delete" | "context"
---@field content string
---@field old_lnum? number -- original line number in old file
---@field new_lnum? number -- original line number in new file

---@class diffv.DiffResult
---@field hunks diffv.Hunk[]
---@field old_lines string[] -- full old file as line array
---@field new_lines string[] -- full new file as line array

---@class diffv.FileChange
---@field path string
---@field old_path? string -- set for renames
---@field status "added" | "modified" | "deleted" | "renamed"
---@field hunks diffv.Hunk[]

---@class diffv.DiffView
---@field buffers number[] -- buffer handles
---@field windows number[] -- window handles
---@field tabnr? number -- tab page number
---@field layout string -- current layout ("side_by_side" or "inline")
---@field diff_result diffv.DiffResult
---@field context_lines number
---@field filetype string
---@field file_info? { path: string, old_label: string, new_label: string }
---@field file_changes diffv.FileChange[]
---@field current_index number
---@field config diffv.Config
---@field close fun()
---@field toggle_layout? fun() -- re-render with opposite layout

---@class diffv.Highlights
---@field add string
---@field delete string
---@field change string
---@field change_text string
---@field context_separator string

---@class diffv.Keymaps
---@field close string
---@field toggle_layout string
---@field increase_context string
---@field decrease_context string
---@field toggle_context string
---@field next_hunk string
---@field prev_hunk string

---@class diffv.Config
---@field layout "side_by_side" | "inline"
---@field context number -- lines of context around changes (0 = show all)
---@field git_cmd string
---@field highlights diffv.Highlights
---@field keymaps diffv.Keymaps

return {}
