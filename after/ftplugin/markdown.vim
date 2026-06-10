setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal wrap
setlocal linebreak

let b:ivim_autocomplete_disable = 1

" wrap/linebreak are window-local and Vim does not auto-restore them when a
" different-filetype buffer is loaded into this window, so they would leak the
" soft-wrap into the next (e.g. code) buffer. Revert the setlocal options and
" clear the iVim disable flag (otherwise autocomplete stays off in the next
" filetype loaded here) when this buffer's filetype is undone.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal ts< sw< sts< et< wrap< linebreak<|unlet! b:ivim_autocomplete_disable'
