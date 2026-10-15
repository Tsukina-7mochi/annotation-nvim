local header = require("annotation.header")

local M = {
    separator = "=====",
    ---@type integer | nil
    buf = nil,
}

---@return integer
function M.get_buffer ()
    if M.buf ~= nil and vim.api.nvim_buf_is_valid(M.buf) then
        return M.buf
    end

    local buf = vim.api.nvim_create_buf(true, false)
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "annotation"
    M.buf = buf
    return buf
end

---@param buf integer | nil
---@return integer
function M.open_win (buf)
    return vim.api.nvim_open_win(buf or M.get_buffer(), true, {
        relative = "cursor",
        row = 1,
        col = 0,
        title = "Annotation",
        width = math.floor(vim.o.columns * 0.5),
        height = 10,
        style = "minimal",
    })
end

---@param buf integer
---@param entry_header string
---@return integer
local function find_or_insert_entry (buf, entry_header)
    local entry_location = header.parse(entry_header)
    if entry_location == nil then
        error("entry header cannot be parsed: " .. entry_header)
    end

    local i = 0
    while true do
        local lines = vim.api.nvim_buf_get_lines(buf, i, i + 2, false)
        if #lines < 2 then
            i = i + #lines
            break
        end

        if lines[1] == M.separator then
            local line_location = header.parse(lines[2])
            if line_location ~= nil then
                local order = header.compare(entry_location, line_location)
                if order <= 0 then
                    break
                end
            end
        end

        i = i + 1
    end

    vim.api.nvim_buf_set_lines(buf, i, i, false, { M.separator, entry_header })
    return i + 2
end

---@param entry_header string
local function annotate_header (entry_header)
    local buf = M.get_buffer()
    local lnum = find_or_insert_entry(buf, entry_header)
    local win = M.open_win(buf)
    vim.api.nvim_win_set_cursor(win, { lnum, 0 })
end

---@param filename string
---@param line integer
function M.annotate_line (filename, line)
    annotate_header(header.line(filename, line))
end

---@param filename string
---@param line_from integer
---@param line_to integer
function M.annotate_lines (filename, line_from, line_to)
    annotate_header(header.lines(filename, line_from, line_to))
end

---@param filename string
---@param line_from integer
---@param col_from integer
---@param line_to integer
---@param col_to integer
function M.annotate_range (filename, line_from, col_from, line_to, col_to)
    annotate_header(header.range(filename, line_from, col_from, line_to, col_to))
end

function M.annotate ()
    local filename = vim.fn.expand("%")
    if filename == "" or vim.bo[0].buftype ~= "" then
        vim.notify("this buffer is not related to file", vim.log.levels.ERROR)
        return nil
    end

    local mode = vim.fn.mode()
    if mode == "n" then
        M.annotate_line(filename, vim.fn.getpos(".")[2])
    elseif mode == "V" then
        local from = vim.fn.getpos("v")
        local to = vim.fn.getpos(".")
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
        M.annotate_lines(filename, from[2], to[2])
    elseif mode == "v" then
        local from = vim.fn.getpos("v")
        local to = vim.fn.getpos(".")
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
        M.annotate_range(filename, from[2], from[3], to[2], to[3])
    else
        vim.notify("not in NORMAL, VISUAL, or VISUAL LINE mode", vim.log.levels.INFO)
    end
end

function M.setup ()
    vim.api.nvim_create_user_command("Annotate", M.annotate, {})
    vim.api.nvim_create_user_command("AnnotateOpen", M.open_win, {})
end

return M
