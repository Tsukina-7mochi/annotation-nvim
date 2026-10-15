local M = {}

---@class annotation.Position
---@field line integer
---@field col integer

---@class annotation.Location
---@field filename string
---@field from annotation.Position
---@field to annotation.Position

---@param value string
---@return integer
local function parse_integer (value)
    local parsed = tonumber(value)
    if parsed == nil or parsed ~= math.floor(parsed) then
        error(value .. " cannot be parsed to integer")
    end
    return parsed
end

---@param a annotation.Position
---@param b annotation.Position
---@return integer
local function compare_position (a, b)
    if a.line ~= b.line then
        return a.line < b.line and -1 or 1
    end
    if a.col ~= b.col then
        return a.col < b.col and -1 or 1
    end
    return 0
end

---@param filename string
---@param line integer
---@return string
function M.line (filename, line)
    return ("%s:L%d"):format(filename, line)
end

---@param filename string
---@param line_from integer
---@param line_to integer
---@return string
function M.lines (filename, line_from, line_to)
    return ("%s:L%d-L%d"):format(filename, math.min(line_from, line_to), math.max(line_from, line_to))
end

---@param filename string
---@param line_from integer
---@param col_from integer
---@param line_to integer
---@param col_to integer
---@return string
function M.range (filename, line_from, col_from, line_to, col_to)
    local from = { line = line_from, col = col_from }
    local to = { line = line_to, col = col_to }
    local first, last = from, to
    if compare_position(from, to) > 0 then
        first, last = to, from
    end
    return ("%s:L%d.%d-L%d.%d"):format(filename, first.line, first.col, last.line, last.col)
end

---@param line string
---@return annotation.Location | nil
function M.parse (line)
    local filename, line_from, col_from, line_to, col_to = line:match("^(.*):L(%d+)%.(%d+)%-L(%d+)%.(%d+)$")
    if filename ~= nil then
        return {
            filename = filename,
            from = { line = parse_integer(line_from), col = parse_integer(col_from) },
            to = { line = parse_integer(line_to), col = parse_integer(col_to) },
        }
    end

    filename, line_from, line_to = line:match("^(.*):L(%d+)%-L(%d+)$")
    if filename ~= nil then
        return {
            filename = filename,
            from = { line = parse_integer(line_from), col = 0 },
            to = { line = parse_integer(line_to), col = 0 },
        }
    end

    filename, line_from = line:match("^(.*):L(%d+)$")
    if filename ~= nil then
        return {
            filename = filename,
            from = { line = parse_integer(line_from), col = 0 },
            to = { line = parse_integer(line_from), col = 0 },
        }
    end

    return nil
end

---@param a annotation.Location
---@param b annotation.Location
---@return integer
function M.compare (a, b)
    if a.filename ~= b.filename then
        return a.filename < b.filename and -1 or 1
    end

    local from_order = compare_position(a.from, b.from)
    if from_order ~= 0 then
        return from_order
    end

    local to_order = compare_position(a.to, b.to)
    if to_order ~= 0 then
        return to_order
    end

    return 0
end

return M
