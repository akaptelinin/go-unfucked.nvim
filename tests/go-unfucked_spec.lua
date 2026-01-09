require("nvim-test-core")

describe("go-unfucked", function()
	before_each(function()
		vim._mock.reset()
		vim._mock.add_buffer(1, "/test/main.go", "package main")
		vim._mock.add_window(1000, 1, { 1, 0 })
	end)

	describe("import-hints", function()
		local import_hints = require("go-unfucked.import-hints")

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
	end)

	describe("receiver-highlight", function()
		local receiver_highlight = require("go-unfucked.receiver-highlight")

		it("should be a table", function()
			expect(receiver_highlight).to_be_table()
		end)

		it("should have setup function", function()
			expect(receiver_highlight.setup).to_be_function()
		end)

		it("should have highlight_receivers function", function()
			expect(receiver_highlight.highlight_receivers).to_be_function()
		end)
	end)

	describe("error-dim", function()
		local error_dim = require("go-unfucked.error-dim")

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
	end)
end)
