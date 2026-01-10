local M = {}

local ns = vim.api.nvim_create_namespace("go_error_dim")

M.config = {
	enabled = false,
	dim_simple_return = false,
	dim_wrapped_return = false,
}

local function analyze_if_err_block(bufnr, block_node)
	local dominated_statements = 0
	local has_side_effects = false
	local is_wrapped = false

	for i = 0, block_node:named_child_count() - 1 do
		local child = block_node:named_child(i)
		local child_type = child:type()

		if child_type == "return_statement" then
			local return_text = vim.treesitter.get_node_text(child, bufnr)

			if
				return_text:match("fmt%.Errorf")
				or return_text:match("errors%.Wrap")
				or return_text:match("errors%.New")
				or return_text:match("%.Wrapf?%(")
			then
				is_wrapped = true
			end

			dominated_statements = dominated_statements + 1
		else
			has_side_effects = true
			break
		end
	end

	return {
		has_side_effects = has_side_effects,
		is_wrapped = is_wrapped,
		is_simple_return = dominated_statements == 1 and not has_side_effects,
	}
end

local function is_err_nil_check(bufnr, condition_node)
	local text = vim.treesitter.get_node_text(condition_node, bufnr)
	return text:match("err%s*!=%s*nil") or text:match("err%s*==%s*nil")
end

function M.update_dims(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	if not M.config.enabled then
		return
	end
	if vim.bo[bufnr].filetype ~= "go" then
		return
	end

	if not M.config.dim_simple_return and not M.config.dim_wrapped_return then
		return
	end

	local parser = vim.treesitter.get_parser(bufnr, "go")
	if not parser then
		return
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"go",
		[[
        (if_statement
            condition: (_) @condition
            consequence: (block) @block)
    ]]
	)

	local dim_hl = "GoDimmedError"

	for id, node, _ in query:iter_captures(root, bufnr) do
		local name = query.captures[id]

		if name == "condition" then
			if is_err_nil_check(bufnr, node) then
				local if_node = node:parent()
				local block_node = if_node:field("consequence")[1]

				if block_node then
					local analysis = analyze_if_err_block(bufnr, block_node)

					local should_dim = false

					if analysis.has_side_effects then
						should_dim = false
					elseif analysis.is_wrapped and M.config.dim_wrapped_return then
						should_dim = true
					elseif analysis.is_simple_return and not analysis.is_wrapped and M.config.dim_simple_return then
						should_dim = true
					end

					if should_dim then
						local start_row, _, end_row, _ = if_node:range()

						for row = start_row, end_row do
							vim.api.nvim_buf_add_highlight(bufnr, ns, dim_hl, row, 0, -1)
						end
					end
				end
			end
		end
	end
end

function M.setup(opts)
	opts = opts or {}

	M.config = vim.tbl_deep_extend("force", M.config, opts)

	vim.api.nvim_set_hl(0, "GoDimmedError", {
		fg = opts.dim_color or "#666666",
		blend = opts.dim_blend or 50,
	})

	local group = vim.api.nvim_create_augroup("GoErrorDim", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			vim.defer_fn(function()
				M.update_dims(ev.buf)
			end, 200)
		end,
	})

	vim.api.nvim_create_user_command("GoErrorDimToggle", function()
		M.config.enabled = not M.config.enabled
		M.update_dims()
		print("Go error dim: " .. (M.config.enabled and "enabled" or "disabled"))
	end, {})

	vim.api.nvim_create_user_command("GoErrorDimStatus", function()
		print(string.format(
			"Go error dim: %s | simple_return: %s | wrapped_return: %s",
			M.config.enabled and "ON" or "OFF",
			M.config.dim_simple_return and "dim" or "normal",
			M.config.dim_wrapped_return and "dim" or "normal"
		))
	end, {})
end

return M
