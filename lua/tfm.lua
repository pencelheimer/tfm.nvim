local PATH_SELECTED_FILES = vim.fn.stdpath("cache") .. "/tfm_selected_files"

local M = {}

---Configurable user options.
---@class Options
---@field keybindings table<string, string>
---@field ui UI

---@class UI
---@field height number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field width number from 0 to 1 (0 = 0% of screen and 1 = 100% of screen)
---@field x number from 0 to 1 (0 = left most of screen and 1 = right most of screen)
---@field y number from 0 to 1 (0 = top most of screen and 1 = bottom most of screen)

---@enum OPEN_MODE
M.OPEN_MODE = {
    vsplit = "vsplit",
    split = "split",
    tabedit = "tabedit",
}

---@type Options
local default_opts = {
    ui = {
        height = 0.9,
        width = 0.9,
        x = 0.5,
        y = 0.5,
    },
    keybindings = {
        ["<ESC>"] = "q",
        ["<C-v>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.vsplit)<CR><CR>",
        ["<C-x>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.split)<CR><CR>",
        ["<C-t>"] = "<C-\\><C-O>:lua require('tfm').set_next_open_mode(require('tfm').OPEN_MODE.tabedit)<CR><CR>",
    },
}

---Get merged options from defaults and `vim.g.tfm`
---@return Options
local function get_opts()
    local user_opts = vim.g.tfm
    if type(user_opts) == "table" then
        return vim.tbl_deep_extend("force", default_opts, user_opts)
    end
    return default_opts
end

---Get the function which will be used to open files based on the given mode
---@param open_mode OPEN_MODE|nil The mode to open the selected file(s) with
---@return function
local function get_edit_fn(open_mode)
    return (open_mode and vim.cmd[open_mode]) or vim.cmd.edit
end

---Handles opening of the selected path(s)
---@param open_mode OPEN_MODE|nil The mode to open the selected file(s) with
local function open_paths(open_mode)
    if vim.fn.filereadable(PATH_SELECTED_FILES) ~= 1 then
        return
    end

    local selected_files = vim.fn.readfile(PATH_SELECTED_FILES)
    local edit = get_edit_fn(open_mode)
    local directories = {}

    for _, path in ipairs(selected_files) do
        if vim.fn.isdirectory(path) == 1 then
            table.insert(directories, path)
        else
            edit(path)
        end
    end

    -- Reopen the TFM again with the selected first directory, ignore the rest
    if directories[1] then
        M.open(directories[1], open_mode)
    end
end

---Builds the Yazi launch command
---@param path_to_open string|nil Path to the file/directory to open. If `nil`, the current file will be used.
---@return string[]
local function build_cmd(path_to_open)
    local cmd = { "yazi", "--chooser-file", PATH_SELECTED_FILES }
    local target = path_to_open
    if not target then
        local current_file = vim.api.nvim_buf_get_name(0)
        if current_file ~= "" then
            target = current_file
        end
    end

    if target then
        table.insert(cmd, target)
    end

    return cmd
end

---Returns window configuration for the floating window
---@param ui UI
---@return vim.api.keyset.win_config
local function get_win_config(ui)
    local win_height = math.ceil(vim.o.lines * ui.height)
    local win_width = math.ceil(vim.o.columns * ui.width)
    return {
        relative = "editor",
        style = "minimal",
        height = win_height,
        width = win_width,
        row = math.ceil((vim.o.lines - win_height) * ui.y - 1),
        col = math.ceil((vim.o.columns - win_width) * ui.x),
    }
end

---Open a window for the TFM to run in
---@param opts Options
local function open_win(opts)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, get_win_config(opts.ui))

    vim.api.nvim_set_option_value("winhl", "NormalFloat:Normal", { win = win })
    vim.api.nvim_set_option_value("filetype", "tfm", { buf = buf })

    -- Resize the window when Neovim is resized
    local group = vim.api.nvim_create_augroup("tfm_window", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        buffer = buf,
        callback = function()
            vim.api.nvim_win_set_config(win, get_win_config(opts.ui))
        end,
    })

    -- Apply custom keybinds
    for keybind, command in pairs(opts.keybindings) do
        vim.keymap.set("t", keybind, command, { buffer = buf, silent = true })
    end
end

---Returns a table with the names of all currently listed buffers that point to existing files
---@return string[]
local function get_buffers_for_existing_files()
    local buffer_names = {}

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(buf) == 1 then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if vim.fn.filereadable(buf_name) == 1 then
                table.insert(buffer_names, buf_name)
            end
        end
    end

    return buffer_names
end

---Closes any buffers from the given table which point to files that no longer exist
---@param buffers string[]
local function close_empty_buffers(buffers)
    for _, buf in ipairs(buffers) do
        if vim.fn.filereadable(buf) ~= 1 then
            vim.cmd.bdelete(buf)
        end
    end
end

---Clean up temporary files used to communicate between the terminal file manager and the plugin
local function clean_up()
    vim.fn.delete(PATH_SELECTED_FILES)
end

---Opens the terminal file manager and open selected files on exit
---@param path_to_open string|nil Open the terminal file manager and select the current file. False means open the current directory instead (or pass in a second argument to specify a different path). Defaults to true.
---@param open_mode OPEN_MODE|nil Open the selected file(s) using a specific mode, e.g. "split", "vsplit", "tabedit"
function M.open(path_to_open, open_mode)
    assert(
        vim.fn.executable("yazi") == 1,
        "The 'yazi' executable not found, please check that 'yazi' is installed and is in your path\n"
    )

    clean_up()

    local opts = get_opts()
    local buffers_for_existing_files = get_buffers_for_existing_files()
    local cmd = build_cmd(path_to_open)
    local last_win = vim.api.nvim_get_current_win()

    open_win(opts)

    local on_exit = function(_, code, _)
        if code ~= 0 then return end

        open_mode = vim.b.tfm_next_open_mode or open_mode

        vim.api.nvim_win_close(0, true)
        vim.api.nvim_set_current_win(last_win)

        open_paths(open_mode)
        clean_up()
        close_empty_buffers(buffers_for_existing_files)
    end

    vim.fn.jobstart(cmd, { term = true, on_exit = on_exit })
    vim.cmd.startinsert()
end

---Set the next mode that selected file(s) will be opened with
---@param open_mode OPEN_MODE|nil The next mode to open selected file(s) with
function M.set_next_open_mode(open_mode)
    vim.b.tfm_next_open_mode = open_mode
end

return M
