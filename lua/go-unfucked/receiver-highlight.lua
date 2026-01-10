local M = {}

local ns = vim.api.nvim_create_namespace("go_receiver_hl")
local saved_color = nil
local saved_italic = false

local function set_hl()
	vim.api.nvim_set_hl(0, "GoReceiver", {
		fg = saved_color or "#f5a97f",
		italic = saved_italic,
	})
end

function M.highlight_identifier_usages(bufnr, node, name)
	for child in node:iter_children() do
		if child:type() == "identifier" then
			local text = vim.treesitter.get_node_text(child, bufnr)
			if text == name then
				local row, col, _, end_col = child:range()
				vim.api.nvim_buf_add_highlight(bufnr, ns, "GoReceiver", row, col, end_col)
			end
		end
		M.highlight_identifier_usages(bufnr, child, name)
	end
end

function M.highlight_receivers(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	if vim.bo[bufnr].filetype ~= "go" then
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
        (method_declaration
            receiver: (parameter_list
                (parameter_declaration
                    name: (identifier) @recv_name
                    type: (_) @recv_type))
            body: (block) @body) @method
    ]]
	)

	for id, node, _ in query:iter_captures(root, bufnr) do
		local name = query.captures[id]

		if name == "recv_name" then
			local recv_name = vim.treesitter.get_node_text(node, bufnr)
			local row, col, _, end_col = node:range()

			vim.api.nvim_buf_add_highlight(bufnr, ns, "GoReceiver", row, col, end_col)

			local method_node = node:parent():parent():parent()
			local body_node = method_node:field("body")[1]

			if body_node then
				M.highlight_identifier_usages(bufnr, body_node, recv_name)
			end
		end
	end
end

function M.setup(opts)
	opts = opts or {}
	saved_color = opts.color
	saved_italic = opts.italic or false

	set_hl()

	local group = vim.api.nvim_create_augroup("GoReceiverHighlight", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = set_hl,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "InsertLeave" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			vim.defer_fn(function()
				M.highlight_receivers(ev.buf)
			end, 100)
		end,
	})
end

M._internal = {
	set_hl = set_hl,
	get_saved_color = function()
		return saved_color
	end,
	set_saved_color = function(color)
		saved_color = color
	end,
	get_saved_italic = function()
		return saved_italic
	end,
	set_saved_italic = function(italic)
		saved_italic = italic
	end,
	get_namespace = function()
		return ns
	end,
}

return M
