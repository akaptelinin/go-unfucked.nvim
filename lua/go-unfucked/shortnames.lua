local M = {}

local ns = vim.api.nvim_create_namespace("go_shortnames")

M.config = {
	enabled = false,
	binary = "shortnames-linter",
}

local function find_go_mod(start_path)
	local path = start_path
	while path ~= "/" do
		if vim.fn.filereadable(path .. "/go.mod") == 1 then
			return path
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
	return nil
end

local function parse_output(output, bufnr)
	local diagnostics = {}
	local filename = vim.api.nvim_buf_get_name(bufnr)

	for line in output:gmatch("[^\r\n]+") do
		local file, lnum, col, msg = line:match("^(.+):(%d+):(%d+): (.+)$")
		if file and file == filename then
			table.insert(diagnostics, {
				bufnr = bufnr,
				lnum = tonumber(lnum) - 1,
				col = tonumber(col) - 1,
				message = msg,
				severity = vim.diagnostic.severity.WARN,
				source = "shortnames",
			})
		end
	end

	return diagnostics
end

function M.run(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not M.config.enabled then
		return
	end

	if vim.bo[bufnr].filetype ~= "go" then
		return
	end

	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return
	end

	local filedir = vim.fn.fnamemodify(filename, ":h")
	local go_mod_dir = find_go_mod(filedir)

	if not go_mod_dir then
		return
	end

	local rel_dir = filedir:sub(#go_mod_dir + 2)
	local pkg_path = "./" .. rel_dir

	vim.fn.jobstart({ M.config.binary, pkg_path }, {
		cwd = go_mod_dir,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				local output = table.concat(data, "\n")
				local diagnostics = parse_output(output, bufnr)
				vim.diagnostic.set(ns, bufnr, diagnostics)
			end
		end,
		on_stderr = function(_, data)
			if data then
				local output = table.concat(data, "\n")
				local diagnostics = parse_output(output, bufnr)
				vim.diagnostic.set(ns, bufnr, diagnostics)
			end
		end,
		on_exit = function(_, code)
			if code == 0 then
				vim.diagnostic.set(ns, bufnr, {})
			end
		end,
	})
end

function M.clear(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	vim.diagnostic.set(ns, bufnr, {})
end

function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	if not M.config.enabled then
		return
	end

	local group = vim.api.nvim_create_augroup("GoShortnames", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
		group = group,
		pattern = "*.go",
		callback = function(ev)
			M.run(ev.buf)
		end,
	})

	vim.api.nvim_create_user_command("GoShortnamesRun", function()
		M.run()
	end, {})

	vim.api.nvim_create_user_command("GoShortnamsClear", function()
		M.clear()
	end, {})

	vim.api.nvim_create_user_command("GoShortnamesToggle", function()
		M.config.enabled = not M.config.enabled
		if M.config.enabled then
			M.run()
			print("Shortnames linter: enabled")
		else
			M.clear()
			print("Shortnames linter: disabled")
		end
	end, {})
end

return M
