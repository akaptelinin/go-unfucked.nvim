local M = {}

local ns = vim.api.nvim_create_namespace("go_import_hints")
M.enabled = true

local function get_imports(bufnr)
	local imports = {}
	local parser = vim.treesitter.get_parser(bufnr, "go")
	if not parser then
		return imports
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"go",
		[[
        (import_declaration
            (import_spec
                name: (package_identifier)? @alias
                path: (interpreted_string_literal) @path)) @import
        (import_declaration
            (import_spec_list
                (import_spec
                    name: (package_identifier)? @alias
                    path: (interpreted_string_literal) @path))) @import
    ]]
	)

	for id, node, _ in query:iter_captures(root, bufnr) do
		local name = query.captures[id]
		if name == "path" then
			local path = vim.treesitter.get_node_text(node, bufnr)
			path = path:gsub('"', "")

			local row, col = node:range()
			local pkg_name = path:match("([^/]+)$")

			local parent = node:parent()
			local alias_node = parent and parent:field("name")[1]
			local alias = alias_node and vim.treesitter.get_node_text(alias_node, bufnr) or pkg_name

			table.insert(imports, {
				path = path,
				alias = alias,
				pkg_name = pkg_name,
				line = row,
				col = col,
			})
		end
	end

	return imports
end

local function find_package_usages(bufnr, pkg_alias)
	local usages = {}
	local seen = {}

	local parser = vim.treesitter.get_parser(bufnr, "go")
	if not parser then
		return usages
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"go",
		[[
        (selector_expression
            operand: (identifier) @pkg
            field: (field_identifier) @field)
    ]]
	)

	for id, node, _ in query:iter_captures(root, bufnr) do
		local name = query.captures[id]
		if name == "pkg" then
			local pkg = vim.treesitter.get_node_text(node, bufnr)
			if pkg == pkg_alias then
				local parent = node:parent()
				local field_node = parent:field("field")[1]
				if field_node then
					local symbol = vim.treesitter.get_node_text(field_node, bufnr)
					if not seen[symbol] then
						seen[symbol] = true
						table.insert(usages, symbol)
					end
				end
			end
		end
	end

	table.sort(usages)
	return usages
end

function M.update_hints(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	if not M.enabled then
		return
	end
	if vim.bo[bufnr].filetype ~= "go" then
		return
	end

	local imports = get_imports(bufnr)

	for _, imp in ipairs(imports) do
		local usages = find_package_usages(bufnr, imp.alias)

		if #usages > 0 then
			local hint_text = "→ " .. table.concat(usages, ", ")

			if #hint_text > 60 then
				hint_text = hint_text:sub(1, 57) .. "..."
			end

			vim.api.nvim_buf_set_extmark(bufnr, ns, imp.line, 0, {
				virt_text = { { hint_text, "Comment" } },
				virt_text_pos = "eol",
			})
		else
			vim.api.nvim_buf_set_extmark(bufnr, ns, imp.line, 0, {
				virt_text = { { "→ unused", "DiagnosticWarn" } },
				virt_text_pos = "eol",
			})
		end
	end
end

function M.setup(opts)
	opts = opts or {}
	M.enabled = opts.enabled ~= false

	local group = vim.api.nvim_create_augroup("GoImportHints", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			vim.defer_fn(function()
				M.update_hints(ev.buf)
			end, 100)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			vim.defer_fn(function()
				M.update_hints(ev.buf)
			end, 500)
		end,
	})

	vim.api.nvim_create_user_command("GoImportHints", function()
		M.update_hints()
	end, {})

	vim.api.nvim_create_user_command("GoImportHintsToggle", function()
		M.enabled = not M.enabled
		if M.enabled then
			M.update_hints()
		else
			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
		end
		print("Go import hints: " .. (M.enabled and "enabled" or "disabled"))
	end, {})
end

M._internal = {
	get_imports = get_imports,
	find_package_usages = find_package_usages,
	get_namespace = function()
		return ns
	end,
}

return M
