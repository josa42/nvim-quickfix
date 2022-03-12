local M = {}

local function get_on_read(results)
  return function(err, chunk)
    if err then
      print(err)
    end
    if chunk then
      for line in chunk:gmatch('[^\r\n]+') do
        table.insert(results, line)
      end
    end
  end
end

local function set_quickfix(results)
  vim.fn.setqflist({}, 'r', { title = 'Search Results', lines = results })
  vim.cmd('cwindow')
  if #results > 0 then
    vim.cmd('cfirst')
    vim.cmd('copen')
  end
end

local function run(cmd, args, process)
  local results = {}
  local handle

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  handle = vim.loop.spawn(
    cmd,
    { args = args, stdio = { stdout, stderr } },
    vim.schedule_wrap(function()
      stdout:read_stop()
      stderr:read_stop()

      stdout:close()
      stderr:close()

      handle:close()

      if process ~= nil then
        for i, line in ipairs(results) do
          results[i] = process(line)
        end
      end

      set_quickfix(results)
    end)
  )

  local on_read = get_on_read(results)

  vim.loop.read_start(stdout, on_read)
  vim.loop.read_start(stderr, on_read)
end

local function real_path(path)
  path, _ = path:gsub('^~', vim.env.HOME)

  return path
end

function M.rg(pattern, dir)
  run('rg', { '--regexp', pattern, real_path(dir or '.'), '--vimgrep', '--smart-case' })
end

function M.fd(pattern, dir)
  run('fd', { '--regex', pattern, '--type', 'file', '--search-path', real_path(dir or '.') }, function(line)
    return line .. ':1: ' -- line .. line:gsub('^.*/', '')
  end)
end

return M
