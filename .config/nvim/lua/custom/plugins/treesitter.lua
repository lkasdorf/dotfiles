-- return {
  -- {
    -- "nvim-treesitter/nvim-treesitter",
    -- build = ":TSUpdate",
    -- config = function()
      -- require("nvim-treesitter.configs").setup({
        -- highlight = { enable = true },
        -- indent = { enable = true },

        -- -- optional: nimm ein paar Sprachen direkt mit
        -- ensure_installed = {
          -- "lua", "vim", "vimdoc",
          -- "bash", "json", "yaml", "toml",
          -- "markdown", "markdown_inline",
          -- "python", "javascript", "typescript", "html", "css",
        -- },
        -- auto_install = true,
      -- })
    -- end,
  -- },
-- }
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("nvim-treesitter.configs not found (plugin not loaded yet)", vim.log.levels.WARN)
        return
      end

      configs.setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "bash", "json", "yaml", "toml",
          "markdown", "markdown_inline",
          "python", "javascript", "typescript", "html", "css",
        },
        highlight = { enable = true },
        indent = { enable = true },
        auto_install = true,
      })
    end,
  },

  -- only if you use textobjects in your treesitter config
  { "nvim-treesitter/nvim-treesitter-textobjects" },
}

