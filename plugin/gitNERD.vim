" Author: Marcel Simader (marcel0simader@gmail.com)
" Date: 17.11.2022
" (c) Marcel Simader 2022

" load-guard
" if exists('g:gitNERD_did_plugin')
"     finish
" endif
" let g:gitNERD_did_plugin = 1
" TODO: uncomment this and remove the '!' from each function

function! s:Config(name, Default)
    try
        if exists('g:'.a:name) | return | endif
        let g:{a:name} = a:Default()
    catch
        echohl ErrorMsg
        echomsg 'Error while processing GitNERD config "'.a:name.'"'
        echohl None
    endtry
endfunction

call s:Config('gitNERD_enabled', {-> 1})
if !g:gitNERD_enabled | finish | endif
call s:Config('gitNERD_render_throttle_ms', {-> 35})
call s:Config('gitNERD_delimiters', {-> ['[', ']']})
call s:Config('gitNERD_status_flags', {-> ['--ignored', '--find-renames=5']})

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~ NERDTree API ~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

call g:NERDTreePathNotifier.AddListener("init", "gitNERD#Init")
call g:NERDTreePathNotifier.AddListener("refresh", "gitNERD#Refresh")

" Sets up the 'displayString' function for each NERDTree node.
function! gitNERD#Init(event)
    const subject  = a:event['subject']
    const nerdtree = a:event['nerdtree']
    call s:PrepareNode(subject, nerdtree)
endfunction

" Marks nodes as stale when refreshed.
function! gitNERD#Refresh(event)
    const subject = a:event['subject']
    const nerdtree = a:event['nerdtree']
    " mark as stale right away, so we don't accidentally leave nodes that should be stale
    " already around in some circumstances
    if has_key(subject, 'gitStatusStale')
        let subject.gitStatusStale = 1
    endif
    call s:PrepareNode(subject, nerdtree)
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~ GitNERD API ~~~~~~~~~~~~~~~~~~~~
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Prepare a NERDTree node so it can have a Git status indicator.
function! s:PrepareNode(node, nerdtree)
    " only move on if the nerdtree root is a git repository
    if !s:ContinueProcessingEvent(a:nerdtree, a:node) | return | endif
    " save old function so we can do a super-call
    " conveniently we can also use this to check if we processed this node already
    if has_key(a:node, '__displayString') | return | endif
    let a:node.__displayString = a:node.displayString
    " replace with our new edited function
    function! a:node.displayString() closure
        " check if we are in a cascade
        if has_key(a:nerdtree, 'root') && has_key(a:nerdtree.root, 'findNode')
            const parentdir = has_key(self, 'getParent') ?
                            \ a:nerdtree.root.findNode(self.getParent())
                        \ : has_key(self, 'parent') ?
                            \ a:nerdtree.root.findNode(self.parent)
                        \ : {}
            if has_key(parentdir, 'isCascadable') && parentdir.isCascadable()
                return self.__displayString()
            endif
        endif
        " if NOT we can compute and display the status
        call s:ComputeGitStatusFor(self, a:nerdtree)
        return get(self, 'gitStatus', s:WrapStatus('  ')).' '.self.__displayString()
    endfunction
endfunction

" Computes and sets the git status for 'node' in 'nerdtree'. If the status is marked as
" stale, this starts a new job with callback, otherwise the node is left as-is.
function! s:ComputeGitStatusFor(node, nerdtree)
    if s:IsStatusStale(a:node) | return | endif
    const pathspec = a:node.str()
    call gitNERD#ComputeGitStatus(
                \ pathspec,
                \ {s -> s:UpdateGitStatusFor(a:node, a:nerdtree, s)},
                \ g:gitNERD_status_flags
                \ )
endfunction

" Sets 'status' on 'node' and re-renders 'nerdtree'
function! s:UpdateGitStatusFor(node, nerdtree, status)
    const statusInd = s:WrapStatus(substitute(a:status, '\.', ' ', 'g'))
    let a:node.gitStatus      = statusInd
    let a:node.gitStatusStale = 0
    call s:RedrawNERDTree(a:nerdtree)
endfunction

" ~~~~~~~~~~~~~~~~~~~~ Helper Methods ~~~~~~~~~~~~~~~~~~~~

" Throttled redrawing of the currently open NERDTree.
function! s:RedrawNERDTree(nerdtree, throttle = g:gitNERD_render_throttle_ms)
    if exists('g:gitNERDtimer') | return | endif
    " we have no scheduled execution, start a new one
    let g:gitNERDtimer = timer_start(a:throttle, {_ -> s:_RedrawNERDTree(a:nerdtree)})
endfunction

" Redraws the currently open NERDTree and marks the action as completed.
function! s:_RedrawNERDTree(nerdtree)
    if !a:nerdtree.IsOpen() | return | endif
    " remember window we were from, jump to NERDTree and render, jump back
    const [curwinnr, curview] = [win_getid(), winsaveview()]
    call a:nerdtree.CursorToTreeWin()
    call a:nerdtree.render()
    call win_gotoid(curwinnr)
    call winrestview(curview)
    " mark as completed
    unlet g:gitNERDtimer
endfunction

" Returns whether or not a 'node' has a stale git status.
function! s:IsStatusStale(node)
    return has_key(a:node, 'gitStatus')
                \ && has_key(a:node, 'gitStatusStale')
                \ && !a:node['gitStatusStale']
endfunction

function! s:WrapStatus(status)
    return get(g:gitNERD_delimiters, 0, '').a:status.get(g:gitNERD_delimiters, 1, '')
endfunction

" Whether or not we should continue processing a NERDTree event.
function! s:ContinueProcessingEvent(nerdtree, node)
    return s:IsNERDTreeInRepo(a:nerdtree) && s:IsValidNERDTreePath(a:node)
endfunction

" Convenience function for checking if we should proceed to handle an event.
function! s:IsNERDTreeInRepo(nerdtree)
    return has_key(a:nerdtree, 'root')
                \ && has_key(a:nerdtree.root, 'path')
                \ && gitNERD#IsInsideGitRepo(a:nerdtree.root.path.str())
endfunction

" Make sure the path we are pursuing is not inside '.git'. We don't need or want that...
function! s:IsValidNERDTreePath(node)
    return has_key(a:node, 'pathSegments')
                \ && index(a:node.pathSegments, '.git') == -1
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

