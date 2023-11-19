" Author: Marcel Simader (marcel0simader@gmail.com)
" Date: 21.11.2022
" (c) Marcel Simader 2022

syn match GitNERDStatusNone /\[..\=\]/
            \ containedin=NERDTreeDir,NERDTreeFile
            \ contains=@GitNERD

syn cluster GitNERD contains=GitNERDStatusUntracked,GitNERDStatusIgnored,
            \ GitNERDStatusAdded,GitNERDStatusModified,GitNERDStatusDeleted,
            \ GitNERDStatusRenamed, GitNERDStatusSubmodule, GitNERDStatusUnmerged,
            \ GitNERDStatusImportant

syn match GitNERDStatusUntracked /\[??\=\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusIgnored   /\[!!\=\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusAdded     /\[\(.A\|A.\)\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusModified  /\[\(.[MT]\|[MT].\)\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusDeleted   /\[\(.D\|D.\)\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusRenamed   /\[\(.R\|R.\)\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusSubmodule /\[S\(.\|S\)\]/ms=s+1,me=e-1
            \ containedin=NERDTreeDir,NERDTreeFile
syn match GitNERDStatusUnmerged /\[\(DD\|AU\|UD\|UA\|DU\|AA\|UU\)\]/ms=s+1,me=e-1
            \ containedin=GitNERDStatusImportant,NERDTreeDir,NERDTreeFile
syn match GitNERDStatusImportant /\[\(DD\|AU\|UD\|UA\|DU\|AA\|UU\)\]/
            \ containedin=NERDTreeDir,NERDTreeFile

hi def GitNERDStatusNone      ctermfg=Black      ctermbg=NONE
hi def GitNERDStatusUntracked ctermfg=DarkGray   ctermbg=NONE
hi def GitNERDStatusIgnored   ctermfg=DarkGray   ctermbg=NONE
hi def GitNERDStatusAdded     ctermfg=Cyan       ctermbg=NONE
hi def GitNERDStatusModified  ctermfg=Green      ctermbg=NONE
hi def GitNERDStatusDeleted   ctermfg=Red        ctermbg=NONE
hi def GitNERDStatusRenamed   ctermfg=Blue       ctermbg=NONE
hi def GitNERDStatusSubmodule ctermfg=DarkYellow ctermbg=NONE
hi def GitNERDStatusUnmerged  ctermfg=LightBlue  ctermbg=NONE
hi def GitNERDStatusImportant ctermfg=Grey       ctermbg=NONE cterm=UNDERLINE

