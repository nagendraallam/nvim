return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {
      PATH = "prepend",
    },
  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"

      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if require("local_completion").accept() then
          return
        end

        if cmp.visible() then
          cmp.select_next_item()
        elseif require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" })

      return opts
    end,
  },
}
