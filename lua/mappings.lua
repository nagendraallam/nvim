require "nvchad.mappings"

local map = vim.keymap.set

-- Basics
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Option + d → diagnostic popup
map("n", "<A-d>", function()
  vim.diagnostic.open_float(nil, {
    focusable = false,
    border = "rounded",
    source = "always",
  })
end, { desc = "Show diagnostics (float)" })

-- Cmd + s → save all files
map("n", "<D-s>", "<cmd>wa<CR>", { desc = "Save all files" })
map({ "i", "v" }, "<D-s>", "<Esc><cmd>wa<CR>", { desc = "Save all files" })
map("c", "<D-s>", "<C-c><cmd>wa<CR>", { desc = "Save all files" })

map("n", "<leader>ft", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "Format file" })

-- Option + w → quit current window
map("n", "<A-w>", "<cmd>q<CR>", { desc = "Quit window" })
