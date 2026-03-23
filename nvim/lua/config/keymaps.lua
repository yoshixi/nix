-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Y in visual mode: yank file path with line range (e.g. ../foo/bar.ts#L10-L14)
vim.keymap.set("v", "Y", function()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local abs_path = vim.fn.expand("%:p")
  local rel_path = vim.fn.fnamemodify(abs_path, ":~:.")
  local result = rel_path .. "#L" .. start_line .. "-L" .. end_line
  vim.fn.setreg("+", result)
  vim.fn.setreg('"', result)
  vim.notify("Copied: " .. result, vim.log.levels.INFO)
end, { desc = "Yank file path with line range" })
