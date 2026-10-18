local quickfix = require('quickfix')

local default_types = vim.deepcopy(quickfix.types)

local function qf_lines()
  local bufnr = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

local function syn_name(lnum)
  local bufnr = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
  local winid = vim.fn.bufwinid(bufnr)
  return vim.api.nvim_win_call(winid, function()
    local col = vim.fn.col({ lnum, '$' }) - 1
    return vim.fn.synIDattr(vim.fn.synID(lnum, col, 1), 'name')
  end)
end

describe('quickfix', function()
  local cwd = vim.fn.getcwd()
  local dir

  before_each(function()
    vim.cmd.runtime('plugin/quickfix.lua')
    quickfix.types = vim.deepcopy(default_types)

    dir = vim.fn.resolve(vim.fn.tempname()) .. '/a-b (c)+'
    vim.fn.mkdir(dir, 'p')
    vim.cmd.cd(vim.fn.fnameescape(dir))
  end)

  after_each(function()
    vim.cmd('cclose')
    vim.cmd('lclose')
    vim.fn.setqflist({}, 'f')
    vim.cmd.cd(vim.fn.fnameescape(cwd))
    vim.fn.delete(vim.fs.dirname(dir), 'rf')
  end)

  describe('setup', function()
    it('works without options', function()
      quickfix.setup()
      assert.same(default_types, quickfix.types)
    end)

    it('overrides types', function()
      quickfix.setup({ types = { error = '●' } })
      assert.equals('●', quickfix.types.error)
      assert.equals('W', quickfix.types.warning)
    end)
  end)

  describe('format', function()
    it('formats and aligns entries', function()
      vim.fn.setqflist({
        { filename = dir .. '/a.lua', lnum = 1, col = 2, text = 'one', type = 'E' },
        { filename = dir .. '/sub/bb.lua', lnum = 12, col = 10, text = 'two', type = 'w' },
        { filename = dir .. '/c.lua', lnum = 3, col = 1, text = 'untyped' },
      })
      vim.cmd('copen')

      assert.same({
        'a.lua      │  1:2  │ E one',
        'sub/bb.lua │ 12:10 │ W two',
        'c.lua      │  3:1  │ untyped',
      }, qf_lines())
    end)

    it('uses configured type icons', function()
      quickfix.setup({ types = { error = '●' } })
      vim.fn.setqflist({ { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'one', type = 'E' } })
      vim.cmd('copen')

      assert.same({ 'a.lua │ 1:1 │ ● one' }, qf_lines())
    end)

    it('formats entries appended while the window is open', function()
      vim.fn.setqflist({ { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'one' } })
      vim.cmd('copen')
      vim.fn.setqflist({}, 'a', { items = { { filename = dir .. '/b.lua', lnum = 2, col = 1, text = 'two' } } })

      assert.same({
        'a.lua │ 1:1 │ one',
        'b.lua │ 2:1 │ two',
      }, qf_lines())
    end)

    it('shortens paths in the home directory', function()
      local home = vim.env.HOME
      vim.env.HOME = vim.fs.dirname(dir)
      vim.cmd.cd('/')

      vim.fn.setqflist({ { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'one' } })
      vim.cmd('copen')
      vim.env.HOME = home

      assert.same({ '~/a-b (c)+/a.lua │ 1:1 │ one' }, qf_lines())
    end)

    it('truncates long file names to the column width', function()
      local name = string.rep('x', 120) .. 'ä.lua'
      vim.fn.setqflist({
        { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'short' },
        { filename = dir .. '/' .. name, lnum = 1, col = 1, text = 'long' },
      })
      vim.cmd('copen')

      local lines = qf_lines()
      local short = vim.split(lines[1], ' │ ')[1]
      local long = vim.split(lines[2], ' │ ')[1]

      assert.equals(96, vim.fn.strchars(short))
      assert.equals(96, vim.fn.strchars(long))
      assert.equals('…' .. vim.fn.strcharpart(name, vim.fn.strchars(name) - 95), long)
    end)

    it('keeps the text of invalid entries', function()
      vim.fn.setqflist({}, 'r', { lines = { 'not a location' }, efm = '%f:%l:%m' })
      vim.cmd('copen')

      assert.same({ 'not a location' }, qf_lines())
    end)

    it('formats location lists', function()
      vim.fn.setloclist(0, { { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'loc', type = 'I' } })
      vim.cmd('lopen')

      assert.same({ 'a.lua │ 1:1 │ I loc' }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end)
  end)

  describe('syntax', function()
    it('highlights types, including icons with special characters', function()
      quickfix.setup({ types = { error = '*', warning = '.', info = '/', hint = 'Hint', note = '[N]' } })
      vim.fn.setqflist({
        { filename = dir .. '/a.lua', lnum = 1, col = 1, text = 'e', type = 'E' },
        { filename = dir .. '/a.lua', lnum = 2, col = 1, text = 'w', type = 'W' },
        { filename = dir .. '/a.lua', lnum = 3, col = 1, text = 'i', type = 'I' },
        { filename = dir .. '/a.lua', lnum = 4, col = 1, text = 'h', type = 'H' },
        { filename = dir .. '/a.lua', lnum = 5, col = 1, text = 'n', type = 'N' },
      })
      vim.cmd('copen')

      assert.equals('qfError', syn_name(1))
      assert.equals('qfWarning', syn_name(2))
      assert.equals('qfInfo', syn_name(3))
      assert.equals('qfHint', syn_name(4))
      assert.equals('qfHint', syn_name(5))
    end)
  end)
end)
