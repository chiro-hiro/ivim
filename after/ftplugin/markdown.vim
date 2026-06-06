setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal wrap
setlocal linebreak

" wrap/linebreak are window-local and Vim does not auto-restore them when a
" different-filetype buffer is loaded into this window, so they would leak the
" soft-wrap into the next (e.g. code) buffer. Restore the global defaults when
" this buffer's filetype is undone.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal wrap< linebreak<'

let b:ivim_autocomplete_disable = 1
