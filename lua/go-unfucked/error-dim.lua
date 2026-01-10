local M = {}

local ns = vim.api.nvim_create_namespace("go_error_dim")

M.config = {
	enabled = false,
	dim_simple_return = false,
	dim_wrapped_return = false,
	dim_percent = 40,
	dim_target = nil,
}

local dimmed_groups = {}
local target_color = nil

local function get_bg_color()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
	if normal.bg then
		return string.format("#%06x", normal.bg)
	end
	return "#000000"
end

local function blend_colors(fg_hex, bg_hex, percent)
	local function hex_to_rgb(hex)
		hex = hex:gsub("#", "")
		return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	end

	local fr, fg, fb = hex_to_rgb(fg_hex)
	local br, bg_val, bb = hex_to_rgb(bg_hex)

	local t = percent / 100
	local nr = math.floor(fr * (1 - t) + br * t)
	local ng = math.floor(fg * (1 - t) + bg_val * t)
	local nb = math.floor(fb * (1 - t) + bb * t)

	return string.format(
		"#%02x%02x%02x",
		math.max(0, math.min(255, nr)),
		math.max(0, math.min(255, ng)),
		math.max(0, math.min(255, nb))
	)
end

local function get_dimmed_group(original_group)
	if dimmed_groups[original_group] then
		return dimmed_groups[original_group]
	end

	local dimmed_name = "GoDim_" .. original_group:gsub("@", ""):gsub("%.", "_")

	local hl = vim.api.nvim_get_hl(0, { name = original_group, link = false })

	if hl.fg then
		local fg_hex = string.format("#%06x", hl.fg)
		local dimmed_fg = blend_colors(fg_hex, target_color, M.config.dim_percent)
		vim.api.nvim_set_hl(0, dimmed_name, {
			fg = dimmed_fg,
			bg = hl.bg,
			bold = hl.bold,
			italic = hl.italic,
			underline = hl.underline,
		})
	else
		local default_fg = "#cccccc"
		local dimmed_fg = blend_colors(default_fg, target_color, M.config.dim_percent)
		vim.api.nvim_set_hl(0, dimmed_name, { fg = dimmed_fg })
	end

	dimmed_groups[original_group] = dimmed_name
	return dimmed_name
end

local function clear_cache()
	dimmed_groups = {}
	target_color = M.config.dim_target or get_bg_color()
end

local function analyze_if_err_block(bufnr, block_node)
	local dominated_statements = 0
	local has_side_effects = false
	local is_wrapped = false

	local stmt_list = block_node:named_child(0)
	if not stmt_list or stmt_list:type() ~= "statement_list" then
		return { has_side_effects = true, is_wrapped = false, is_simple_return = false }
	end

	for i = 0, stmt_list:named_child_count() - 1 do
		local child = stmt_list:named_child(i)
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

local function dim_region(bufnr, start_row, start_col, end_row, end_col)
	for row = start_row, end_row do
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		if not line then
			goto continue
		end

		local col_start = (row == start_row) and start_col or 0
		local col_end = (row == end_row) and end_col or #line

		for col = col_start, col_end - 1 do
			local captures = vim.treesitter.get_captures_at_pos(bufnr, row, col)

			if #captures > 0 then
				local capture = captures[#captures]
				local hl_group = "@" .. capture.capture
				local dimmed = get_dimmed_group(hl_group)

				vim.api.nvim_buf_set_extmark(bufnr, ns, row, col, {
					end_col = col + 1,
					hl_group = dimmed,
					priority = 200,
				})
			end
		end

		::continue::
	end
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
						local start_row, start_col, end_row, end_col = if_node:range()
						dim_region(bufnr, start_row, start_col, end_row, end_col)
					end
				end
			end
		end
	end
end

local timer = nil

local function debounced_update(bufnr)
	if timer then
		timer:stop()
		timer:close()
	end
	timer = vim.loop.new_timer()
	timer:start(
		150,
		0,
		vim.schedule_wrap(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				M.update_dims(bufnr)
			end
			timer:stop()
			timer:close()
			timer = nil
		end)
	)
end

function M.setup(opts)
	opts = opts or {}

	M.config = vim.tbl_deep_extend("force", M.config, opts)

	target_color = M.config.dim_target or get_bg_color()

	local group = vim.api.nvim_create_augroup("GoErrorDim", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			clear_cache()
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.bo[buf].filetype == "go" then
					M.update_dims(buf)
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			M.update_dims(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			debounced_update(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			M.update_dims(ev.buf)
		end,
	})

	vim.api.nvim_create_user_command("GoErrorDimToggle", function()
		M.config.enabled = not M.config.enabled
		M.update_dims()
		print("Go error dim: " .. (M.config.enabled and "enabled" or "disabled"))
	end, {})

	vim.api.nvim_create_user_command("GoErrorDimStatus", function()
		print(string.format(
			"Go error dim: %s | simple_return: %s | wrapped_return: %s | percent: %d",
			M.config.enabled and "ON" or "OFF",
			M.config.dim_simple_return and "dim" or "normal",
			M.config.dim_wrapped_return and "dim" or "normal",
			M.config.dim_percent
		))
	end, {})
end

M._internal = {
	blend_colors = blend_colors,
	get_bg_color = get_bg_color,
	get_dimmed_group = function(original_group)
		return get_dimmed_group(original_group)
	end,
	clear_cache = function()
		clear_cache()
	end,
	get_cache = function()
		return dimmed_groups
	end,
	get_target_color = function()
		return target_color
	end,
	set_target_color = function(color)
		target_color = color
	end,
}

return M
