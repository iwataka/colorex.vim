let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:colorex_cache_file_path')
  let g:colorex_cache_file_path = expand('~/.vim/.colorscheme.vim')
endif

if !exists('g:colorex_enable_cache_colorscheme_options')
  let g:colorex_enable_cache_colorscheme_options = 1
endif

" The name of global variable storing all colorscheme options.
let s:option_map_key_name = '_colorex_colorscheme_option_map'

fu! colorex#save()
  let lines = s:get_colorscheme_lines() + s:get_airline_lines()
  if !empty(lines)
    call writefile(lines, s:get_cache_file_path())
    if g:colorex_enable_auto_cache
      call s:warn('This saved data will be overwritten on save.')
    endif
  endif
endfu

fu! s:get_colorscheme_lines()
  if exists('g:colors_name') && !empty(g:colors_name)
    let option_lines = g:colorex_enable_cache_colorscheme_options ?
          \ s:get_colorscheme_option_lines(g:colors_name) : []
    let colors_name_line = printf('colorscheme %s', g:colors_name)
    let background_line = printf('set background=%s', &bg)
    return option_lines + [colors_name_line, background_line]
  endif
  return []
endfu

fu! s:get_colorscheme_option_lines(colors_name)
  let cur_option_keys = keys(get(g:, s:option_map_key_name, {}))
  let new_option_keys = filter(keys(g:), printf("v:val =~ '^%s_'", a:colors_name))
  let option_keys = uniq(cur_option_keys + new_option_keys)
  let valid_option_keys = filter(option_keys, 'has_key(g:, v:val)')
  let option_map = {}
  for key in valid_option_keys
    let option_map[key] = get(g:, key)
  endfor
  return [printf('let g:%s = %s', s:option_map_key_name, string(option_map))]
endfu

fu! s:get_airline_lines()
  if has_key(g:, 'airline_theme')
    let theme = get(g:, 'airline_theme')
    return [printf("silent! exe 'AirlineTheme %s'", theme)]
  endif
  return []
endfu

fu! colorex#load()
  if filereadable(s:get_cache_file_path())
    execute printf('source %s', s:get_cache_file_path())
  endif
  call extend(g:, get(g:, s:option_map_key_name), 'keep')
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

let s:solarized_contrasts = ['low', 'normal', 'high']

let s:colorex_contrast_list_map = {
      \ 'gruvbox': ['soft', 'medium', 'hard'],
      \ 'solarized': s:solarized_contrasts,
      \ 'NeoSolarized': s:solarized_contrasts,
      \ }

fu! colorex#toggle_contrast(incr)
  if exists('g:colors_name')
    if g:colors_name == 'gruvbox'
      exe 'let current_contrast = g:gruvbox_contrast_'.&bg
      call s:toggle_contrast(a:incr, current_contrast)
    elseif g:colors_name == 'solarized'
      call s:toggle_contrast(a:incr, g:solarized_contrast)
    elseif g:colors_name == 'NeoSolarized'
      call s:toggle_contrast(a:incr, g:neosolarized_contrast)
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
    elseif g:colors_name == 'NeoSolarized'
      let g:neosolarized_contrast = a:contrast
      colorscheme NeoSolarized
      redraw | echo 'Current contrast: '.g:neosolarized_contrast
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
