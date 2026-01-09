describe("go-unfucked", function()
	before_each(function()
		vim._mock.reset()
		vim._mock.add_buffer(1, "/test/main.go", "package main", { filetype = "go" })
		vim._mock.add_window(1000, 1, { 1, 0 })
		package.loaded["go-unfucked.import-hints"] = nil
		package.loaded["go-unfucked.receiver-highlight"] = nil
		package.loaded["go-unfucked.error-dim"] = nil
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
			expect(vim._hl_groups["GoReceiver"].fg).to_be("#ff9900")
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

		it("should register highlight group on setup", function()
			error_dim.setup({})
			expect(vim._hl_groups["GoDimmedError"]).not_to_be_nil()
		end)

		it("should use custom dim color from config", function()
			error_dim.setup({ dim_color = "#333333" })
			expect(vim._hl_groups["GoDimmedError"].fg).to_be("#333333")
		end)

		it("should use default dim color when not specified", function()
			error_dim.setup({})
			expect(vim._hl_groups["GoDimmedError"].fg).to_be("#666666")
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
