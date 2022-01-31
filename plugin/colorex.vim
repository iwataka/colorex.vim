if &compatible || (exists('g:loaded_colorex') && g:loaded_colorex)
  finish
endif
let g:loaded_colorex = 1

if !exists('g:colorex_enable_auto_cache')
  let g:colorex_enable_auto_cache = 1
endif

com! ColorexSave call colorex#save()
com! ColorexLoad call colorex#load()
com! ColorexClear call colorex#clear()
com! ColorexToggleBackground call colorex#toggle_background()
com! -bang -nargs=* -complete=customlist,colorex#toggle_contrast_complete
      \ ColorexSwitchContrast call colorex#switch_contrast(<q-bang>, <q-args>)

augroup colorex
  autocmd!
  autocmd VimEnter * nested if g:colorex_enable_auto_cache | silent call colorex#load() | endif
  autocmd VimLeave * if g:colorex_enable_auto_cache | silent call colorex#save() | endif
augroup END
