setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal cinoptions=l1,g0,:0

setlocal omnifunc=ccomplete#Complete
let b:ivim_complete_triggers = ['.', '->']

" Revert setlocal options and clear iVim buffer state on filetype change so
" they don't leak into the next filetype loaded in this buffer.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal ts< sw< sts< et< cino< ofu<|unlet! b:ivim_complete_triggers'
