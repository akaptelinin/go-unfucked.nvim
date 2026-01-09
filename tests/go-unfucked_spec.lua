local import_hints = require("go-unfucked.import-hints")
local receiver_highlight = require("go-unfucked.receiver-highlight")
local error_dim = require("go-unfucked.error-dim")

describe("go-unfucked", function()
	describe("import-hints", function()
		it("should be a table", function()
			assert.is_table(import_hints)
		end)

		it("should have setup function", function()
			assert.is_function(import_hints.setup)
		end)

		it("should have update_hints function", function()
			assert.is_function(import_hints.update_hints)
		end)

		it("should track enabled state", function()
			import_hints.setup({ enabled = true })
			assert.is_true(import_hints.enabled)

			import_hints.setup({ enabled = false })
			assert.is_false(import_hints.enabled)
		end)
	end)

	describe("receiver-highlight", function()
		it("should be a table", function()
			assert.is_table(receiver_highlight)
		end)

		it("should have setup function", function()
			assert.is_function(receiver_highlight.setup)
		end)

		it("should have highlight_receivers function", function()
			assert.is_function(receiver_highlight.highlight_receivers)
		end)
	end)

	describe("error-dim", function()
		it("should be a table", function()
			assert.is_table(error_dim)
		end)

		it("should have setup function", function()
			assert.is_function(error_dim.setup)
		end)

		it("should have update_dims function", function()
			assert.is_function(error_dim.update_dims)
		end)

		it("should have default config", function()
			assert.is_table(error_dim.config)
			assert.is_false(error_dim.config.enabled)
			assert.is_false(error_dim.config.dim_simple_return)
			assert.is_false(error_dim.config.dim_wrapped_return)
		end)

		it("should merge config on setup", function()
			error_dim.setup({
				enabled = true,
				dim_simple_return = true,
			})
			assert.is_true(error_dim.config.enabled)
			assert.is_true(error_dim.config.dim_simple_return)
			assert.is_false(error_dim.config.dim_wrapped_return)
		end)
	end)
end)
