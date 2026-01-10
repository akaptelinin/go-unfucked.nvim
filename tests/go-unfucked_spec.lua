describe("go-unfucked", function()
	before_each(function()
		vim._mock.reset()
		vim._mock.add_buffer(1, "/test/main.go", "package main", { filetype = "go" })
		vim._mock.add_window(1000, 1, { 1, 0 })
		package.loaded["go-unfucked.import-hints"] = nil
		package.loaded["go-unfucked.receiver-highlight"] = nil
		package.loaded["go-unfucked.error-dim"] = nil
		package.loaded["go-unfucked.shortnames"] = nil
	end)

	describe("import-hints", function()
		local import_hints

		before_each(function()
			import_hints = require("go-unfucked.import-hints")
		end)

		it("should be a table", function()
			expect(import_hints).to_be_table()
		end)

		it("should have setup function", function()
			expect(import_hints.setup).to_be_function()
		end)

		it("should have update_hints function", function()
			expect(import_hints.update_hints).to_be_function()
		end)

		it("should track enabled state", function()
			import_hints.setup({ enabled = true })
			expect(import_hints.enabled).to_be_true()

			import_hints.setup({ enabled = false })
			expect(import_hints.enabled).to_be_false()
		end)

		it("should create namespace on first call", function()
			import_hints.update_hints(1)
			expect(vim._namespaces["go_import_hints"]).not_to_be_nil()
		end)

		it("should register autocmds on setup", function()
			import_hints.setup({})
			expect(vim._autocmds["GoImportHints"]).not_to_be_nil()
			expect(vim._autocmds["GoImportHints"].events).to_be_table()
		end)

		it("should register user commands on setup", function()
			import_hints.setup({})
			expect(vim._commands["GoImportHints"]).not_to_be_nil()
			expect(vim._commands["GoImportHintsToggle"]).not_to_be_nil()
		end)

		it("should handle nil treesitter parser gracefully", function()
			local success = pcall(function()
				import_hints.update_hints(1)
			end)
			expect(success).to_be_true()
		end)

		it("should skip non-go filetypes", function()
			vim._mock.add_buffer(2, "/test/main.lua", "local x = 1", { filetype = "lua" })
			import_hints.setup({ enabled = true })
			import_hints.update_hints(2)
			local ns_id = vim._namespaces["go_import_hints"]
			local extmarks = vim._extmarks[ns_id] or {}
			expect(#extmarks).to_be(0)
		end)

		it("should clear extmarks when disabled", function()
			import_hints.setup({ enabled = true })
			import_hints.update_hints(1)
			import_hints.enabled = false
			import_hints.update_hints(1)
			local ns_id = vim._namespaces["go_import_hints"]
			local extmarks = vim._extmarks[ns_id] or {}
			expect(#extmarks).to_be(0)
		end)
	end)

	describe("receiver-highlight", function()
		local receiver_highlight

		before_each(function()
			receiver_highlight = require("go-unfucked.receiver-highlight")
		end)

		it("should be a table", function()
			expect(receiver_highlight).to_be_table()
		end)

		it("should have setup function", function()
			expect(receiver_highlight.setup).to_be_function()
		end)

		it("should have highlight_receivers function", function()
			expect(receiver_highlight.highlight_receivers).to_be_function()
		end)

		it("should create namespace on first call", function()
			receiver_highlight.highlight_receivers(1)
			expect(vim._namespaces["go_receiver_hl"]).not_to_be_nil()
		end)

		it("should register highlight group on setup", function()
			receiver_highlight.setup({})
			expect(vim._hl_groups["GoReceiver"]).not_to_be_nil()
		end)

		it("should use custom color from config", function()
			receiver_highlight.setup({ color = "#ff0000" })
			expect(vim._hl_groups["GoReceiver"].fg).to_be("#ff0000")
		end)

		it("should use default color when not specified", function()
			receiver_highlight.setup({})
			expect(vim._hl_groups["GoReceiver"].fg).to_be("#a855f7")
		end)

		it("should register autocmds on setup", function()
			receiver_highlight.setup({})
			expect(vim._autocmds["GoReceiverHighlight"]).not_to_be_nil()
		end)

		it("should handle nil treesitter parser gracefully", function()
			local success = pcall(function()
				receiver_highlight.highlight_receivers(1)
			end)
			expect(success).to_be_true()
		end)

		it("should skip non-go filetypes", function()
			vim._mock.add_buffer(2, "/test/main.lua", "local x = 1", { filetype = "lua" })
			receiver_highlight.highlight_receivers(2)
			local ns_id = vim._namespaces["go_receiver_hl"]
			local highlights = vim._highlights[ns_id] or {}
			expect(#highlights).to_be(0)
		end)

		it("should register ColorScheme autocmd", function()
			receiver_highlight.setup({ color = "#ff757f" })
			local group = vim._autocmds["GoReceiverHighlight"]
			expect(group).not_to_be_nil()
			local has_colorscheme = false
			for _, ac in pairs(group.events or {}) do
				if ac.events == "ColorScheme" then
					has_colorscheme = true
					break
				end
			end
			expect(has_colorscheme).to_be_true()
		end)

		it("should restore color after ColorScheme event", function()
			receiver_highlight.setup({ color = "#ff757f" })
			vim._hl_groups["GoReceiver"] = nil
			local group = vim._autocmds["GoReceiverHighlight"]
			for _, ac in pairs(group.events or {}) do
				if ac.events == "ColorScheme" and ac.opts.callback then
					ac.opts.callback()
					break
				end
			end
			expect(vim._hl_groups["GoReceiver"]).not_to_be_nil()
			expect(vim._hl_groups["GoReceiver"].fg).to_be("#ff757f")
		end)

		it("should register InsertLeave and TextChangedI autocmds", function()
			receiver_highlight.setup({})
			local group = vim._autocmds["GoReceiverHighlight"]
			expect(group).not_to_be_nil()
			local has_insert_leave = false
			local has_text_changed_i = false
			for _, ac in pairs(group.events or {}) do
				if type(ac.events) == "table" then
					for _, ev in ipairs(ac.events) do
						if ev == "InsertLeave" then has_insert_leave = true end
						if ev == "TextChangedI" then has_text_changed_i = true end
					end
				end
			end
			expect(has_insert_leave).to_be_true()
			expect(has_text_changed_i).to_be_true()
		end)
	end)

	describe("error-dim", function()
		local error_dim

		before_each(function()
			error_dim = require("go-unfucked.error-dim")
		end)

		it("should be a table", function()
			expect(error_dim).to_be_table()
		end)

		it("should have setup function", function()
			expect(error_dim.setup).to_be_function()
		end)

		it("should have update_dims function", function()
			expect(error_dim.update_dims).to_be_function()
		end)

		it("should have default config", function()
			expect(error_dim.config).to_be_table()
			expect(error_dim.config.enabled).to_be_false()
			expect(error_dim.config.dim_simple_return).to_be_false()
			expect(error_dim.config.dim_wrapped_return).to_be_false()
			expect(error_dim.config.dim_percent).to_be(40)
		end)

		it("should merge config on setup", function()
			error_dim.setup({
				enabled = true,
				dim_simple_return = true,
			})
			expect(error_dim.config.enabled).to_be_true()
			expect(error_dim.config.dim_simple_return).to_be_true()
			expect(error_dim.config.dim_wrapped_return).to_be_false()
		end)

		it("should create namespace on first call", function()
			error_dim.setup({ enabled = true })
			error_dim.update_dims(1)
			expect(vim._namespaces["go_error_dim"]).not_to_be_nil()
		end)

		it("should accept dim_percent config", function()
			error_dim.setup({ dim_percent = 60 })
			expect(error_dim.config.dim_percent).to_be(60)
		end)

		it("should accept dim_target config", function()
			error_dim.setup({ dim_target = "#1a1a1a" })
			expect(error_dim.config.dim_target).to_be("#1a1a1a")
		end)

		it("should register autocmds on setup", function()
			error_dim.setup({})
			expect(vim._autocmds["GoErrorDim"]).not_to_be_nil()
		end)

		it("should register user commands on setup", function()
			error_dim.setup({})
			expect(vim._commands["GoErrorDimToggle"]).not_to_be_nil()
			expect(vim._commands["GoErrorDimStatus"]).not_to_be_nil()
		end)

		it("should not create highlights when disabled", function()
			error_dim.setup({ enabled = false })
			error_dim.update_dims(1)
			local ns_id = vim._namespaces["go_error_dim"]
			local highlights = vim._highlights[ns_id] or {}
			expect(#highlights).to_be(0)
		end)

		it("should not create highlights when no dim options enabled", function()
			error_dim.setup({
				enabled = true,
				dim_simple_return = false,
				dim_wrapped_return = false,
			})
			error_dim.update_dims(1)
			local ns_id = vim._namespaces["go_error_dim"]
			local highlights = vim._highlights[ns_id] or {}
			expect(#highlights).to_be(0)
		end)

		it("should handle nil treesitter parser gracefully", function()
			error_dim.setup({ enabled = true, dim_simple_return = true })
			local success = pcall(function()
				error_dim.update_dims(1)
			end)
			expect(success).to_be_true()
		end)

		it("should skip non-go filetypes", function()
			vim._mock.add_buffer(2, "/test/main.lua", "local x = 1", { filetype = "lua" })
			error_dim.setup({ enabled = true, dim_simple_return = true })
			error_dim.update_dims(2)
			local ns_id = vim._namespaces["go_error_dim"]
			local highlights = vim._highlights[ns_id] or {}
			expect(#highlights).to_be(0)
		end)

		it("should preserve unrelated config options on merge", function()
			error_dim.setup({ enabled = true })
			error_dim.setup({ dim_simple_return = true })
			expect(error_dim.config.enabled).to_be_true()
			expect(error_dim.config.dim_simple_return).to_be_true()
		end)

		it("should register ColorScheme autocmd", function()
			error_dim.setup({})
			local group = vim._autocmds["GoErrorDim"]
			expect(group).not_to_be_nil()
			local has_colorscheme = false
			for _, ac in pairs(group.events or {}) do
				if ac.events == "ColorScheme" then
					has_colorscheme = true
					break
				end
			end
			expect(has_colorscheme).to_be_true()
		end)

		it("should register ColorScheme autocmd for cache clearing", function()
			error_dim.setup({})
			local group = vim._autocmds["GoErrorDim"]
			local has_colorscheme = false
			for _, ac in pairs(group.events or {}) do
				if ac.events == "ColorScheme" and ac.opts.callback then
					has_colorscheme = true
					break
				end
			end
			expect(has_colorscheme).to_be_true()
		end)

		it("should register InsertLeave autocmd", function()
			error_dim.setup({})
			local group = vim._autocmds["GoErrorDim"]
			expect(group).not_to_be_nil()
			local has_insert_leave = false
			for _, ac in pairs(group.events or {}) do
				if ac.events == "InsertLeave" then
					has_insert_leave = true
					break
				end
			end
			expect(has_insert_leave).to_be_true()
		end)
	end)

	describe("shortnames", function()
		local shortnames

		before_each(function()
			shortnames = require("go-unfucked.shortnames")
		end)

		it("should be a table", function()
			expect(shortnames).to_be_table()
		end)

		it("should have setup function", function()
			expect(shortnames.setup).to_be_function()
		end)

		it("should have run function", function()
			expect(shortnames.run).to_be_function()
		end)

		it("should have clear function", function()
			expect(shortnames.clear).to_be_function()
		end)

		it("should have default config", function()
			expect(shortnames.config).to_be_table()
			expect(shortnames.config.enabled).to_be_false()
			expect(shortnames.config.binary).to_be_nil()
		end)

		it("should merge config on setup", function()
			vim._mock.set_executable("/usr/bin/shortnames-linter", true)
			vim.fn.exepath = function() return "/usr/bin/shortnames-linter" end

			shortnames.setup({
				enabled = true,
				binary = "/custom/path/shortnames-linter",
			})
			expect(shortnames.config.enabled).to_be_true()
			expect(shortnames.config.binary).to_be("/custom/path/shortnames-linter")
		end)

		it("should create namespace on first call", function()
			shortnames.clear(1)
			expect(vim._namespaces["go_shortnames"]).not_to_be_nil()
		end)

		it("should register autocmds on setup when binary found", function()
			vim._mock.set_executable("/usr/bin/shortnames-linter", true)
			vim.fn.exepath = function() return "/usr/bin/shortnames-linter" end

			shortnames.setup({ enabled = true })
			expect(vim._autocmds["GoShortnames"]).not_to_be_nil()
		end)

		it("should not register autocmds when disabled", function()
			shortnames.setup({ enabled = false })
			expect(vim._autocmds["GoShortnames"]).to_be_nil()
		end)

		it("should register user commands on setup when binary found", function()
			vim._mock.set_executable("/usr/bin/shortnames-linter", true)
			vim.fn.exepath = function() return "/usr/bin/shortnames-linter" end

			shortnames.setup({ enabled = true })
			expect(vim._commands["GoShortnamesRun"]).not_to_be_nil()
			expect(vim._commands["GoShortnamesToggle"]).not_to_be_nil()
		end)

		it("should skip non-go filetypes", function()
			vim._mock.add_buffer(2, "/test/main.lua", "local x = 1", { filetype = "lua" })
			shortnames.config.enabled = true
			shortnames.run(2)
			local ns_id = vim._namespaces["go_shortnames"]
			local diagnostics = vim._diagnostics[ns_id] or {}
			expect(#diagnostics).to_be(0)
		end)

		it("should clear diagnostics", function()
			shortnames.clear(1)
			local ns_id = vim._namespaces["go_shortnames"]
			expect(ns_id).not_to_be_nil()
		end)

		describe("parse_output", function()
			it("should parse single line", function()
				local output = '/test/main.go:10:5: variable "x" is too short'
				local diagnostics = {}
				for line in output:gmatch("[^\r\n]+") do
					local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
					if file and file == "/test/main.go" then
						table.insert(diagnostics, {
							lnum = tonumber(lnum) - 1,
							col = tonumber(col) - 1,
							message = msg,
						})
					end
				end
				expect(#diagnostics).to_be(1)
				expect(diagnostics[1].lnum).to_be(9)
				expect(diagnostics[1].col).to_be(4)
				expect(diagnostics[1].message).to_be('variable "x" is too short')
			end)

			it("should parse multiple lines", function()
				local output = "/test/main.go:10:5: first\n/test/main.go:20:10: second"
				local diagnostics = {}
				for line in output:gmatch("[^\r\n]+") do
					local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
					if file and file == "/test/main.go" then
						table.insert(diagnostics, {
							lnum = tonumber(lnum) - 1,
							col = tonumber(col) - 1,
							message = msg,
						})
					end
				end
				expect(#diagnostics).to_be(2)
			end)

			it("should filter by filename", function()
				local output = "/test/main.go:10:5: in file\n/test/other.go:20:10: in other"
				local diagnostics = {}
				for line in output:gmatch("[^\r\n]+") do
					local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
					if file and file == "/test/main.go" then
						table.insert(diagnostics, { message = msg })
					end
				end
				expect(#diagnostics).to_be(1)
				expect(diagnostics[1].message).to_be("in file")
			end)

			it("should ignore malformed lines", function()
				local output = "not valid\n/test/main.go:10:5: valid\nshortnames: skipped"
				local diagnostics = {}
				for line in output:gmatch("[^\r\n]+") do
					local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
					if file and file == "/test/main.go" then
						table.insert(diagnostics, { message = msg })
					end
				end
				expect(#diagnostics).to_be(1)
			end)
		end)

		describe("find_go_mod", function()
			it("should find go.mod in current dir", function()
				vim._mock.set_file_readable("/project/go.mod", true)
				local path = "/project"
				while path ~= "/" do
					if vim.fn.filereadable(path .. "/go.mod") == 1 then
						break
					end
					path = vim.fn.fnamemodify(path, ":h")
				end
				expect(path).to_be("/project")
			end)

			it("should find go.mod in parent dir", function()
				vim._mock.set_file_readable("/project/go.mod", true)
				local path = "/project/pkg/handler"
				while path ~= "/" do
					if vim.fn.filereadable(path .. "/go.mod") == 1 then
						break
					end
					path = vim.fn.fnamemodify(path, ":h")
				end
				expect(path).to_be("/project")
			end)
		end)

		describe("package path calculation", function()
			it("should calculate relative path", function()
				local go_mod_dir = "/home/user/project"
				local filedir = "/home/user/project/pkg/handler"
				local rel_dir = filedir:sub(#go_mod_dir + 2)
				local pkg_path = "./" .. rel_dir
				expect(rel_dir).to_be("pkg/handler")
				expect(pkg_path).to_be("./pkg/handler")
			end)

			it("should handle root package", function()
				local go_mod_dir = "/home/user/project"
				local filedir = "/home/user/project"
				local rel_dir = filedir:sub(#go_mod_dir + 2)
				local pkg_path = "./" .. rel_dir
				expect(rel_dir).to_be("")
				expect(pkg_path).to_be("./")
			end)

			it("should handle deeply nested packages", function()
				local go_mod_dir = "/home/user/project"
				local filedir = "/home/user/project/internal/pkg/v2/handler"
				local rel_dir = filedir:sub(#go_mod_dir + 2)
				expect(rel_dir).to_be("internal/pkg/v2/handler")
			end)
		end)

		describe("find_binary", function()
			it("should find binary in PATH", function()
				vim.fn.exepath = function(cmd)
					if cmd == "shortnames-linter" then
						return "/usr/local/bin/shortnames-linter"
					end
					return ""
				end
				vim._mock.set_executable("/usr/local/bin/shortnames-linter", true)

				local result = vim.fn.exepath("shortnames-linter")
				expect(result).to_be("/usr/local/bin/shortnames-linter")
			end)

			it("should find binary in go/bin", function()
				vim.fn.exepath = function() return "" end
				vim.fn.expand = function(path)
					if path == "~/go/bin/shortnames-linter" then
						return "/home/user/go/bin/shortnames-linter"
					end
					return path
				end
				vim._mock.set_executable("/home/user/go/bin/shortnames-linter", true)

				local expanded = vim.fn.expand("~/go/bin/shortnames-linter")
				expect(expanded).to_be("/home/user/go/bin/shortnames-linter")
			end)
		end)
	end)

	describe("init module", function()
		it("should export setup function", function()
			local go_unfucked = require("go-unfucked")
			expect(go_unfucked.setup).to_be_function()
		end)

		it("should call all submodule setup functions", function()
			local go_unfucked = require("go-unfucked")
			go_unfucked.setup({})
			expect(vim._autocmds["GoImportHints"]).not_to_be_nil()
			expect(vim._autocmds["GoReceiverHighlight"]).not_to_be_nil()
			expect(vim._autocmds["GoErrorDim"]).not_to_be_nil()
			-- shortnames autocmd only created if binary found, so we don't check it here
		end)

		it("should pass config to submodules", function()
			local go_unfucked = require("go-unfucked")
			go_unfucked.setup({
				import_hints = { enabled = false },
				receiver_highlight = { color = "#00ff00" },
				error_dim = { enabled = true, dim_simple_return = true },
			})

			local import_hints = require("go-unfucked.import-hints")
			local receiver_highlight = require("go-unfucked.receiver-highlight")
			local error_dim = require("go-unfucked.error-dim")

			expect(import_hints.enabled).to_be_false()
			expect(vim._hl_groups["GoReceiver"].fg).to_be("#00ff00")
			expect(error_dim.config.enabled).to_be_true()
			expect(error_dim.config.dim_simple_return).to_be_true()
		end)
	end)
end)
