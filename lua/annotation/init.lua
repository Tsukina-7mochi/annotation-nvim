local M = {
    separator = "=====",
    ---@type integer | nil
    buf = nil,
}

---@param filename string
---@param lnum integer
---@return string
local function make_header (filename, lnum)
    return ("%s:L%d"):format(filename, lnum)
end

---@param line string
---@return string | nil, integer | nil
local function parse_header (line)
    local filename, lnum = line:match("^(.*):L(%d+)$")
    if filename == nil then
        return nil, nil
    end
    return filename, tonumber(lnum)
end

---@param a string
---@param b string
---@return integer | nil
local function compare_header (a, b)
    local a_filename, a_lnum = parse_header(a)
    local b_filename, b_lnum = parse_header(b)

    if a_filename == nil or b_filename == nil then
        return nil
    end

    if a_filename ~= b_filename then
        return a_filename < b_filename and -1 or 1
    end
    if a_lnum ~= b_lnum then
        return a_lnum < b_lnum and -1 or 1
    end
    return 0
end

---@return integer
function M.get_buffer ()
    if M.buf ~= nil and vim.api.nvim_buf_is_valid(M.buf) then
        return M.buf
    end

    M.buf = vim.api.nvim_create_buf(true, false)
    vim.bo[M.buf].buftype = "acwrite"
    vim.bo[M.buf].bufhidden = "hide"
    vim.bo[M.buf].swapfile = false
    vim.bo[M.buf].filetype = "annotation"
    return M.buf
end

function M.open_annotation ()
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" or vim.bo.buftype ~= "" then
        return vim.notify("this buffer is not related to file", vim.log.levels.ERROR)
    end
    local lnum = vim.api.nvim_win_get_cursor(0)[1]

    local buf = M.get_buffer()
    vim.api.nvim_open_win(buf, true, {
        relative = "cursor",
        row = 1,
        col = 0,
        title = "Annotation",
        width = math.floor(vim.o.columns * 0.5),
        height = 10,
        style = "minimal",
    })

    local header = make_header(filename, lnum)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    local insert_at = #lines
    for i, line in ipairs(lines) do
        if line == M.separator and lines[i + 1] ~= nil then
            local order = compare_header(header, lines[i + 1])
            if order == 0 then
                vim.api.nvim_win_set_cursor(0, { i + 2, 0 })
                return
            elseif order < 0 then
                insert_at = i - 1
                break
            end
        end
    end

    local entry = { M.separator, header, "" }
    if #lines == 1 and lines[1] == "" then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, entry)
        insert_at = 0
    else
        vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, entry)
    end
    vim.api.nvim_win_set_cursor(0, { insert_at + 3, 0 })
end

function M.setup ()
    vim.api.nvim_create_user_command("Annotate", M.open_annotation, {})
    vim.api.nvim_create_user_command("AnnotationEdit", function ()
        vim.cmd(("b %d"):format(M.get_buffer()))
    end, {})
    vim.api.nvim_create_user_command("AnnotationTabEdit", function ()
        vim.cmd(("tab sb %d"):format(M.get_buffer()))
    end, {})
    vim.api.nvim_create_user_command("AnnotationDrop", function ()
        vim.api.nvim_buf_delete(M.buf, { force = true })
        M.buf = nil
    end, {})
end

return M
