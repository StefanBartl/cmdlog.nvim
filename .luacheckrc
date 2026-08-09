-- luacheck configuration for cmdlog.nvim
std = "luajit"
read_globals = { "vim" }

-- Neovim Lua conventions favor readability over a hard line-length cap;
-- don't fail CI on line length alone.
max_line_length = false
