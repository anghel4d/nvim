" Dark, low-glare surfaces with saturated early-PC syntax colors.
set background=dark
highlight clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'c64-brutalist'

function! s:Hi(group, fg, bg, cfg, cbg, ...) abort
  let attr = a:0 ? a:1 : 'NONE'
  execute 'highlight ' . a:group . ' guifg=' . a:fg . ' guibg=' . a:bg
        \ . ' ctermfg=' . a:cfg . ' ctermbg=' . a:cbg . ' gui=' . attr . ' cterm=' . attr
endfunction

call s:Hi('Normal', '#b6bac8', '#202430', 7, 0)
for group in ['NormalNC', 'NormalFloat', 'SignColumn', 'EndOfBuffer', 'FoldColumn', 'NvimTreeNormal', 'NvimTreeNormalNC', 'TelescopeNormal']
  call s:Hi(group, '#b6bac8', '#202430', 7, 0)
endfor
for group in ['LineNr', 'NonText', 'SpecialKey', 'Conceal', 'WinSeparator', 'VertSplit', 'FloatBorder', 'Folded']
  call s:Hi(group, '#939bac', '#202430', 8, 0)
endfor
call s:Hi('Comment', '#77aaaa', 'NONE', 6, 'NONE')
call s:Hi('Statement', '#ff66ff', 'NONE', 5, 'NONE')
call s:Hi('PreProc', '#ffcc55', 'NONE', 3, 'NONE')
call s:Hi('Function', '#55ddff', 'NONE', 6, 'NONE')
call s:Hi('Identifier', '#bbccff', 'NONE', 7, 'NONE')
call s:Hi('Type', '#7799ff', 'NONE', 4, 'NONE')
call s:Hi('String', '#66dd66', 'NONE', 2, 'NONE')
call s:Hi('Character', '#66dd66', 'NONE', 2, 'NONE')
for group in ['Constant', 'Number', 'Boolean', 'Float']
  call s:Hi(group, '#ff9955', 'NONE', 3, 'NONE')
endfor
call s:Hi('Operator', '#ffcc55', 'NONE', 3, 'NONE')
call s:Hi('Special', '#ff7777', 'NONE', 1, 'NONE')
call s:Hi('Delimiter', '#b6bac8', 'NONE', 7, 'NONE')
for group in ['Title', 'Directory', 'Question', 'MoreMsg']
  call s:Hi(group, '#a2abcf', 'NONE', 4, 'NONE')
endfor
call s:Hi('Underlined', '#a2abcf', 'NONE', 4, 'NONE', 'underline')
call s:Hi('Cursor', '#202430', '#a2abcf', 0, 4)
call s:Hi('CursorLine', 'NONE', '#262b38', 'NONE', 0)
call s:Hi('CursorLineNr', '#b6bac8', '#262b38', 7, 0)
for group in ['Visual', 'Search', 'IncSearch', 'CurSearch', 'MatchParen', 'PmenuSel', 'WildMenu', 'TelescopeSelection']
  call s:Hi(group, '#b6bac8', '#394254', 7, 8)
endfor
for group in ['StatusLine', 'TabLineSel', 'Pmenu']
  call s:Hi(group, '#b6bac8', '#262b38', 7, 0)
endfor
for group in ['StatusLineNC', 'TabLine', 'TabLineFill', 'PmenuSbar']
  call s:Hi(group, '#939bac', '#202430', 8, 0)
endfor
call s:Hi('PmenuThumb', 'NONE', '#939bac', 'NONE', 8)
for group in ['Error', 'ErrorMsg', 'DiagnosticError', 'DiagnosticVirtualTextError', 'DiffDelete']
  call s:Hi(group, '#c49a9a', 'NONE', 1, 'NONE')
endfor
for group in ['WarningMsg', 'DiagnosticWarn', 'DiagnosticVirtualTextWarn', 'Todo', 'DiffChange', 'DiffText']
  call s:Hi(group, '#bdb08b', 'NONE', 3, 'NONE')
endfor
for group in ['DiffAdd', 'Added', 'DiagnosticOk']
  call s:Hi(group, '#a7b89d', 'NONE', 2, 'NONE')
endfor
for group in ['DiagnosticInfo', 'DiagnosticHint', 'DiagnosticVirtualTextInfo', 'DiagnosticVirtualTextHint']
  call s:Hi(group, '#939bac', 'NONE', 8, 'NONE')
endfor
for group in ['SpellBad', 'SpellCap', 'SpellLocal', 'SpellRare']
  call s:Hi(group, 'NONE', 'NONE', 'NONE', 'NONE', 'underline')
endfor
highlight! link Removed DiffDelete
highlight! link Changed DiffChange
highlight! link NvimTreeFolderName Directory
highlight! link NvimTreeOpenedFolderName Directory
highlight! link NvimTreeRootFolder Directory
highlight! link TelescopeBorder FloatBorder
highlight! link TelescopeMatching Underlined
highlight! link WinBar StatusLine
highlight! link WinBarNC StatusLineNC

let s:ansi = ['#202430', '#ff7777', '#66dd66', '#ffcc55', '#7799ff', '#ff66ff', '#55ddff', '#b6bac8', '#939bac', '#ff7777', '#66dd66', '#ffcc55', '#7799ff', '#ff66ff', '#55ddff', '#b6bac8']
for i in range(16)
  let g:terminal_color_{i} = s:ansi[i]
endfor
let g:terminal_ansi_colors = s:ansi
unlet s:ansi
 delfunction s:Hi
