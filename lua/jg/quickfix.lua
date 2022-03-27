local M = {}

local fname_len_default = 96

local function format_fname(fname, len)
  if vim.fn.strchars(fname) <= len then
    return vim.fn.strcharpart(fname .. string.rep(' ', len), 0, len)
  end

  return '…' .. fname:sub(1 - len)
end

local function format_text(type, text)
  return (type and type:sub(1, 1):upper() .. ' ' or '') .. text
end

local function format_pos(lnum, lnum_len, col, col_len)
  return ('%' .. lnum_len .. 'd:%-' .. col_len .. 'd'):format(lnum, col)
end

local function buf_fname(bufnr)
  if bufnr > 0 then
    local fname = vim.fn.bufname(bufnr)
    if fname == '' then
      return '[No Name]'
    end

    fname, _ = fname:gsub('^' .. vim.env.HOME .. '/', '~/')
    fname, _ = fname:gsub('^%./', '')

    return fname
  end

  return ''
end

local function get_items(info)
  if info.quickfix == 1 then
    return vim.fn.getqflist({ id = info.id, items = 0 }).items
  end
  return vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
end

local function max_len(len, str)
  return math.max(len, vim.fn.strchars(str))
end

function M.format(info)
  local lines = {}
  local items = get_items(info)

  local fname_len = 0
  local lnum_len = 0
  local col_len = 0

  for _, e in ipairs(items) do
    if e.valid == 1 then
      e.fname = buf_fname(e.bufnr)
      e.lnum = e.lnum > 99999 and -1 or e.lnum
      e.col = e.col > 999 and -1 or e.col

      fname_len = max_len(fname_len, e.fname)
      lnum_len = max_len(lnum_len, e.lnum)
      col_len = max_len(col_len, e.col)
    end
  end

  fname_len = math.min(fname_len, fname_len_default)

  for _, e in ipairs(items) do
    if e.valid == 1 then
      e.text = ('%s │ %s │ %s'):format(
        format_fname(e.fname, fname_len),
        format_pos(e.lnum, lnum_len, e.col, col_len),
        format_text(e.type, e.text)
      )
    end

    table.insert(lines, e.text)
  end

  return lines
end

return M
