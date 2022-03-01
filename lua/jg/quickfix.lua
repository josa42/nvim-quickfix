local M = {}

local limit_default = 96

local function pad_right(str, len)
  return string.sub(str .. string.rep(' ', len), 0, len)
end

local function format_fname(fname, limit)
  -- char in fname may occur more than 1 width, ignore this issue in order to keep performance
  if #fname <= limit then
    return pad_right(fname, limit)
  end

  return '…' .. fname:sub(1 - limit)
end

local function buf_fname(bufnr)
  if bufnr > 0 then
    local fname = vim.fn.bufname(bufnr)
    if fname == '' then
      return '[No Name]'
    end

    return fname:gsub('^' .. vim.env.HOME, '~')
  end

  return ''
end

local function get_items(info)
  if info.quickfix == 1 then
    return vim.fn.getqflist({ id = info.id, items = 0 }).items
  end
  return vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
end

function M.format(info)
  local ret = {}

  for _, e in ipairs(get_items(info)) do
    local str

    if e.valid == 1 then
      local fname = format_fname(buf_fname(e.bufnr), limit_default)

      local lnum = e.lnum > 99999 and -1 or e.lnum
      local col = e.col > 999 and -1 or e.col
      local qtype = e.type == '' and '' or ' ' .. e.type:sub(1, 1):upper()

      str = ('%s │%5d:%-3d│%s %s'):format(fname, lnum, col, qtype, e.text)
    else
      str = e.text
    end
    table.insert(ret, str)
  end

  return ret
end

return M
