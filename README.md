# Neovim config

My personal Neovim setup, based on [NvChad](https://nvchad.com/).

## Highlights

- Gruvchad theme
- LSP support for web development, Python, Rust, and Go
- Format-on-save with Conform
- Private inline code completion powered by a local Ollama model
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

## Local AI completion

Inline completion runs entirely through Ollama on `127.0.0.1`; no code is sent
to a cloud service. Install and start the configured model before opening
Neovim:

```sh
ollama run qwen2.5-coder:0.5b-base-q4_K_M
```

As you type, a suggested continuation appears as dimmed ghost text. The engine
uses Ollama's fill-in-the-middle support, so it considers code on both sides of
the cursor. It works in regular code buffers, including Go, JavaScript,
TypeScript, React, HTML, CSS, Tailwind-heavy markup, Lua, Python, and Rust.

- `Tab`: accept the visible local suggestion. When none is visible, it keeps its
  normal completion-menu, snippet, and indentation behavior.
- `:OllamaComplete`: request a suggestion immediately
- `:OllamaStopProject`: stop suggestions for every buffer in the current project
  for this Neovim session. They are enabled again after restarting Neovim.
- `:OllamaStatus`: show the current model and status

Save shortcuts on macOS:

- `Cmd-n`: prompt for a path and open a new file buffer in the current project
- `Cmd-s`: save the current buffer
- `Cmd-Shift-s`: save all modified buffers

Environment files, key files, credential/secret-named files, special buffers,
and files larger than 1 MiB are excluded automatically.

## Credits

Built from the [NvChad starter](https://github.com/NvChad/starter).
