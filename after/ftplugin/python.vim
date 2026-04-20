setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal textwidth=88
setlocal colorcolumn=88

if has('python3')
  setlocal omnifunc=python3complete#Complete
else
  setlocal omnifunc=syntaxcomplete#Complete
endif
let b:ivim_complete_triggers = ['.']
