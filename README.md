# Neovim config

My personal Neovim setup, based on [NvChad](https://nvchad.com/).

## Highlights

- Gruvchad theme
- LSP support for web development, Python, Rust, and Go
- Format-on-save with Conform
- GitHub Copilot
- macOS-friendly save, diagnostics, and window mappings

## Install

Back up any existing Neovim config, then clone this repository:

```sh
git clone https://github.com/nagendraallam/nvim.git ~/.config/nvim
nvim
```

Plugins install automatically on first launch. Install the configured language
servers and formatters with `:Mason` as needed. The current setup expects:

- Language servers: `html-lsp`, `css-lsp`, `vtsls`, `rust-analyzer`, `pyright`,
  `gopls`, and `tailwindcss-language-server`
- Formatters: `stylua`, `ruff`, and `prettier`

The plugin lockfile is committed so installs remain reproducible.

## Credits

Built from the [NvChad starter](https://github.com/NvChad/starter).
