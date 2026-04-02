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

---@class diffv.View
---@field buffers number[] -- diff buffer handles
---@field windows number[] -- diff window handles
---@field tabnr number
---@field layout "side_by_side" | "inline"
---@field diff_result diffv.DiffResult
---@field context_lines number
---@field _saved_context? number
---@field filetype string
---@field file_info { path: string, old_label: string, new_label: string }
---@field file_changes diffv.FileChange[]
---@field current_index number
---@field config diffv.Config
---@field close fun()
---@field toggle_layout_impl fun()

---@class diffv.Highlights
---@field minus string -- left/old line background
---@field minus_emph string -- left/old changed word background
---@field plus string -- right/new line background
---@field plus_emph string -- right/new changed word background
---@field minus_nr string -- left/old line number foreground
---@field plus_nr string -- right/new line number foreground
---@field filler string -- diff filler lines
---@field context_separator string

---@class diffv.Keymaps
---@field global table<string, string|function> key → action shared across all views
---@field diff table<string, string|function> key → action for diff buffers
---@field filelist table<string, string|function> key → action for file list panel

--- Interface that every diff engine must implement.
---@class diffv.DiffEngine
---@field diff fun(old_text: string, new_text: string, opts?: table): diffv.DiffResult
---@field word_diff fun(old_line: string, new_line: string): { old_ranges: number[][], new_ranges: number[][] }
---@field line_distance fun(old_line: string, new_line: string): number

---@class diffv.Config
---@field layout "side_by_side" | "inline"
---@field context number -- lines of context around changes (0 = show all)
---@field git_cmd string
---@field diff_engine string -- "line" or "semantic" or a custom registered engine
---@field highlights diffv.Highlights
---@field status_icons table<string, string> -- M/A/D/R → icon string
---@field keymaps diffv.Keymaps

return {}
