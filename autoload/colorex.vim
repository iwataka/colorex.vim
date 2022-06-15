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

fu! colorex#save(warn)
  let lines = s:get_colorscheme_lines() + s:get_airline_lines() + s:get_lightline_lines()
  if !empty(lines)
    call writefile(lines, s:get_cache_file_path())
    if a:warn
      call s:warn('This saved data will be overwritten on save.')
    endif
    return 1
  endif
  return 0
endfu

fu! colorex#clear()
  call delete(s:get_cache_file_path())
  unlet g:[s:option_map_key_name]
endfu

fu! s:get_colorscheme_lines()
  if has_key(g:, 'colors_name') && !empty(g:colors_name)
    let option_lines = g:colorex_enable_cache_colorscheme_options ?
          \ s:get_colorscheme_option_lines() : []
    let colors_name_line = printf('colorscheme %s', g:colors_name)
    let background_line = printf('set background=%s', &bg)
    return option_lines + [colors_name_line, background_line]
  endif
  return []
endfu

let s:extra_colorscheme_option_keys = {
      \ 'ayu': ['ayucolor'],
      \ }

fu! s:get_var_prefix()
  return printf('%s_', substitute(tolower(g:colors_name), '-', '_', 'g'))
endfu

fu! s:get_colorscheme_option_lines()
  let cur_option_keys = keys(get(g:, s:option_map_key_name, {}))
  let new_option_keys = filter(keys(g:), printf("v:val =~ '^%s'", s:get_var_prefix()))
  if has_key(s:extra_colorscheme_option_keys, g:colors_name)
    call extend(new_option_keys, s:extra_colorscheme_option_keys[g:colors_name])
  endif
  let option_keys = uniq(cur_option_keys + new_option_keys)
  let valid_option_keys = filter(option_keys, 'has_key(g:, v:val)')
  let option_map = {}
  for key in valid_option_keys
    let option_map[key] = get(g:, key)
  endfor
  return [
        \ printf('let g:%s = %s', s:option_map_key_name, string(option_map)),
        \ printf("call extend(g:, get(g:, '%s', {}), 'keep')", s:option_map_key_name),
        \ ]
endfu

fu! s:get_airline_lines()
  let theme = get(g:, 'airline_theme', '')
  if !empty(theme)
    return [printf("silent! exe 'AirlineTheme %s'", theme)]
  endif
  return []
endfu

fu! s:get_lightline_lines()
  let lightline = get(g:, 'lightline', {})
  let theme = get(lightline, 'colorscheme', '')
  if !empty(theme)
    return [
          \ "if !has_key(g:, 'lightline')",
          \ "    let g:lightline = {}",
          \ "endif",
          \ printf("let g:lightline.colorscheme = '%s'", theme),
          \ 'call lightline#init()',
          \ 'call lightline#colorscheme()',
          \ 'call lightline#update()',
          \ ]
  endif
  return []
endfu

fu! colorex#load()
  if filereadable(s:get_cache_file_path())
    exe printf('source %s', s:get_cache_file_path())
    return 1
  endif
  return 0
endfu

fu! s:get_cache_file_path()
  if fnamemodify(g:colorex_cache_file_path, ':e') == 'vim'
    return g:colorex_cache_file_path
  else
    return g:colorex_cache_file_path + '.vim'
  endif
endfu

fu! colorex#toggle_background()
  if g:colors_name == 'ayu'
    call s:toggle_background_for_ayu()
    return
  endif
  let opposite_bg = &bg == 'dark' ? 'light' : 'dark'
  let colors_name_before = has_key(g:, 'colors_name') ? g:colors_name : ''
  silent exe 'set background='.opposite_bg
  let colors_name_after = has_key(g:, 'colors_name') ? g:colors_name : ''
  " If the colorscheme doesn't support the changed background color, rollback
  " to before
  if !empty(colors_name_before) && colors_name_before != colors_name_after
    silent exe 'colorscheme '.colors_name_before
    call s:warn('You cannot toggle background for the current colorscheme')
  endif
endfu

let s:ayu_colors = ['dark', 'mirage', 'light']

fu! s:toggle_background_for_ayu()
  let color = get(g:, 'ayucolor', s:ayu_colors[0])
  let next_color = s:ayu_colors[(index(s:ayu_colors, color) + 1) % 3]
  let g:ayucolor = next_color
  silent exe 'colorscheme ayu'
endfu

fu! colorex#switch_contrast(bang, contrast)
  if !empty(a:contrast)
    call colorex#set_contrast(a:contrast)
  else
    call colorex#toggle_contrast(empty(a:bang))
  endif
endfu

let s:solarized_contrasts = ['low', 'normal', 'high']
let s:gruvbox_contrasts = ['soft', 'medium', 'hard']

let s:colorex_contrast_list_map = {
      \ 'gruvbox': s:gruvbox_contrasts,
      \ 'gruvbox-material': s:gruvbox_contrasts,
      \ 'everforest': s:gruvbox_contrasts,
      \ 'solarized': s:solarized_contrasts,
      \ 'NeoSolarized': s:solarized_contrasts,
      \ }

fu! s:can_switch_contrast()
  return has_key(s:colorex_contrast_list_map, g:colors_name)
endfu

fu! s:get_contrast_varname()
  if s:can_switch_contrast()
    if g:colors_name == 'gruvbox'
      return 'gruvbox_contrast_'.&background
    elseif g:colors_name == 'gruvbox-material'
      return 'gruvbox_material_background'
    elseif g:colors_name == 'everforest'
      return 'everforest_background'
    else
      return s:get_var_prefix().'contrast'
    endif
  endif
endfu

fu! colorex#toggle_contrast(incr)
  if s:can_switch_contrast()
    call s:toggle_contrast(a:incr, get(g:, s:get_contrast_varname()))
  else
    call s:warn(g:colors_name.' is not supported.')
  endif
endfu

fu! s:toggle_contrast(incr, current_contrast)
  let contrast_list = s:colorex_contrast_list_map[g:colors_name]
  let next_index = (index(contrast_list, a:current_contrast) + (a:incr ? 1 : -1)) % len(contrast_list)
  call colorex#set_contrast(contrast_list[next_index])
endfu

fu! colorex#set_contrast(contrast)
  if s:can_switch_contrast()
    let varname = s:get_contrast_varname()
    let g:[varname] = a:contrast
    echo printf('Current contrast: %s', get(g:, varname))
    silent exe 'colorscheme '.g:colors_name
  endif
endfu

fu! colorex#toggle_contrast_complete(A, L, P)
  if s:can_switch_contrast()
    let cands = copy(s:colorex_contrast_list_map[g:colors_name])
    return filter(cands, 'v:val =~ "'.a:A.'"')
  endif
endfu

fu! s:warn(msg)
  echohl WarningMsg
  echo a:msg
  echohl Normal
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
