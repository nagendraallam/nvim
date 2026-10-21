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
