if &compatible || (exists('g:loaded_colorex') && g:loaded_colorex)
  finish
endif
let g:loaded_colorex = 1

if !exists('g:colorex_auto_cache')
  let g:colorex_auto_cache = 1
endif

com! ColorexSaveColorScheme call colorex#colorscheme_save()
com! ColorexLoadColorScheme call colorex#colorscheme_load()
com! ColorexToggleBackground call colorex#toggle_background()
com! -bang -nargs=* -complete=customlist,colorex#toggle_contrast_complete
      \ ColorexSwitchContrast call colorex#switch_contrast(<q-bang>, <q-args>)

augroup colorex
  autocmd!
  autocmd VimEnter * nested if g:colorex_auto_cache | call colorex#colorscheme_load() | endif
  autocmd VimLeave * if g:colorex_auto_cache | call colorex#colorscheme_save() | endif
augroup END
