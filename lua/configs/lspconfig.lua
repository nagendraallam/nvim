local nvlsp = require "nvchad.configs.lspconfig"
nvlsp.defaults()

local servers = {
  "html",
  "cssls",
  "vtsls",
  "rust_analyzer",
  "pyright",
  "gopls",
  "tailwindcss",
}

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        command = "clippy",
      },
    },
  },
})

vim.lsp.enable(servers)
