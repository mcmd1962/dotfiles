" Vim filetype plugin file
"
"   Language :  Python
"     Plugin :  python-support.vim
" Maintainer :  Fritz Mehner <mehner@fh-swf.de>
"   Revision :  $Id: python.vim,v 1.64 2010/03/02 13:30:20 mehner Exp $
"
" ----------------------------------------------------------------------------
"
" Only do this when not done yet for this buffer
"
if exists("b:did_PYTHON_ftplugin")
  finish
endif
let b:did_PYTHON_ftplugin = 1
"
let s:UNIX  = has("unix") || has("macunix") || has("win32unix")
let s:MSWIN = has("win16") || has("win32")   || has("win64")    || has("win95")
"
" ---------- tabulator / shiftwidth ------------------------------------------
"  Set tabulator and shift width to 4 conforming to the Python Style Guide.
"  Uncomment the next two lines to force these settings for all files with
"  filetype 'python' .
"
setlocal  tabstop=3
setlocal  shiftwidth=3
"
" ---------- Add ':' to the keyword characters -------------------------------
"            Tokens like 'File::Find' are recognized as
"            one keyword
"
setlocal iskeyword+=:
"
" ---------- Do we have a mapleader other than '\' ? ------------
"
if exists("g:Python_MapLeader")
  let maplocalleader  = g:Python_MapLeader
endif
"
" ---------- Python dictionary -------------------------------------------------
" This will enable keyword completion for Python
" using Vim's dictionary feature |i_CTRL-X_CTRL-K|.
"
if exists("g:Python_Dictionary_File")
  let save=&dictionary
  silent! exe 'setlocal dictionary='.g:Python_Dictionary_File
  silent! exe 'setlocal dictionary+='.save
endif
"
" ---------- commands --------------------------------------------------
"
command! -nargs=? CriticOptions         call Python_PythonCriticOptions  (<f-args>)
command! -nargs=1 -complete=customlist,Python_PythonCriticSeverityList   CriticSeverity   call Python_PythonCriticSeverity (<f-args>)
command! -nargs=1 -complete=customlist,Python_PythonCriticVerbosityList  CriticVerbosity  call Python_PythonCriticVerbosity(<f-args>)
command! -nargs=1 RegexSubstitutions    call pythonsupportregex#Python_PythonRegexSubstitutions(<f-args>)
"
"command! -nargs=1 RegexCodeEvaluation    call Python_RegexCodeEvaluation(<f-args>)
"
command! -nargs=1 -complete=customlist,pythonsupportprofiling#Python_SmallProfSortList SmallProfSort
        \ call  pythonsupportprofiling#Python_SmallProfSortQuickfix ( <f-args> )
"
if  !s:MSWIN
  command! -nargs=1 -complete=customlist,pythonsupportprofiling#Python_FastProfSortList FastProfSort
        \ call  pythonsupportprofiling#Python_FastProfSortQuickfix ( <f-args> )
endif
"
command! -nargs=1 -complete=customlist,pythonsupportprofiling#Python_NYTProfSortList NYTProfSort
        \ call  pythonsupportprofiling#Python_NYTProfSortQuickfix ( <f-args> )
"
command! -nargs=0  NYTProfCSV call pythonsupportprofiling#Python_NYTprofReadCSV  ()
"
command! -nargs=0  NYTProfHTML call pythonsupportprofiling#Python_NYTprofReadHtml  ()
"
" ---------- Key mappings : function keys ------------------------------------
"
"   Ctrl-F9   run script
"    Alt-F9   run syntax check
"  Shift-F9   set command line arguments
"  Shift-F1   read Python documentation
" Vim (non-GUI) : shifted keys are mapped to their unshifted key !!!
"
if has("gui_running")
  "
   map    <buffer>  <silent>  <A-F9>             :call Python_SyntaxCheck()<CR>
  imap    <buffer>  <silent>  <A-F9>        <C-C>:call Python_SyntaxCheck()<CR>
  "
   map    <buffer>  <silent>  <C-F9>             :call Python_Run()<CR>
  imap    <buffer>  <silent>  <C-F9>        <C-C>:call Python_Run()<CR>
  "
   map    <buffer>  <silent>  <S-F9>             :call Python_Arguments()<CR>
  imap    <buffer>  <silent>  <S-F9>        <C-C>:call Python_Arguments()<CR>
  "
   map    <buffer>  <silent>  <S-F1>             :call Python_pythondoc()<CR><CR>
  imap    <buffer>  <silent>  <S-F1>        <C-C>:call Python_pythondoc()<CR><CR>
endif
"
"-------------------------------------------------------------------------------
"   Key mappings for menu entries
"   The mappings can be switched on and off by g:Python_NoKeyMappings
"-------------------------------------------------------------------------------
"
if !exists("g:Python_NoKeyMappings") || ( exists("g:Python_NoKeyMappings") && g:Python_NoKeyMappings!=1 )
  " ---------- plugin help -----------------------------------------------------
  "
   map    <buffer>  <silent>  <LocalLeader>hp         :call Python_HelpPythonsupport()<CR>
  imap    <buffer>  <silent>  <LocalLeader>hp    <C-C>:call Python_HelpPythonsupport()<CR>
  "
  " ----------------------------------------------------------------------------
  " Comments
  " ----------------------------------------------------------------------------
  "
  inoremap    <buffer>  <silent>  <LocalLeader>cj    <C-C>:call Python_AlignLineEndComm("a")<CR>a
  inoremap    <buffer>  <silent>  <LocalLeader>cl    <C-C>:call Python_LineEndComment("")<CR>A
  nnoremap    <buffer>  <silent>  <LocalLeader>cj         :call Python_AlignLineEndComm("a")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cl         :call Python_LineEndComment("")<CR>A
  vnoremap    <buffer>  <silent>  <LocalLeader>cj    <C-C>:call Python_AlignLineEndComm("v")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>cl    <C-C>:call Python_MultiLineEndComments()<CR>A

  nnoremap    <buffer>  <silent>  <LocalLeader>cs         :call Python_GetLineEndCommCol()<CR>

  nnoremap    <buffer>  <silent>  <LocalLeader>cfr        :call Python_InsertTemplate("comment.frame")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cfu        :call Python_InsertTemplate("comment.function")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cm         :call Python_InsertTemplate("comment.method")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>chpl       :call Python_InsertTemplate("comment.file-description-pl")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>chpm       :call Python_InsertTemplate("comment.file-description-pm")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cht        :call Python_InsertTemplate("comment.file-description-t")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>chpo       :call Python_InsertTemplate("comment.file-description-pod")<CR>

  inoremap    <buffer>  <silent>  <LocalLeader>cfr   <C-C>:call Python_InsertTemplate("comment.frame")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>cfu   <C-C>:call Python_InsertTemplate("comment.function")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>cm    <C-C>:call Python_InsertTemplate("comment.method")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>chpl  <C-C>:call Python_InsertTemplate("comment.file-description-pl")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>chpm  <C-C>:call Python_InsertTemplate("comment.file-description-pm")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>cht   <C-C>:call Python_InsertTemplate("comment.file-description-t")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>chpo  <C-C>:call Python_InsertTemplate("comment.file-description-pod")<CR>

  nnoremap    <buffer>  <silent>  <LocalLeader>ckb        $:call Python_InsertTemplate("comment.keyword-bug")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ckt        $:call Python_InsertTemplate("comment.keyword-todo")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ckr        $:call Python_InsertTemplate("comment.keyword-tricky")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ckw        $:call Python_InsertTemplate("comment.keyword-warning")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cko        $:call Python_InsertTemplate("comment.keyword-workaround")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ckn        $:call Python_InsertTemplate("comment.keyword-keyword")<CR>

  inoremap    <buffer>  <silent>  <LocalLeader>ckb   <C-C>$:call Python_InsertTemplate("comment.keyword-bug")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ckt   <C-C>$:call Python_InsertTemplate("comment.keyword-todo")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ckr   <C-C>$:call Python_InsertTemplate("comment.keyword-tricky")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ckw   <C-C>$:call Python_InsertTemplate("comment.keyword-warning")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>cko   <C-C>$:call Python_InsertTemplate("comment.keyword-workaround")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ckn   <C-C>$:call Python_InsertTemplate("comment.keyword-keyword")<CR>

  nnoremap    <buffer>  <silent>  <LocalLeader>cc         :call Python_CommentToggle()<CR>j
  vnoremap    <buffer>  <silent>  <LocalLeader>cc    <C-C>:call Python_CommentToggleRange()<CR>j

  nnoremap    <buffer>  <silent>  <LocalLeader>cd    <Esc>:call Python_InsertDateAndTime("d")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>cd    <Esc>:call Python_InsertDateAndTime("d")<CR>a
  nnoremap    <buffer>  <silent>  <LocalLeader>ct    <Esc>:call Python_InsertDateAndTime("dt")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ct    <Esc>:call Python_InsertDateAndTime("dt")<CR>a

  nnoremap    <buffer>  <silent>  <LocalLeader>cv         :call Python_CommentVimModeline()<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cb         :call Python_CommentBlock("a")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>cb    <C-C>:call Python_CommentBlock("v")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>cn         :call Python_UncommentBlock()<CR>
  "
  " ----------------------------------------------------------------------------
  " Statements
  " ----------------------------------------------------------------------------
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>sd              :call Python_InsertTemplate("statements.do-while")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sf              :call Python_InsertTemplate("statements.for")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sfe             :call Python_InsertTemplate("statements.foreach")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>si              :call Python_InsertTemplate("statements.if")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sie             :call Python_InsertTemplate("statements.if-else")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>se              :call Python_InsertTemplate("statements.else")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sei             :call Python_InsertTemplate("statements.elsif")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>su              :call Python_InsertTemplate("statements.unless")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sue             :call Python_InsertTemplate("statements.unless-else")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>st              :call Python_InsertTemplate("statements.until")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sw              :call Python_InsertTemplate("statements.while")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>s{              :call Python_InsertTemplate("statements.block")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>sb              :call Python_InsertTemplate("statements.block")<CR>

  vnoremap    <buffer>  <silent>  <LocalLeader>sd    <C-C>:call Python_InsertTemplate("statements.do-while", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sf    <C-C>:call Python_InsertTemplate("statements.for", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sfe   <C-C>:call Python_InsertTemplate("statements.foreach", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>si    <C-C>:call Python_InsertTemplate("statements.if", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sie   <C-C>:call Python_InsertTemplate("statements.if-else", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>se    <C-C>:call Python_InsertTemplate("statements.else", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sei   <C-C>:call Python_InsertTemplate("statements.elsif", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>su    <C-C>:call Python_InsertTemplate("statements.unless", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sue   <C-C>:call Python_InsertTemplate("statements.unless-else", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>st    <C-C>:call Python_InsertTemplate("statements.until", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sw    <C-C>:call Python_InsertTemplate("statements.while", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>s{    <C-C>:call Python_InsertTemplate("statements.block", "v" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>sb    <C-C>:call Python_InsertTemplate("statements.block", "v" )<CR>

  inoremap    <buffer>  <silent>  <LocalLeader>sd    <C-C>:call Python_InsertTemplate("statements.do-while")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sf    <C-C>:call Python_InsertTemplate("statements.for")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sfe   <C-C>:call Python_InsertTemplate("statements.foreach")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>si    <C-C>:call Python_InsertTemplate("statements.if")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sie   <C-C>:call Python_InsertTemplate("statements.if-else")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>se    <C-C>:call Python_InsertTemplate("statements.else")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sei   <C-C>:call Python_InsertTemplate("statements.elsif")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>su    <C-C>:call Python_InsertTemplate("statements.unless")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sue   <C-C>:call Python_InsertTemplate("statements.unless-else")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>st    <C-C>:call Python_InsertTemplate("statements.until")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>sw    <C-C>:call Python_InsertTemplate("statements.while")<CR>
  "
  " ----------------------------------------------------------------------------
  " Snippets
  " ----------------------------------------------------------------------------
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>nr    <C-C>:call Python_CodeSnippet("r")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>nw    <C-C>:call Python_CodeSnippet("w")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>nw    <C-C>:call Python_CodeSnippet("wv")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ne    <C-C>:call Python_CodeSnippet("e")<CR>
  "
  noremap    <buffer>  <silent>  <LocalLeader>ntl        :call Python_EditTemplates("local")<CR>
  noremap    <buffer>  <silent>  <LocalLeader>ntg        :call Python_EditTemplates("global")<CR>
  noremap    <buffer>  <silent>  <LocalLeader>ntr        :call Python_RereadTemplates()<CR>
  "
  " ----------------------------------------------------------------------------
  " Idioms
  " ----------------------------------------------------------------------------
  "
  "nnoremap    <buffer>  <silent>  <LocalLeader>$         :call Python_InsertTemplate("idioms.scalar")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>$=        :call Python_InsertTemplate("idioms.scalar-assign")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>$$        :call Python_InsertTemplate("idioms.scalar2")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>@         :call Python_InsertTemplate("idioms.array")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>@=        :call Python_InsertTemplate("idioms.array-assign")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>%         :call Python_InsertTemplate("idioms.hash")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>%=        :call Python_InsertTemplate("idioms.hash-assign")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>ir        :call Python_InsertTemplate("idioms.regex")<CR>
  "
  "inoremap    <buffer>  <silent>  <LocalLeader>$    <C-C>:call Python_InsertTemplate("idioms.scalar")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>$=   <C-C>:call Python_InsertTemplate("idioms.scalar-assign")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>$$   <C-C>:call Python_InsertTemplate("idioms.scalar2")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>@    <C-C>:call Python_InsertTemplate("idioms.array")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>@=   <C-C>:call Python_InsertTemplate("idioms.array-assign")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>%    <C-C>:call Python_InsertTemplate("idioms.hash")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>%=   <C-C>:call Python_InsertTemplate("idioms.hash-assign")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ir   <C-C>:call Python_InsertTemplate("idioms.regex")<CR>
  "

  nnoremap    <buffer>  <silent>  <LocalLeader>im         :call Python_InsertTemplate("idioms.match")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>is         :call Python_InsertTemplate("idioms.substitute")<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>it         :call Python_InsertTemplate("idioms.translate")<CR>
  "
  inoremap    <buffer>  <silent>  <LocalLeader>im    <C-C>:call Python_InsertTemplate("idioms.match")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>is    <C-C>:call Python_InsertTemplate("idioms.substitute")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>it    <C-C>:call Python_InsertTemplate("idioms.translate")<CR>
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>ip         :call Python_InsertTemplate("idioms.print")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ip    <C-C>:call Python_InsertTemplate("idioms.print")<CR>
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>ii         :call Python_InsertTemplate("idioms.open-input-file")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ii    <C-C>:call Python_InsertTemplate("idioms.open-input-file")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>ii    <C-C>:call Python_InsertTemplate("idioms.open-input-file", "v" )<CR>

  nnoremap    <buffer>  <silent>  <LocalLeader>io         :call Python_InsertTemplate("idioms.open-output-file")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>io    <C-C>:call Python_InsertTemplate("idioms.open-output-file")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>io    <C-C>:call Python_InsertTemplate("idioms.open-output-file", "v" )<CR>

  nnoremap    <buffer>  <silent>  <LocalLeader>ipi        :call Python_InsertTemplate("idioms.open-pipe")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ipi   <C-C>:call Python_InsertTemplate("idioms.open-pipe")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>ipi   <C-C>:call Python_InsertTemplate("idioms.open-pipe", "v" )<CR>
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>isu        :call Python_InsertTemplate("idioms.subroutine")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>isu   <C-C>:call Python_InsertTemplate("idioms.subroutine")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>isu   <C-C>:call Python_InsertTemplate("idioms.subroutine", "v")<CR>
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>ifu        :call Python_InsertTemplate("idioms.subroutine")<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ifu   <C-C>:call Python_InsertTemplate("idioms.subroutine")<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>ifu   <C-C>:call Python_InsertTemplate("idioms.subroutine", "v")<CR>
  "
  " ----------------------------------------------------------------------------
  " Regex
  " ----------------------------------------------------------------------------
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>xr        :call pythonsupportregex#Python_RegexPick( "regexp", "n" )<CR>j
  nnoremap    <buffer>  <silent>  <LocalLeader>xs        :call pythonsupportregex#Python_RegexPick( "string", "n" )<CR>j
  nnoremap    <buffer>  <silent>  <LocalLeader>xf        :call pythonsupportregex#Python_RegexPickFlag( "n" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>xr   <C-C>:call pythonsupportregex#Python_RegexPick( "regexp", "v" )<CR>'>j
  vnoremap    <buffer>  <silent>  <LocalLeader>xs   <C-C>:call pythonsupportregex#Python_RegexPick( "string", "v" )<CR>'>j
  vnoremap    <buffer>  <silent>  <LocalLeader>xf   <C-C>:call pythonsupportregex#Python_RegexPickFlag( "v" )<CR>'>j
  nnoremap    <buffer>  <silent>  <LocalLeader>xm        :call pythonsupportregex#Python_RegexVisualize( )<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>xmm       :call pythonsupportregex#Python_RegexMatchSeveral( )<CR>
  nnoremap    <buffer>  <silent>  <LocalLeader>xe        :call pythonsupportregex#Python_RegexExplain( "n" )<CR>
  vnoremap    <buffer>  <silent>  <LocalLeader>xe   <C-C>:call pythonsupportregex#Python_RegexExplain( "v" )<CR>
  "
  " ----------------------------------------------------------------------------
  " POSIX character classes
  " ----------------------------------------------------------------------------
  "
  nnoremap    <buffer>  <silent>  <LocalLeader>pa    a[:alnum:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>ph    a[:alpha:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pi    a[:ascii:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pb    a[:blank:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pc    a[:cntrl:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pd    a[:digit:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pg    a[:graph:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pl    a[:lower:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pp    a[:print:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pn    a[:punct:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>ps    a[:space:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pu    a[:upper:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>pw    a[:word:]<Esc>
  nnoremap    <buffer>  <silent>  <LocalLeader>px    a[:xdigit:]<Esc>
  "
  inoremap    <buffer>  <silent>  <LocalLeader>pa    [:alnum:]
  inoremap    <buffer>  <silent>  <LocalLeader>ph    [:alpha:]
  inoremap    <buffer>  <silent>  <LocalLeader>pi    [:ascii:]
  inoremap    <buffer>  <silent>  <LocalLeader>pb    [:blank:]
  inoremap    <buffer>  <silent>  <LocalLeader>pc    [:cntrl:]
  inoremap    <buffer>  <silent>  <LocalLeader>pd    [:digit:]
  inoremap    <buffer>  <silent>  <LocalLeader>pg    [:graph:]
  inoremap    <buffer>  <silent>  <LocalLeader>pl    [:lower:]
  inoremap    <buffer>  <silent>  <LocalLeader>pp    [:print:]
  inoremap    <buffer>  <silent>  <LocalLeader>pn    [:punct:]
  inoremap    <buffer>  <silent>  <LocalLeader>ps    [:space:]
  inoremap    <buffer>  <silent>  <LocalLeader>pu    [:upper:]
  inoremap    <buffer>  <silent>  <LocalLeader>pw    [:word:]
  inoremap    <buffer>  <silent>  <LocalLeader>px    [:xdigit:]
  "
  " ----------------------------------------------------------------------------
  " POD
  " ----------------------------------------------------------------------------
  "
   map    <buffer>  <silent>  <LocalLeader>pod         :call Python_PodCheck()<CR>
   map    <buffer>  <silent>  <LocalLeader>podh        :call Python_POD('html')<CR>
   map    <buffer>  <silent>  <LocalLeader>podm        :call Python_POD('man')<CR>
   map    <buffer>  <silent>  <LocalLeader>podt        :call Python_POD('text')<CR>
  "
  " ----------------------------------------------------------------------------
  " Profiling
  " ----------------------------------------------------------------------------
  "
   map    <buffer>  <silent>  <LocalLeader>rps         :call pythonsupportprofiling#Python_Smallprof()<CR>
   map    <buffer>  <silent>  <LocalLeader>rpf         :call pythonsupportprofiling#Python_Fastprof()<CR>
   map    <buffer>  <silent>  <LocalLeader>rpn         :call pythonsupportprofiling#Python_NYTprof()<CR>
   map    <buffer>  <silent>  <LocalLeader>rpnc        :call pythonsupportprofiling#Python_NYTprofReadCSV("read","line")<CR>
  "
  " ----------------------------------------------------------------------------
  " Run
  " ----------------------------------------------------------------------------
  "
   noremap    <buffer>  <silent>  <LocalLeader>rr         :call Python_Run()<CR>
   noremap    <buffer>  <silent>  <LocalLeader>rs         :call Python_SyntaxCheck()<CR>
   noremap    <buffer>  <silent>  <LocalLeader>ra         :call Python_Arguments()<CR>
   noremap    <buffer>  <silent>  <LocalLeader>rw         :call Python_PythonSwitches()<CR>
   noremap    <buffer>  <silent>  <LocalLeader>rm         :call Python_Make()<CR>
   noremap    <buffer>  <silent>  <LocalLeader>rma        :call Python_MakeArguments()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>rr    <C-C>:call Python_Run()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>rs    <C-C>:call Python_SyntaxCheck()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>ra    <C-C>:call Python_Arguments()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>rw    <C-C>:call Python_PythonSwitches()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>rm    <C-C>:call Python_Make()<CR>
  inoremap    <buffer>  <silent>  <LocalLeader>rma   <C-C>:call Python_MakeArguments()<CR>
  "
   noremap    <buffer>  <silent>  <LocalLeader>rd    :call Python_Debugger()<CR>
   noremap    <buffer>  <silent>    <F9>             :call Python_Debugger()<CR>
  inoremap    <buffer>  <silent>    <F9>        <C-C>:call Python_Debugger()<CR>
  "
  if s:UNIX
     noremap    <buffer>  <silent>  <LocalLeader>re         :call Python_MakeScriptExecutable()<CR>
    inoremap    <buffer>  <silent>  <LocalLeader>re    <C-C>:call Python_MakeScriptExecutable()<CR>
  endif
  "
   map    <buffer>  <silent>  <LocalLeader>rp         :call Python_pythondoc()<CR>
   map    <buffer>  <silent>  <LocalLeader>h          :call Python_pythondoc()<CR>
  "
   map    <buffer>  <silent>  <LocalLeader>ri         :call Python_pythondoc_show_module_list()<CR>
   map    <buffer>  <silent>  <LocalLeader>rg         :call Python_pythondoc_generate_module_list()<CR>
  "
   map    <buffer>  <silent>  <LocalLeader>ry         :call Python_Pythontidy("n")<CR>
  vmap    <buffer>  <silent>  <LocalLeader>ry    <C-C>:call Python_Pythontidy("v")<CR>
   "
   map    <buffer>  <silent>  <LocalLeader>rc         :call Python_Pythoncritic()<CR>
   map    <buffer>  <silent>  <LocalLeader>rt         :call Python_SaveWithTimestamp()<CR>
   map    <buffer>  <silent>  <LocalLeader>rh         :call Python_Hardcopy("n")<CR>
  vmap    <buffer>  <silent>  <LocalLeader>rh    <C-C>:call Python_Hardcopy("v")<CR>
  "
   map    <buffer>  <silent>  <LocalLeader>rk    :call Python_Settings()<CR>
  if has("gui_running") && s:UNIX
     map    <buffer>  <silent>  <LocalLeader>rx    :call Python_XtermSize()<CR>
  endif
  "
   map    <buffer>  <silent>  <LocalLeader>ro         :call Python_Toggle_Gvim_Xterm()<CR>
  imap    <buffer>  <silent>  <LocalLeader>ro    <C-C>:call Python_Toggle_Gvim_Xterm()<CR>
  "
  "
endif

" ----------------------------------------------------------------------------
"  Generate (possibly exuberant) Ctags style tags for Python sourcecode.
"  Controlled by g:Python_PythonTags, enabled by default.
" ----------------------------------------------------------------------------
"if has('python') && g:Python_PythonTags == 'enabled'
"  let g:Python_PythonTagsTempfile = tempname()
"  if getfsize( expand('%') ) > 0
"    call Python_do_tags( expand('%'), g:Python_PythonTagsTempfile )
"  endif
"endif
"
"-------------------------------------------------------------------------------
" additional mapping : {<CR> always opens a block
"-------------------------------------------------------------------------------
inoremap    <buffer>  {<CR>  {<CR>}<Esc>O
vnoremap    <buffer>  {<CR> s{<CR>}<Esc>kp=iB
"
if !exists("g:Python_Ctrl_j") || ( exists("g:Python_Ctrl_j") && g:Python_Ctrl_j != 'off' )
  nmap    <buffer>  <silent>  <C-j>    i<C-R>=Python_JumpCtrlJ()<CR>
  imap    <buffer>  <silent>  <C-j>     <C-R>=Python_JumpCtrlJ()<CR>
endif
" ----------------------------------------------------------------------------
