package.path = package.path .. ";./tests/deps/nvim-test-core/lua/?.lua"
package.path = package.path .. ";./tests/deps/nvim-test-core/lua/?/init.lua"
package.path = package.path .. ";./lua/?.lua"
package.path = package.path .. ";./lua/?/init.lua"

require("nvim-test-core")

-- Load mock functions into real vim when running in Neovim
local mock = require("nvim-test-core.vim_mock")
vim._mock = mock._mock
vim._buffers = mock._buffers
vim._windows = mock._windows
vim._win_tab = mock._win_tab
vim._tab_windows = mock._tab_windows
vim._commands = mock._commands
vim._autocmds = mock._autocmds
vim._vars = mock._vars
vim._options = mock._options
vim._namespaces = mock._namespaces
vim._augroups = mock._augroups
vim._augroup_names = mock._augroup_names
vim._extmarks = mock._extmarks
vim._highlights = mock._highlights
vim._hl_groups = mock._hl_groups
vim._diagnostics = mock._diagnostics
vim._executables = mock._executables
vim._readable_files = mock._readable_files
vim._jobs = mock._jobs

-- Initialize default state
vim._mock.reset()
vim._mock.add_buffer(1, "/home/user/project/test.go", "package main", { filetype = "go" })
vim._mock.add_window(1000, 1, { 1, 0 })

require("go-unfucked")
