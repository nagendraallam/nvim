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

-- Cmd + n → create a named buffer in the current project
map({ "n", "i", "v" }, "<D-n>", new_file, { desc = "Create new project file" })

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

-- Cmd + Shift + s → save all buffers
map({ "n", "i", "v" }, "<D-S-s>", "<Cmd>wall<CR>", { desc = "Save all buffers" })
map("c", "<D-S-s>", "<C-c><Cmd>wall<CR>", { desc = "Save all buffers" })

map("n", "<leader>ft", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "Format file" })

-- Option + w → quit current window
map("n", "<A-w>", "<cmd>q<CR>", { desc = "Quit window" })
