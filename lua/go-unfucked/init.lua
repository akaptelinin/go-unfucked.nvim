local M = {}

function M.setup(opts)
	opts = opts or {}

	require("go-unfucked.import-hints").setup(opts.import_hints or {})
	require("go-unfucked.receiver-highlight").setup(opts.receiver_highlight or {})
	require("go-unfucked.error-dim").setup(opts.error_dim or {})
	require("go-unfucked.shortnames").setup(opts.shortnames or {})
end

return M
