if true then return {} end

-- custom config
return {
  -- Configure LazyVim to load gruvbox
  {
    "neo-tree",
    opts = {
       filesystem = {
        filtered_items = {
            visible = true, -- Set to true to show filtered (hidden/ignored) files
            hide_dotfiles = false, -- Set to false to show dotfiles
            hide_gitignored = false, -- Set to false to show gitignored files
        },
        -- other filesystem options ...
      },
    },
  },
}
