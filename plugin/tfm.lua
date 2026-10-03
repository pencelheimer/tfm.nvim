if vim.g.loaded_tfm then
    return
end
vim.g.loaded_tfm = true

local function open(args, mode)
    local path = (args and args ~= "") and args or nil
    require("tfm").open(path, mode)
end

vim.api.nvim_create_user_command("Tfm", function(opts)
    open(opts.args)
end, { nargs = "?", complete = "file", desc = "Open Yazi in current window" })

vim.api.nvim_create_user_command("TfmSplit", function(opts)
    open(opts.args, "split")
end, { nargs = "?", complete = "file", desc = "Open Yazi in horizontal split" })

vim.api.nvim_create_user_command("TfmVsplit", function(opts)
    open(opts.args, "vsplit")
end, { nargs = "?", complete = "file", desc = "Open Yazi in vertical split" })

vim.api.nvim_create_user_command("TfmTabedit", function(opts)
    open(opts.args, "tabedit")
end, { nargs = "?", complete = "file", desc = "Open Yazi in new tab" })
