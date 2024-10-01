local types = require('quickfix').types

vim.cmd.syntax('match', 'qfFileName', '/^[^│]*/', 'nextgroup=qfSeparatorLeft')
vim.cmd.syntax('match', 'qfSeparatorLeft', '/│/', 'contained nextgroup=qfLineNr')
vim.cmd.syntax('match', 'qfLineNr', '/[^│]*/', 'contained nextgroup=qfSeparatorRight')
vim.cmd.syntax('match', 'qfSeparatorRight', '/│/', 'contained nextgroup=qfError,qfWarning,qfInfo,qfHint')
vim.cmd.syntax('match', 'qfError', '/ ' .. types.error .. ' .*$/', 'contained')
vim.cmd.syntax('match', 'qfWarning', '/ ' .. types.warning .. ' .*$/', 'contained')
vim.cmd.syntax('match', 'qfInfo', '/ ' .. types.info .. ' .*$/', 'contained')
vim.cmd.syntax('match', 'qfHint', '/ [' .. types.note .. types.hint .. '] .*$/', 'contained')

vim.cmd.hi('def', 'link', 'qfFileName', 'Directory')
vim.cmd.hi('def', 'link', 'qfSeparatorLeft', 'Delimiter')
vim.cmd.hi('def', 'link', 'qfSeparatorRight', 'Delimiter')
vim.cmd.hi('def', 'link', 'qfLineNr', 'LineNr')
vim.cmd.hi('def', 'link', 'qfError', 'DiagnosticError')
vim.cmd.hi('def', 'link', 'qfWarning', 'DiagnosticWarn')
vim.cmd.hi('def', 'link', 'qfInfo', 'DiagnosticInfo')
vim.cmd.hi('def', 'link', 'qfHint', 'DiagnosticHint')

vim.b.current_syntax = 'qf'
