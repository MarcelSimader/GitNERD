" Author: Marcel Simader (marcel0simader@gmail.com)
" Date: 17.11.2022
" (c) Marcel Simader 2022

" load-guard
" if exists('g:gitNERD_did_plugin')
"     finish
" endif
" let g:gitNERD_did_plugin = 1
" TODO: uncomment this and remove the '!' from each function

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~ NERDTree API ~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

call g:NERDTreePathNotifier.AddListener("init", "gitNERD#Init")
call g:NERDTreePathNotifier.AddListener("refresh", "gitNERD#Refresh")

" Sets up the 'displayString' function for each NERDTree node.
function! gitNERD#Init(event)
    const subject  = a:event['subject']
    const nerdtree = a:event['nerdtree']
    " only move on if the nerdtree root is a git repository
    if !s:IsNERDTreeInRepo(nerdtree) | return | endif
    " save old function so we can do a super-call
    if !has_key(subject, '__displayString')
        let subject.__displayString = subject.displayString
    endif
    " replace with our new edited function
    function! subject.displayString() closure
        call s:ComputeGitStatusFor(self, nerdtree)
        return get(self, 'gitStatus', '[  ]').' '.self.__displayString()
    endfunction
endfunction

" Marks nodes as stale when refreshed.
function! gitNERD#Refresh(event)
    const subject = a:event['subject']
    const nerdtree = a:event['nerdtree']
    " only move on if the nerdtree root is a git repository
    if !s:IsNERDTreeInRepo(nerdtree) | return | endif
    " mark as stale
    let subject.gitStatusStale = 1
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~ GitNERD API ~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function! s:IsNERDTreeInRepo(nerdtree)
    return has_key(a:nerdtree, 'root')
                \ && has_key(a:nerdtree.root, 'path')
                \ && gitNERD#IsInsideGitRepo(a:nerdtree.root.path.str())
endfunction

" Computes and sets the git status for 'node' in 'nerdtree'. If the status is marked as
" stale, this starts a new job with callback, otherwise the node is left as-is.
function! s:ComputeGitStatusFor(node, nerdtree)
    if s:IsStatusStale(a:node) | return | endif
    const pathspec = a:node.str()
    call gitNERD#ComputeGitStatus(
                \ pathspec,
                \ {s -> s:UpdateGitStatusFor(a:node, a:nerdtree, s)},
                \ )
endfunction

" Sets 'status' on 'node' and re-renders 'nerdtree'
function! s:UpdateGitStatusFor(node, nerdtree, status)
    const statusInd = '['.substitute(a:status, '\.', ' ', 'g').']'
    let a:node.gitStatus      = statusInd
    let a:node.gitStatusStale = 0
    " remember window we were from, jump to NERDTree and render, jump back
    const [curwinnr, curview] = [win_getid(), winsaveview()]
    call a:nerdtree.CursorToTreeWin()
    call a:nerdtree.render()
    call win_gotoid(curwinnr)
    call winrestview(curview)
endfunction

" Returns whether or not a 'node' has a stale git status.
function! s:IsStatusStale(node)
    return has_key(a:node, 'gitStatus')
                \ && has_key(a:node, 'gitStatusStale')
                \ && !a:node['gitStatusStale']
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~ Git Stuff ~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Returns whether the given directory is inside a Git repository or not.
function! gitNERD#IsInsideGitRepo(dir)
    const rootdir = finddir('.git', fnamemodify(a:dir, ':p').';')
    return strlen(rootdir) > 0
endfunction

" Computes a git status string (see s:GitStatusMessageToStr) and returns it in a callback,
" using asynchronous jobs.
" Arguments:
"   pathspec, see 'git status --help'
"   Callback, a function that is called with the result as only argument
"   [arguments,] a list of extra arguments to pass to Git
" Returns:
"   the job object
function! gitNERD#ComputeGitStatus(pathspec, Callback, arguments = [])
    const Callback = a:Callback
    const args = ['git', 'status', a:pathspec, '--porcelain=v2'] + a:arguments
    const opts = {'out_cb': {_, msg -> Callback(s:GitStatusMessageToStr(msg))},
                \ 'timeout': 50}
    let g:gitNERDjob = job_start(args, opts)
    return g:gitNERDjob
endfunction

" Takes a git status message in Porcelain v2 format and returns a str like 'AM', or '??'.
" Arguments:
"   message, the message to parse
" Returns:
"   a string of length 2
function! s:GitStatusMessageToStr(message)
    const output = split(a:message, ' ')
    if len(output) < 2
        " path is unknown in some way
        return '  '
    else
        " path is known and we have one of the 3 defined formats
        const [ind, xy; rest] = output
        if ind == '?'
            " untracked
            return '??'
        elseif ind == '!'
            " ignored
            return '!!'
        elseif ind == '1' || ind == '2' || ind == 'u'
            " other
            return xy
        else
            " error?
            return '##'
        end
    endif
endfunction

