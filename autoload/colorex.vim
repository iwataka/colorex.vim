let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:colorex_cache_file_path')
  let g:colorex_cache_file_path = expand('~/.vim/.colorscheme.vim')
endif

if !exists('g:colorex_enable_cache_colorscheme_options')
  let g:colorex_enable_cache_colorscheme_options = 1
endif

fu! colorex#colorscheme_save()
  if exists('g:colors_name') && !empty(g:colors_name)
    let enable_cache_colorscheme_options = get(g:, 'colorex_enable_cache_colorscheme_options')
    let lines = enable_cache_colorscheme_options ?
          \ s:get_option_lines_for_specified_colorscheme(g:colors_name) : []
    let colors_name_line = printf('colorscheme %s', g:colors_name)
    let background_line = printf('set background=%s', &bg)
    let lines += [colors_name_line, background_line]
    call writefile(lines, s:get_cache_file_path())
  else
    call s:warn('Please select colorscheme and then re-execute')
    return
  endif
  if g:colorex_auto_cache
    call s:warn('This saved data will be possibly overwritten.')
  endif
endfu

fu! s:get_option_lines_for_specified_colorscheme(colors_name)
  let colors_name_keys = filter(keys(g:), printf("v:val =~ '^%s_'", a:colors_name))
  for colors_name_key in colors_name_keys
    let val = get(g:, colors_name_key)
    if type(val) == type('')
      let lines += [printf("let g:%s = '%s'", colors_name_key, val)]
    elseif type(val) == type(0)
      let lines += [printf("let g:%s = %s", colors_name_key, val)]
    endif
  endfor
endfu

fu! colorex#colorscheme_load()
  if filereadable(s:get_cache_file_path())
    execute printf('source %s', s:get_cache_file_path())
  endif
endfu

fu! s:get_cache_file_path()
  if fnamemodify(g:colorex_cache_file_path, ':e') == 'vim'
    return g:colorex_cache_file_path
  else
    return g:colorex_cache_file_path + '.vim'
  endif
endfu

fu! colorex#toggle_background()
  let opposite_bg = &bg == 'dark' ? 'light' : 'dark'
  let colors_name_before = exists('g:colors_name') ? g:colors_name : ''
  silent execute 'set background='.opposite_bg
  let colors_name_after = exists('g:colors_name') ? g:colors_name : ''
  " If the colorscheme doesn't support the changed background color, rollback
  " to before
  if !empty(colors_name_before) && colors_name_before != colors_name_after
    silent execute 'colorscheme '.colors_name_before
    call s:warn('You cannot toggle background for the current colorscheme')
  endif
endfu

fu! colorex#switch_contrast(bang, contrast)
  if !empty(a:contrast)
    call colorex#set_contrast(a:contrast)
  else
    call colorex#toggle_contrast(empty(a:bang))
  endif
endfu

let s:colorex_contrast_list_map = {
      \ 'gruvbox': ['soft', 'medium', 'hard'],
      \ 'solarized': ['low', 'normal', 'high']
      \ }

fu! colorex#toggle_contrast(incr)
  if exists('g:colors_name')
    if g:colors_name == 'gruvbox'
      exe 'let current_contrast = g:gruvbox_contrast_'.&bg
      call s:toggle_contrast(a:incr, current_contrast)
    elseif g:colors_name == 'solarized'
      let current_contrast = g:solarized_contrast
      call s:toggle_contrast(a:incr, current_contrast)
    else
      call s:warn(g:colors_name.' is not supported.')
    endif
  endif
endfu

fu! s:toggle_contrast(incr, current_contrast)
  let contrast_list = s:colorex_contrast_list_map[g:colors_name]
  let next_index = (index(contrast_list, a:current_contrast) + (a:incr ? 1 : -1)) % len(contrast_list)
  call colorex#set_contrast(contrast_list[next_index])
endfu

fu! colorex#set_contrast(contrast)
  if exists('g:colors_name')
    if g:colors_name == 'gruvbox'
      exe 'let g:gruvbox_contrast_'.&bg.' = "'.a:contrast.'"'
      colorscheme gruvbox
      redraw | exe 'echo "Current contrast: ".g:gruvbox_contrast_'.&bg
    elseif g:colors_name == 'solarized'
      let g:solarized_contrast = a:contrast
      colorscheme solarized
      redraw | echo 'Current contrast: '.g:solarized_contrast
    endif
  endif
endfu

fu! colorex#toggle_contrast_complete(A, L, P)
  if g:colors_name == 'gruvbox' || g:colors_name == 'solarized'
    return filter(s:colorex_contrast_list_map[g:colors_name], 'v:val =~ "'.a:A.'"')
  endif
endfu

fu! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl Normal
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
