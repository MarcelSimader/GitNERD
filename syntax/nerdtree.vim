" Author: Marcel Simader (marcel0simader@gmail.com)
" Date: 21.11.2022
" (c) Marcel Simader 2022

syn match GitNERDStatusNone      #\s*\[..\=\]#
syn match GitNERDStatusUntracked #\s*\[??\=\]#
syn match GitNERDStatusIgnored   #\s*\[!!\=\]#
"
syn match GitNERDStatusAdded     #\s*\[\(.A\|A.\)\]#
syn match GitNERDStatusModified  #\s*\[\(.[MT]\|[MT].\)\]#
syn match GitNERDStatusDeleted   #\s*\[\(.D\|D.\)\]#
syn match GitNERDStatusRenamed   #\s*\[\(.R\|R.\)\]#

hi def GitNERDStatusNone      ctermfg=DarkGray ctermbg=NONE
hi def GitNERDStatusUntracked ctermfg=DarkGray ctermbg=NONE
hi def GitNERDStatusIgnored   ctermfg=DarkRed  ctermbg=NONE
"
hi def GitNERDStatusAdded     ctermfg=Green    ctermbg=NONE
hi def GitNERDStatusModified  ctermfg=Green    ctermbg=NONE
hi def GitNERDStatusDeleted   ctermfg=Red      ctermbg=NONE
hi def GitNERDStatusRenamed   ctermfg=Blue     ctermbg=NONE

