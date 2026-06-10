setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = []

" Revert setlocal options and clear iVim buffer state on filetype change.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal ts< sw< sts< et< ofu<|unlet! b:ivim_complete_triggers'
