require "nvchad.mappings"

local map = vim.keymap.set

local function new_file()
  local current_path = vim.api.nvim_buf_get_name(0)
  local project_root = current_path ~= "" and vim.fs.root(current_path, ".git") or nil
  project_root = project_root or vim.fn.getcwd()

  vim.ui.input({
    prompt = "New file: ",
    default = vim.fs.normalize(project_root) .. "/",
    completion = "file",
  }, function(path)
    path = path and vim.trim(path) or ""
    if path == "" then
      return
    end

    path = vim.fs.normalize(vim.fn.expand(path))
    local parent = vim.fs.dirname(path)
    if vim.fn.isdirectory(parent) == 0 then
      vim.fn.mkdir(parent, "p")
    end

    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
end

-- Basics
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Space + n → create a named buffer in the current project
map("n", "<leader>n", new_file, { desc = "Create new project file" })

-- Tab / Shift-Tab → move through NvChad's buffer tabs.
-- This is normal-mode only, so insert-mode Tab keeps accepting completions.
map("n", "<Tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "Go to next buffer" })
map("n", "<S-Tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Go to previous buffer" })

local function goto_buffer(position)
  local buffers = vim.t.bufs or vim.tbl_filter(function(buf)
    return vim.fn.buflisted(buf) == 1
  end, vim.api.nvim_list_bufs())
  local bufnr = buffers[position]

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    require("nvchad.tabufline").goto_buf(bufnr)
  else
    vim.notify("No buffer " .. position, vim.log.levels.INFO)
  end
end

-- Ghostty/tmux forward Cmd + 1..9 as function keys. F11/F12 stay
-- reserved for the save-current/save-all shortcuts above.
local buffer_shortcut_keys = { "F5", "F6", "F7", "F8", "F9", "F10", "F13", "F14", "F15" }

for position, forwarded_key in ipairs(buffer_shortcut_keys) do
  local function jump()
    goto_buffer(position)
  end

  map({ "n", "i", "v" }, "<D-" .. position .. ">", jump, { desc = "Go to buffer " .. position })
  map({ "n", "i", "v" }, "<" .. forwarded_key .. ">", jump, { desc = "Go to buffer " .. position })
end

-- Option + d → diagnostic popup
map("n", "<A-d>", function()
  vim.diagnostic.open_float(nil, {
    focusable = false,
    border = "rounded",
    source = "always",
  })
end, { desc = "Show diagnostics (float)" })

-- Cmd + s → save the current buffer
map({ "n", "i", "v" }, "<D-s>", "<Cmd>update<CR>", { desc = "Save current buffer" })
map("c", "<D-s>", "<C-c><Cmd>update<CR>", { desc = "Save current buffer" })
map({ "n", "i", "v" }, "<F11>", "<Cmd>update<CR>", { desc = "Save current buffer" })
map("c", "<F11>", "<C-c><Cmd>update<CR>", { desc = "Save current buffer" })

-- Cmd + Shift + s → save all buffers
map({ "n", "i", "v" }, "<D-S-s>", "<Cmd>wall<CR>", { desc = "Save all buffers" })
map("c", "<D-S-s>", "<C-c><Cmd>wall<CR>", { desc = "Save all buffers" })
map({ "n", "i", "v" }, "<F12>", "<Cmd>wall<CR>", { desc = "Save all buffers" })
map("c", "<F12>", "<C-c><Cmd>wall<CR>", { desc = "Save all buffers" })

map("n", "<leader>ft", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "Format file" })

-- Option + w → quit current window
map("n", "<A-w>", "<cmd>q<CR>", { desc = "Quit window" })
