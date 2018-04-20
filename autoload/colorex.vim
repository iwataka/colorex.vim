let s:save_cpo = &cpoptions
set cpoptions&vim

if !exists('g:colorex_cache_file_path')
  let g:colorex_cache_file_path = expand('~/.vim/.colorscheme.cache')
endif

fu! colorex#colorscheme_save()
  if g:colorex_auto_cache
    call s:warn('This saved data will be possibly overwritten.')
  endif
  if exists('g:colors_name')
    let lines = [g:colors_name, &background]
    if g:colors_name == 'gruvbox'
      if g:colors_name == 'gruvbox'
        silent execute 'let lines += [g:gruvbox_contrast_'.&bg.']'
      elseif g:colors_name == 'solarized'
        let lines += [g:solarized_contrast]
      endif
    endif
    call writefile(lines, g:colorex_cache_file_path)
  endif
endfu

fu! colorex#colorscheme_load()
  if filereadable(g:colorex_cache_file_path)
    let lines = readfile(g:colorex_cache_file_path)
    silent execute 'colorscheme '.lines[0]
    if len(lines) >= 3
      if exists('g:colors_name')
        if g:colors_name == 'gruvbox'
          silent execute "let g:gruvbox_contrast_".&bg." = '".lines[2]."'"
        elseif g:colors_name == 'solarized'
          let g:solarized_contrast = lines[2]
        endif
      endif
    endif
    silent execute 'set background='.lines[1]
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
