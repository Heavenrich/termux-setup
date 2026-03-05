#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starting the Ultimate 'No-Errors' Termux Setup..."

termux-change-repo  # You'll have to pick the mirror once, or just let the script run.

# 1. System Update & Base Packages (Forced Non-Interactive)
export DEBIAN_FRONTEND=noninteractive
pkg update -y
pkg upgrade -y -o Dpkg::Options::="--force-confold"

pkg install python nodejs-lts neovim git gh curl wget zsh build-essential lsd ripgrep fd fastfetch rust -y

# 2. Build Tree-sitter CLI from Source (The only way for v0.26+ on Termux)
echo "🦀 Installing Tree-sitter CLI via Cargo (this may take a few mins)..."
cargo install tree-sitter-cli
export PATH="$HOME/.cargo/bin:$PATH"

# 3. Setup Nerd Font & Termux Styling
echo "🎨 Applying Visual Themes..."
mkdir -p ~/.termux
curl -fLo ~/.termux/font.ttf https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf

cat <<EOF > ~/.termux/colors.properties
background: #1e1e2e
foreground: #cdd6f4
cursor: #f5e0dc
color0: #45475a
color1: #f38ba8
color2: #a6e22e
color3: #f9e2af
color4: #89b4fa
color5: #f5c2e7
color6: #94e2d5
color7: #bac2de
EOF
termux-reload-settings

# 4. Oh-My-Zsh & Customizations
echo "🐚 Configuring Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Persistent Path and Visuals
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
echo "alias ls='lsd'" >> ~/.zshrc
echo "alias vi='nvim'" >> ~/.zshrc
echo "fastfetch" >> ~/.zshrc
echo "prompt_context() {} # This hides the 'u0_a331@localhost' part" >> ~/.zshrc

# 5. The Master init.lua (V1.0+ Compatible)
echo "📝 Writing Neovim Configuration..."
mkdir -p ~/.config/nvim

cat <<EOF > ~/.config/nvim/init.lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Base Settings
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true

require("lazy").setup({
  -- UI & Appearance
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  { "NvChad/nvim-colorizer.lua", opts = {} },
  { "goolord/alpha-nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require'alpha'.setup(require'alpha.themes.startify'.config) end },

  -- Navigation
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Treesitter (V1.0+ Structure)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "python", "javascript", "typescript", "html", "css", "lua" },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- LSP & Autocomplete
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp" } },
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
}, {
  rocks = { enabled = false }, -- Fixes the Luarocks error in Termux
})

-- UI Setup
vim.cmd.colorscheme("catppuccin")
require('lualine').setup()

-- Modern LSP Setup (Fixes Deprecation Warning)
require("mason").setup()
local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "ts_ls", "html", "cssls" },
  handlers = {
    function(server_name)
      require("lspconfig")[server_name].setup({
        capabilities = capabilities,
      })
    end,
  },
})

-- Keybindings
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
EOF

#6. git config
git config --global init.defaultBranch main

echo "✅ Setup Complete! Restart Termux and run 'nvim' to finish installation."
chsh -s zsh
