setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=csscomplete#CompleteCSS
let b:ivim_complete_triggers = [':']

" Revert setlocal options and clear iVim buffer state on filetype change.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal ts< sw< sts< et< ofu<|unlet! b:ivim_complete_triggers'
