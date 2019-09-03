if exists('g:loaded_translate_plugin')
  finish
endif
let g:loaded_translate_plugin = 1

command! -nargs=* -range -bang TranslateVisual call translate#run('visual', <q-args>, '<bang>')
command! -nargs=* -range -bang TranslateRange <line1>,<line2>call translate#run('lrange', <q-args>, '<bang>')
command! TranslateOpen call translate#open_trans_buf('')
command! TranslateClear call translate#clear_trans_buf()

nnoremap <silent> <Plug>Translate :set opfunc=translate#run<cr>g@
xnoremap <silent> <Plug>Translate :<c-u>call translate#run('visual', '', '')<cr>
nnoremap <silent> <Plug>TranslateLine :TranslateRange<cr>

nnoremap <silent> <Plug>TranslateReplace :set opfunc=translate#run_replace<cr>g@
xnoremap <silent> <Plug>TranslateReplace :<c-u>call translate#run('visual', '', '!')<cr>
nnoremap <silent> <Plug>TranslateReplaceLine :TranslateRange!<cr>
