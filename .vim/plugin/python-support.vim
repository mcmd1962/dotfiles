"#################################################################################
"
"       Filename:  python-support.vim
"
"    Description:  python-support.vim implements a Python-IDE for Vim/gVim.  It is
"                  written to considerably speed up writing code in a consistent
"                  style.
"                  This is done by inserting complete statements, comments,
"                  idioms, code snippets, templates, comments and POD
"                  documentation.  Reading pythondoc is integrated.  Syntax
"                  checking, running a script, starting a debugger and a
"                  profiler can be done by a keystroke.
"                  There a many additional hints and options which can improve
"                  speed and comfort when writing Python. Please read the
"                  documentation.
"
"  Configuration:  There are at least some personal details which should be 
"  									configured (see the files README.pythonsupport and
"  									pythonsupport.txt).
"
"   Dependencies:  python           pod2man
"                  podchecker     pod2text
"                  pod2html       pythondoc
"
"                  optional:
"
"                  ddd                  (debugger frontend)
"                  Devel::ptkdb         (debugger frontend)
"                  Devel::SmallProf     (profiler)
"                  Devel::FastProf      (profiler)
"                  Devel::NYTProf       (profiler)
"                  sort(1)              (rearrange profiler statistics)
"                  Python::Critic         (stylechecker)
"                  Python::Tags           (generate Ctags style tags)
"                  Python::Tidy           (beautifier)
"                  Pod::Pdf             (Pod to Pdf conversion)
"                  YAPE::Regex::Explain (regular expression analyzer)
"
"         Author:  Dr.-Ing. Fritz Mehner <mehner@fh-swf.de>
"
"        Version:  see variable  g:Python_Version  below
"        Created:  09.07.2001
"        License:  Copyright (c) 2001-2010, Fritz Mehner
"                  This program is free software; you can redistribute it
"                  and/or modify it under the terms of the GNU General Public
"                  License as published by the Free Software Foundation,
"                  version 2 of the License.
"                  This program is distributed in the hope that it will be
"                  useful, but WITHOUT ANY WARRANTY; without even the implied
"                  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
"                  PURPOSE.
"                  See the GNU General Public License version 2 for more details.
"        Credits:  see pythonsupport.txt
"       Revision:  $Id: python-support.vim,v 1.100 2010/03/02 13:33:19 mehner Exp $
"-------------------------------------------------------------------------------
"
" Prevent duplicate loading:
"
if exists("g:Python_Version") || &compatible
  finish
endif

if v:version < 700
  echohl WarningMsg | echo 'plugin python-support.vim needs Vim version >= 7'| echohl None
  finish
endif

let g:Python_Version= "4.6.2"
"
"#################################################################################
"
"  Global variables (with default values) which can be overridden.
"
"------------------------------------------------------------------------------
"  Define a global variable and assign a default value if nor already defined.
"------------------------------------------------------------------------------
function! PythonSetGlobalVariable ( name, default )
  if !exists('g:'.a:name)
    exe 'let g:'.a:name."  = '".a:default."'"
  endif
endfunction   " ---------- end of function  PythonSetGlobalVariable  ----------
"
"------------------------------------------------------------------------------
"  Assign a value to a local variable if a corresponding global variable
"  exists.
"------------------------------------------------------------------------------
function! PythonSetLocalVariable ( name )
  if exists('g:'.a:name)
    exe 'let s:'.a:name.'  = g:'.a:name
  endif
endfunction   " ---------- end of function  PythonSetLocalVariable  ----------
"
"
call PythonSetGlobalVariable( "Python_MenuHeader",'yes' )
call PythonSetGlobalVariable( "Python_OutputGvim",'vim' )
call PythonSetGlobalVariable( "Python_PythonRegexSubstitution",'$~' )
call PythonSetGlobalVariable( "Python_Root",'&Python.' )
"
"------------------------------------------------------------------------------
"
" Platform specific items:
" - plugin directory
" - characters that must be escaped for filenames
"
let s:MSWIN = has("win16") || has("win32")   || has("win64")    || has("win95")
let s:UNIX	= has("unix")  || has("macunix") || has("win32unix")
"
if  s:MSWIN
  " ==========  MS Windows  ======================================================
  let s:plugin_dir  	= $VIM.'\vimfiles\'
  let s:esc_chars 	  = ''
	call PythonSetGlobalVariable( 'Python_CodeSnippets', s:plugin_dir.'python-support/codesnippets/' )
  "
	let s:Python_Display  = ''
	let s:installation	= 'system'
	let s:Python_root_dir	= s:plugin_dir
	"
else
  "
  " ==========  Linux/Unix  ======================================================
	"
	" user / system wide installation
	"
	let s:installation	= 'local'
	if match( expand("<sfile>"), $VIM ) >= 0
		" system wide installation
		let s:plugin_dir  	= $VIM.'/vimfiles/'
		let s:installation	= 'system'
	else
		" user installation assumed
		let s:plugin_dir  	= $HOME.'/.vim/'
	endif

	" user defined python-support directories
  if exists("g:Python_Support_Root_Dir")
		let s:plugin_dir  	= g:Python_Support_Root_Dir.'/'
		let s:Python_root_dir	= g:Python_Support_Root_Dir
  else
		let s:Python_root_dir	= $HOME.'/.vim'
  endif

	"
	let s:esc_chars   = ' \%#[]'
  "
	call PythonSetGlobalVariable( 'Python_CodeSnippets', s:Python_root_dir.'/python-support/codesnippets/' )
	"
	let s:Python_Display	= expand("$DISPLAY")
	"
endif
"
let g:Python_PluginDir	= s:plugin_dir        " used for communication with ftplugin/python.vim
"
call PythonSetGlobalVariable( 'Python_PythonTags', 'enabled' )
"
"  Key word completion is enabled by the filetype plugin 'python.vim'
"  g:Python_Dictionary_File  must be global
"
if !exists("g:Python_Dictionary_File")
  let g:Python_Dictionary_File       = s:plugin_dir.'python-support/wordlists/python.list'
endif
"
let g:Python_PythonTagsTempfile	= ''
"
"  Modul global variables (with default values) which can be overridden.     {{{1
"
let s:Python_LoadMenus             = 'yes'
let s:Python_GlobalTemplateFile    = s:plugin_dir.'python-support/templates/Templates'
let s:Python_GlobalTemplateDir     = fnamemodify( s:Python_GlobalTemplateFile, ":p:h" ).'/'
let s:Python_LocalTemplateFile     = s:Python_root_dir.'/python-support/templates/Templates'
let s:Python_LocalTemplateDir      = fnamemodify( s:Python_LocalTemplateFile, ":p:h" ).'/'
let s:Python_TemplateOverwrittenMsg= 'yes'
let s:Python_Ctrl_j								 = 'on'
"
let s:Python_FormatDate						 = '%Y%m%d'
let s:Python_FormatTime						 = '%H:%M'
let s:Python_FormatYear						 = '%Y'
let s:Python_TimestampFormat       = '%Y%m%d.%H%M%S'

let s:Python_Template_Directory    = s:plugin_dir.'python-support/templates/'
let s:Python_PythonModuleList        = s:plugin_dir.'python-support/modules/python-modules.list'
let s:Python_XtermDefaults         = "-fa courier -fs 12 -geometry 80x24"
let s:Python_Debugger              = "python"
let s:Python_ProfilerTimestamp     = "no"
let s:Python_LineEndCommColDefault = 49
let s:Python_PodcheckerWarnings    = "yes"
let s:Python_PythoncriticOptions     = ""
let s:Python_PythoncriticSeverity    = 3
let s:Python_PythoncriticVerbosity   = 5
let s:Python_Printheader           = "%<%f%h%m%<  %=%{strftime('%x %X')}     Page %N"
let s:Python_GuiSnippetBrowser     = 'gui'										" gui / commandline
let s:Python_GuiTemplateBrowser    = 'gui'										" gui / explorer / commandline
"
let s:Python_Wrapper                 = s:plugin_dir.'python-support/scripts/wrapper.sh'
let s:Python_EfmPython                 = s:plugin_dir.'python-support/scripts/efm_python.py'
let s:Python_PythonModuleListGenerator = s:plugin_dir.'python-support/scripts/pmdesc3.py'
"
"------------------------------------------------------------------------------
"
"  Look for global variables (if any), to override the defaults.
"
call PythonSetLocalVariable('Python_GuiSnippetBrowser      ')
call PythonSetLocalVariable('Python_GuiTemplateBrowser     ')
call PythonSetLocalVariable("Python_Ctrl_j                 ")
call PythonSetLocalVariable("Python_Debugger               ")
call PythonSetLocalVariable("Python_FormatDate             ")
call PythonSetLocalVariable("Python_FormatTime             ")
call PythonSetLocalVariable("Python_FormatYear             ")
call PythonSetLocalVariable("Python_TimestampFormat        ")
call PythonSetLocalVariable("Python_LineEndCommColDefault  ")
call PythonSetLocalVariable("Python_LoadMenus              ")
call PythonSetLocalVariable("Python_NYTProf_browser        ")
call PythonSetLocalVariable("Python_NYTProf_html           ")
call PythonSetLocalVariable("Python_PythoncriticOptions      ")
call PythonSetLocalVariable("Python_PythoncriticSeverity     ")
call PythonSetLocalVariable("Python_PythoncriticVerbosity    ")
call PythonSetLocalVariable("Python_PythonModuleList         ")
call PythonSetLocalVariable("Python_PythonModuleListGenerator")
call PythonSetLocalVariable("Python_PodcheckerWarnings     ")
call PythonSetLocalVariable("Python_Printheader            ")
call PythonSetLocalVariable("Python_ProfilerTimestamp      ")
call PythonSetLocalVariable("Python_Template_Directory     ")
call PythonSetLocalVariable("Python_TemplateOverwrittenMsg ")
call PythonSetLocalVariable("Python_XtermDefaults          ")
"
"
" set default geometry if not specified
"
if match( s:Python_XtermDefaults, "-geometry\\s\\+\\d\\+x\\d\\+" ) < 0
  let s:Python_XtermDefaults  = s:Python_XtermDefaults." -geometry 80x24"
endif
"
" Flags for pythondoc
"
if has("gui_running")
  let s:Python_pythondoc_flags  = ""
else
  " Display docs using plain text converter.
  let s:Python_pythondoc_flags  = "-otext"
endif
"
" escape the printheader
"
let s:Python_Printheader  		= escape( s:Python_Printheader, ' %' )
let s:Python_InterfaceVersion = ''
"
"------------------------------------------------------------------------------
"  Control variables (not user configurable)
"------------------------------------------------------------------------------
let s:InsertionAttribute       = { 'below':'', 'above':'', 'start':'', 'append':'', 'insert':'' }
let s:IndentAttribute          = { 'noindent':'', 'indent':'' }
let s:Python_InsertionAttribute  = {}
let s:Python_IndentAttribute     = {}
let s:Python_ExpansionLimit      = 10
let s:Python_FileVisited         = []
"
let s:Python_MacroNameRegex        = '\([a-zA-Z][a-zA-Z0-9_]*\)'
let s:Python_MacroLineRegex				 = '^\s*|'.s:Python_MacroNameRegex.'|\s*=\s*\(.*\)'
let s:Python_MacroCommentRegex		 = '^§'
let s:Python_ExpansionRegex				 = '|?'.s:Python_MacroNameRegex.'\(:\a\)\?|'
let s:Python_NonExpansionRegex		 = '|'.s:Python_MacroNameRegex.'\(:\a\)\?|'
"
let s:Python_TemplateNameDelimiter = '-+_,\. '
"let s:Python_TemplateLineRegex		 = '^==\s*\([a-zA-Z][0-9a-zA-Z'.s:Python_TemplateNameDelimiter
"let s:Python_TemplateLineRegex		.= ']\+\)\s*==\s*\([a-z]\+\s*==\)\?'
let s:Python_TemplateLineRegex		 = '^==\s*\([a-zA-Z][0-9a-zA-Z'.s:Python_TemplateNameDelimiter
let s:Python_TemplateLineRegex		.= ']\+\)\s*==\(\s*[a-z]\+\s*==\)*'
let s:Python_TemplateIf						 = '^==\s*IF\s\+|STYLE|\s\+IS\s\+'.s:Python_MacroNameRegex.'\s*=='
let s:Python_TemplateEndif				 = '^==\s*ENDIF\s*=='
"
let s:Python_ExpansionCounter     = {}
let s:Python_TJT									= '[ 0-9a-zA-Z_]*'
let s:Python_TemplateJumpTarget1  = '<+'.s:Python_TJT.'+>\|{+'.s:Python_TJT.'+}'
let s:Python_TemplateJumpTarget2  = '<-'.s:Python_TJT.'->\|{-'.s:Python_TJT.'-}'
let s:Python_Template             = {}
let s:Python_Macro                = {'|AUTHOR|'         : 'first name surname',
											\						 '|AUTHORREF|'      : '',
											\						 '|EMAIL|'          : '',
											\						 '|COMPANY|'        : '',
											\						 '|PROJECT|'        : '',
											\						 '|COPYRIGHTHOLDER|': '',
											\		 				 '|STYLE|'          : ''
											\						}
let	s:Python_MacroFlag						= {	':l' : 'lowercase'			,
											\							':u' : 'uppercase'			,
											\							':c' : 'capitalize'		,
											\							':L' : 'legalize name'	,
											\						}

let s:MsgInsNotAvail	= "insertion not available for a fold"
"
"------------------------------------------------------------------------------
"-----   variables for internal use   -----------------------------------------
"------------------------------------------------------------------------------
"
"------------------------------------------------------------------------------
"  Input after a highlighted prompt     {{{1
"------------------------------------------------------------------------------
function! Python_Input ( promp, text, ... )
	echohl Search																					" highlight prompt
	call inputsave()																			" preserve typeahead
	if a:0 == 0 || a:1 == ''
		let retval	=input( a:promp, a:text )
	else
		let retval	=input( a:promp, a:text, a:1 )
	endif
	call inputrestore()																		" restore typeahead
	echohl None																						" reset highlighting
	let retval  = substitute( retval, '^\s\+', "", "" )		" remove leading whitespaces
	let retval  = substitute( retval, '\s\+$', "", "" )		" remove trailing whitespaces
	return retval
endfunction    " ----------  end of function Python_Input ----------
"
"------------------------------------------------------------------------------
"  Comments : get line-end comment position     {{{1
"------------------------------------------------------------------------------
function! Python_GetLineEndCommCol ()
  let actcol  = virtcol(".")
  if actcol+1 == virtcol("$")
    let b:Python_LineEndCommentColumn = ''
		while match( b:Python_LineEndCommentColumn, '^\s*\d\+\s*$' ) < 0
			let b:Python_LineEndCommentColumn = Python_Input( 'start line-end comment at virtual column : ', actcol, '' )
		endwhile
  else
    let b:Python_LineEndCommentColumn = virtcol(".")
  endif
  echomsg "line end comments will start at column  ".b:Python_LineEndCommentColumn
endfunction   " ---------- end of function  Python_GetLineEndCommCol  ----------
"
"------------------------------------------------------------------------------
"  Comments : single line-end comment     {{{1
"------------------------------------------------------------------------------
function! Python_LineEndComment ( comment )
  if !exists("b:Python_LineEndCommentColumn")
    let b:Python_LineEndCommentColumn = s:Python_LineEndCommColDefault
  endif
  " ----- trim whitespaces -----
	exe 's/\s*$//'
  let linelength= virtcol("$") - 1
  if linelength < b:Python_LineEndCommentColumn
    let diff  = b:Python_LineEndCommentColumn -1 -linelength
    exe "normal ".diff."A "
  endif
  " append at least one blank
  if linelength >= b:Python_LineEndCommentColumn
    exe "normal A "
  endif
  exe "normal A# ".a:comment
endfunction   " ---------- end of function  Python_LineEndComment  ----------
"
"------------------------------------------------------------------------------
"  Python_AlignLineEndComm: adjust line-end comments     {{{1
"------------------------------------------------------------------------------
"
" patterns to ignore when adjusting line-end comments (incomplete):
" some heuristics used (only Python can parse Python)
let	s:AlignRegex	= [
	\	'\$#' ,
	\	'"[^"]\+"' ,
	\	"'[^']\\+'" ,
	\	"`[^`]\+`" ,
	\	'\(m\|qr\)#[^#]\+#' ,
	\	'\(m\|qr\)\?\([\?\/]\)\(.*\)\(\2\)\([imsxg]*\)'  ,
	\	'\(m\|qr\)\([[:punct:]]\)\(.*\)\(\2\)\([imsxg]*\)'  ,
	\	'\(m\|qr\){\(.*\)}\([imsxg]*\)'  ,
	\	'\(m\|qr\)(\(.*\))\([imsxg]*\)'  ,
	\	'\(m\|qr\)\[\(.*\)\]\([imsxg]*\)'  ,
	\	'\(s\|tr\)#[^#]\+#[^#]\+#' ,
	\	'\(s\|tr\){[^}]\+}{[^}]\+}' ,
	\	]

function! Python_AlignLineEndComm ( mode ) range
	"
	if !exists("b:Python_LineEndCommentColumn")
		let	b:Python_LineEndCommentColumn	= s:Python_LineEndCommColDefault
	endif

	let save_cursor = getpos(".")

	let	save_expandtab	= &expandtab
	exe	":set expandtab"

	if a:mode == 'v'
		let pos0	= line("'<")
		let pos1	= line("'>")
	else
		let pos0	= line(".")
		let pos1	= pos0
	endif

	let	linenumber	= pos0
	exe ":".pos0

	while linenumber <= pos1
		let	line= getline(".")
		"
		" line is not a pure comment but may contains a comment:
		"
		if match( line, '^\s*#' ) < 0 && match( line, '#.*$' ) > 0
      "
      " disregard comments starting in a string
      "
			let	idx1	      = -1
			let	idx2	      = -1
			let	commentstart= -2
			let	commentend	= 0
			while commentstart < idx2 && idx2 < commentend
				let start	      = commentend
				let idx2	      = match( line, '#.*$', start )
				" loop over the items to ignore
        for regex in s:AlignRegex
          if match( line, regex ) > -1
            let commentstart	= match   ( line, regex, start )
            let commentend		= matchend( line, regex, start )
            break
          endif
        endfor
			endwhile
      "
      " try to adjust the comment
      "
			let idx1	= 1 + match( line, '\s*#.*$', start )
			let idx2	= 1 + idx2
			call setpos(".", [ 0, linenumber, idx1, 0 ] )
			let vpos1	= virtcol(".")
			call setpos(".", [ 0, linenumber, idx2, 0 ] )
			let vpos2	= virtcol(".")

			if   ! (   vpos2 == b:Python_LineEndCommentColumn
						\	|| vpos1 > b:Python_LineEndCommentColumn
						\	|| idx2  == 0 )

				exe ":.,.retab"
				" insert some spaces
				if vpos2 < b:Python_LineEndCommentColumn
					let	diff	= b:Python_LineEndCommentColumn-vpos2
					call setpos(".", [ 0, linenumber, vpos2, 0 ] )
					let	@"	= ' '
					exe "normal	".diff."P"
				endif

				" remove some spaces
				if vpos1 < b:Python_LineEndCommentColumn && vpos2 > b:Python_LineEndCommentColumn
					let	diff	= vpos2 - b:Python_LineEndCommentColumn
					call setpos(".", [ 0, linenumber, b:Python_LineEndCommentColumn, 0 ] )
					exe "normal	".diff."x"
				endif

			endif
		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	" restore tab expansion settings and cursor position
	let &expandtab	= save_expandtab
	call setpos('.', save_cursor)

endfunction		" ---------- end of function  Python_AlignLineEndComm  ----------
"
"------------------------------------------------------------------------------
"  Comments : multi line-end comments     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_MultiLineEndComments ()
  if !exists("b:Python_LineEndCommentColumn")
    let b:Python_LineEndCommentColumn = s:Python_LineEndCommColDefault
  endif
  "
  let pos0  = line("'<")
  let pos1  = line("'>")
  " ----- trim whitespaces -----
  :'<,'>s/\s*$//
  " ----- find the longest line -----
  let maxlength   = 0
  let linenumber  = pos0
  normal '<
  while linenumber <= pos1
    if  getline(".") !~ "^\\s*$"  && maxlength<virtcol("$")
      let maxlength= virtcol("$")
    endif
    let linenumber=linenumber+1
    normal j
  endwhile
  "
  if maxlength < b:Python_LineEndCommentColumn
    let maxlength = b:Python_LineEndCommentColumn
  else
    let maxlength = maxlength+1   " at least 1 blank
  endif
  "
  " ----- fill lines with blanks -----
  let linenumber  = pos0
  normal '<
  while linenumber <= pos1
    if getline(".") !~ "^\\s*$"
      let diff  = maxlength - virtcol("$")
      exe "normal ".diff."A "
      exe "normal $A# "
    endif
    let linenumber=linenumber+1
    normal j
  endwhile
  " ----- back to the begin of the marked block -----
  normal '<
endfunction   " ---------- end of function  Python_MultiLineEndComments  ----------
"
"------------------------------------------------------------------------------
"  Comments : comment block     {{{1
"------------------------------------------------------------------------------
"
let s:Python_CmtCounter   = 0
let s:Python_CmtLabel     = "BlockCommentNo_"
"
function! Python_CommentBlock (mode)
  "
  let s:Python_CmtCounter = 0
  let save_line         = line(".")
  let actual_line       = 0
  "
  " search for the maximum option number (if any)
  "
  normal gg
  while actual_line < search( s:Python_CmtLabel."\\d\\+" )
    let actual_line = line(".")
    let actual_opt  = matchstr( getline(actual_line), s:Python_CmtLabel."\\d\\+" )
    let actual_opt  = strpart( actual_opt, strlen(s:Python_CmtLabel),strlen(actual_opt)-strlen(s:Python_CmtLabel))
    if s:Python_CmtCounter < actual_opt
      let s:Python_CmtCounter = actual_opt
    endif
  endwhile
  let s:Python_CmtCounter = s:Python_CmtCounter+1
  silent exe ":".save_line
  "
  if a:mode=='a'
    let zz=      "\n=begin  BlockComment  # ".s:Python_CmtLabel.s:Python_CmtCounter
    let zz= zz."\n\n=end    BlockComment  # ".s:Python_CmtLabel.s:Python_CmtCounter
    let zz= zz."\n\n=cut\n\n"
    put =zz
  endif

  if a:mode=='v'
    let zz=    "\n=begin  BlockComment  # ".s:Python_CmtLabel.s:Python_CmtCounter."\n\n"
    :'<put! =zz
    let zz=    "\n=end    BlockComment  # ".s:Python_CmtLabel.s:Python_CmtCounter
    let zz= zz."\n\n=cut\n\n"
    :'>put  =zz
  endif

endfunction    " ----------  end of function Python_CommentBlock ----------
"
"------------------------------------------------------------------------------
"  uncomment block     {{{1
"------------------------------------------------------------------------------
function! Python_UncommentBlock ()

  let frstline  = searchpair( '^=begin\s\+BlockComment\s*#\s*'.s:Python_CmtLabel.'\d\+',
      \                       '',
      \                       '^=end\s\+BlockComment\s\+#\s*'.s:Python_CmtLabel.'\d\+',
      \                       'bn' )
  if frstline<=0
    echohl WarningMsg | echo 'no comment block/tag found or cursor not inside a comment block'| echohl None
    return
  endif
  let lastline  = searchpair( '^=begin\s\+BlockComment\s*#\s*'.s:Python_CmtLabel.'\d\+',
      \                       '',
      \                       '^=end\s\+BlockComment\s\+#\s*'.s:Python_CmtLabel.'\d\+',
      \                       'n' )
  if lastline<=0
    echohl WarningMsg | echo 'no comment block/tag found or cursor not inside a comment block'| echohl None
    return
  endif
  let actualnumber1  = matchstr( getline(frstline), s:Python_CmtLabel."\\d\\+" )
  let actualnumber2  = matchstr( getline(lastline), s:Python_CmtLabel."\\d\\+" )
  if actualnumber1 != actualnumber2
    echohl WarningMsg | echo 'lines '.frstline.', '.lastline.': comment tags do not match'| echohl None
    return
  endif

  let line1 = lastline
  let line2 = lastline
  " empty line before =end
  if match( getline(lastline-1), '^\s*$' ) != -1
    let line1 = line1-1
  endif
  if lastline+1<line("$") && match( getline(lastline+1), '^\s*$' ) != -1
    let line2 = line2+1
  endif
  if lastline+2<line("$") && match( getline(lastline+2), '^=cut' ) != -1
    let line2 = line2+1
  endif
  if lastline+3<line("$") && match( getline(lastline+3), '^\s*$' ) != -1
    let line2 = line2+1
  endif
  silent exe ':'.line1.','.line2.'d'

  let line1 = frstline
  let line2 = frstline
  if frstline>1 && match( getline(frstline-1), '^\s*$' ) != -1
    let line1 = line1-1
  endif
  if match( getline(frstline+1), '^\s*$' ) != -1
    let line2 = line2+1
  endif
  silent exe ':'.line1.','.line2.'d'

endfunction    " ----------  end of function Python_UncommentBlock ----------
"
"------------------------------------------------------------------------------
"  toggle comments     {{{1
"------------------------------------------------------------------------------
function! Python_CommentToggle ()
	let	linenumber	= line(".")
	let line				= getline(linenumber)
	if match( line, '^#' ) == 0
		call setline( linenumber, strpart(line, 1) )
	else
		call setline( linenumber, '#'.line )
	endif
endfunction    " ----------  end of function Python_CommentToggle  ----------
"
"------------------------------------------------------------------------------
"  Comments : toggle comments (range)   {{{1
"------------------------------------------------------------------------------
function! Python_CommentToggleRange ()
	let	comment=1									" 
	let pos0	= line("'<")
	let pos1	= line("'>")
	for line in getline( pos0, pos1 )
		if match( line, '^\s*$' ) != 0					" skip empty lines
			if match( line, '^#') == -1						" no comment 
				let comment = 0
				break
			endif
		endif
	endfor

	if comment == 0
		for linenumber in range( pos0, pos1 )
			if match( line, '^\s*$' ) != 0					" skip empty lines
				call setline( linenumber, '#'.getline(linenumber) )
			endif
		endfor
	else
		for linenumber in range( pos0, pos1 )
			call setline( linenumber, substitute( getline(linenumber), '^#', '', '' ) )
		endfor
	endif

endfunction    " ----------  end of function Python_CommentToggleRange  ----------
"
"------------------------------------------------------------------------------
"  Comments : vim modeline     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_CommentVimModeline ()
  put = '# vim: set tabstop='.&tabstop.' shiftwidth='.&shiftwidth.': '
endfunction    " ----------  end of function Python_CommentVimModeline  ----------
"
"------------------------------------------------------------------------------
"  Python-Idioms : read / edit code snippet     {{{1
"------------------------------------------------------------------------------
function! Python_CodeSnippet(mode)
  if isdirectory(g:Python_CodeSnippets)
    "
    " read snippet file, put content below current line
    "
    if a:mode == "r"
			if has("gui_running") && s:Python_GuiSnippetBrowser == 'gui'
				let l:snippetfile=browse(0,"read a code snippet",g:Python_CodeSnippets,"")
			else
				let	l:snippetfile=input("read snippet ", g:Python_CodeSnippets, "file" )
			endif
      if filereadable(l:snippetfile)
        let linesread= line("$")
        let l:old_cpoptions = &cpoptions " Prevent the alternate buffer from being set to this files
        setlocal cpoptions-=a
        :execute "read ".l:snippetfile
        let &cpoptions  = l:old_cpoptions   " restore previous options
        "
        let linesread= line("$")-linesread-1
        if linesread>=0 && match( l:snippetfile, '\.\(ni\|noindent\)$' ) < 0
          silent exe "normal =".linesread."+"
        endif
      endif
    endif
    "
    " update current buffer / split window / edit snippet file
    "
    if a:mode == "e"
			if has("gui_running") && s:Python_GuiSnippetBrowser == 'gui'
				let l:snippetfile=browse(0,"edit a code snippet",g:Python_CodeSnippets,"")
			else
				let	l:snippetfile=input("edit snippet ", g:Python_CodeSnippets, "file" )
			endif
      if l:snippetfile != ""
        :execute "update! | split | edit ".l:snippetfile
      endif
    endif
    "
    " write whole buffer or marked area into snippet file
    "
    if a:mode == "w" || a:mode == "wv"
			if has("gui_running") && s:Python_GuiSnippetBrowser == 'gui'
				let l:snippetfile=browse(0,"write a code snippet",g:Python_CodeSnippets,"")
			else
				let	l:snippetfile=input("write snippet ", g:Python_CodeSnippets, "file" )
			endif
      if l:snippetfile != ""
        if filereadable(l:snippetfile)
          if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
            return
          endif
        endif
				if a:mode == "w"
					:execute ":write! ".l:snippetfile
				else
					:execute ":*write! ".l:snippetfile
				endif
      endif
    endif

  else
    redraw!
    echohl ErrorMsg
    echo "code snippet directory ".g:Python_CodeSnippets." does not exist"
    echohl None
  endif
endfunction   " ---------- end of function  Python_CodeSnippet  ----------
"
"------------------------------------------------------------------------------
"  Python-Run : Python_pythondoc - lookup word under the cursor or ask     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
"
let s:Python_PythondocBufferName       = "PYTHONDOC"
let s:Python_PythondocHelpBufferNumber = -1
let s:Python_PythondocModulelistBuffer = -1
let s:Python_PythondocSearchWord       = ""
let s:Python_PythondocTry              = "module"
"
function! Python_pythondoc()

  if( expand("%:p") == s:Python_PythonModuleList )
    normal 0
    let item=expand("<cWORD>")        			" WORD under the cursor
  else
		let cuc		= getline(".")[col(".") - 1]	" character under the cursor
    let item	= expand("<cword>")       		" word under the cursor
		if item == "" || match( item, cuc ) == -1
			let item=Python_Input("pythondoc - module, function or FAQ keyword : ", "", '')
		endif
  endif

  "------------------------------------------------------------------------------
  "  replace buffer content with Python documentation
  "------------------------------------------------------------------------------
  if item != ""
    "
    " jump to an already open PYTHONDOC window or create one
    "
    if bufloaded(s:Python_PythondocBufferName) != 0 && bufwinnr(s:Python_PythondocHelpBufferNumber) != -1
      exe bufwinnr(s:Python_PythondocHelpBufferNumber) . "wincmd w"
      " buffer number may have changed, e.g. after a 'save as'
      if bufnr("%") != s:Python_PythondocHelpBufferNumber
        let s:Python_PythondocHelpBufferNumber=bufnr(s:Python_OutputBufferName)
        exe ":bn ".s:Python_PythondocHelpBufferNumber
      endif
    else
      exe ":new ".s:Python_PythondocBufferName
      let s:Python_PythondocHelpBufferNumber=bufnr("%")
      setlocal buftype=nofile
      setlocal noswapfile
      setlocal bufhidden=delete
			silent  setlocal filetype=python    " allows repeated use of <S-F1>
      setlocal syntax=OFF
    endif
    "
    " search order:  library module --> builtin function --> FAQ keyword
    "
    let delete_pythondoc_errors = ""
    if s:UNIX
      let delete_pythondoc_errors = " 2>/dev/null"
    endif
    setlocal  modifiable
    "
    " controll repeated search
    "
    if item == s:Python_PythondocSearchWord
      " last item : search ring :
      if s:Python_PythondocTry == 'module'
        let next  = 'function'
      endif
      if s:Python_PythondocTry == 'function'
        let next  = 'faq'
      endif
      if s:Python_PythondocTry == 'faq'
        let next  = 'module'
      endif
      let s:Python_PythondocTry = next
    else
      " new item :
      let s:Python_PythondocSearchWord  = item
      let s:Python_PythondocTry         = 'module'
    endif
    "
    " module documentation
    if s:Python_PythondocTry == 'module'
      let command=":%!pythondoc  ".s:Python_pythondoc_flags." ".item.delete_pythondoc_errors
      silent exe command
      if v:shell_error != 0
        redraw!
        let s:Python_PythondocTry         = 'function'
      endif
    endif
    "
    " function documentation
    if s:Python_PythondocTry == 'function'
      " -otext has to be ahead of -f and -q
      silent exe ":%!pythondoc ".s:Python_pythondoc_flags." -f ".item.delete_pythondoc_errors
      if v:shell_error != 0
        redraw!
        let s:Python_PythondocTry         = 'faq'
      endif
    endif
    "
    " FAQ documentation
    if s:Python_PythondocTry == 'faq'
      silent exe ":%!pythondoc ".s:Python_pythondoc_flags." -q ".item.delete_pythondoc_errors
      if v:shell_error != 0
        redraw!
        let s:Python_PythondocTry         = 'error'
      endif
    endif
    "
    " no documentation found
    if s:Python_PythondocTry == 'error'
      redraw!
      let zz=   "No documentation found for python module, python function or python FAQ keyword\n"
      let zz=zz."  '".item."'  "
      silent put! =zz
      normal  2jdd$
      let s:Python_PythondocTry         = 'module'
      let s:Python_PythondocSearchWord  = ""
    endif
    if s:UNIX
      " remove windows line ends
      silent! exe ":%s/\r$// | normal gg"
    endif
    setlocal nomodifiable
    redraw!
		" highlight the headlines
		:match Search '^\S.*$'
  endif
endfunction   " ---------- end of function  Python_pythondoc  ----------
"
"------------------------------------------------------------------------------
"  Python-Run : Python_pythondoc - show module list     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_pythondoc_show_module_list()
  if !filereadable(s:Python_PythonModuleList)
    redraw!
    echohl WarningMsg | echo 'Have to create '.s:Python_PythonModuleList.' for the first time:'| echohl None
    call Python_pythondoc_generate_module_list()
  endif
  "
  " jump to the already open buffer or create one
  "
  if bufexists(s:Python_PythondocModulelistBuffer) && bufwinnr(s:Python_PythondocModulelistBuffer)!=-1
    silent exe bufwinnr(s:Python_PythondocModulelistBuffer) . "wincmd w"
  else
		:split
    exe ":view ".s:Python_PythonModuleList
    let s:Python_PythondocModulelistBuffer=bufnr("%")
    setlocal nomodifiable
    setlocal filetype=python
    setlocal syntax=none
  endif
  normal gg
  redraw!
  if has("gui_running")
    echohl Search | echomsg 'use S-F1 to show a manual' | echohl None
  else
    echohl Search | echomsg 'use \hh in normal mode to show a manual' | echohl None
  endif
endfunction   " ---------- end of function  Python_pythondoc_show_module_list  ----------
"
"------------------------------------------------------------------------------
"  Python-Run : Python_pythondoc - generate module list     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_pythondoc_generate_module_list()
	" save the module list, if any
	if filereadable( s:Python_PythonModuleList )
		let	backupfile	= s:Python_PythonModuleList.'.backup'
		if rename( s:Python_PythonModuleList, backupfile ) != 0
			echomsg 'Could not rename "'.s:Python_PythonModuleList.'" to "'.backupfile.'"'
		endif
	endif
	"
  echohl Search
  echo " ... generating Python module list ... "
  if  s:MSWIN
    silent exe ":!python \"".s:Python_PythonModuleListGenerator."\" > \"".s:Python_PythonModuleList."\""
    silent exe ":!sort \"".s:Python_PythonModuleList."\" /O \"".s:Python_PythonModuleList."\""
  else
		" direct STDOUT and STDERR to the module list file :
    silent exe ":!python ".s:Python_PythonModuleListGenerator." -s &> ".s:Python_PythonModuleList
  endif
	redraw!
  echo " DONE "
  echohl None
endfunction   " ---------- end of function  Python_pythondoc_generate_module_list  ----------
"
"------------------------------------------------------------------------------
"  Run : settings     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_Settings ()
  let txt =     "  Python-Support settings\n\n"
  let txt = txt.'             author name  :  "'.s:Python_Macro['|AUTHOR|']."\"\n"
  let txt = txt.'                initials  :  "'.s:Python_Macro['|AUTHORREF|']."\"\n"
  let txt = txt.'                   email  :  "'.s:Python_Macro['|EMAIL|']."\"\n"
  let txt = txt.'                 company  :  "'.s:Python_Macro['|COMPANY|']."\"\n"
  let txt = txt.'                 project  :  "'.s:Python_Macro['|PROJECT|']."\"\n"
  let txt = txt.'        copyright holder  :  "'.s:Python_Macro['|COPYRIGHTHOLDER|']."\"\n"
	let txt = txt.'           template style :  "'.s:Python_Macro['|STYLE|']."\"\n"
  let txt = txt."  code snippet directory  :  ".g:Python_CodeSnippets."\n"
	" ----- template files  ------------------------
	if s:installation == 'system'
		let txt = txt.'global template directory :  '.s:Python_GlobalTemplateDir."\n"
		if filereadable( s:Python_LocalTemplateFile )
			let txt = txt.' local template directory :  '.s:Python_LocalTemplateDir."\n"
		endif
	else
		let txt = txt.' local template directory :  '.s:Python_GlobalTemplateDir."\n"
	endif
	" ----- xterm ------------------------
	if	!s:MSWIN
		let txt = txt.'           xterm defaults :  '.s:Python_XtermDefaults."\n"
	endif
	" ----- dictionaries ------------------------
  if g:Python_Dictionary_File != ""
		let ausgabe= &dictionary
    let ausgabe = substitute( ausgabe, ",", ",\n                          + ", "g" )
    let txt     = txt."       dictionary file(s) :  ".ausgabe."\n"
  endif
  let txt = txt."    current output dest.  :  ".g:Python_OutputGvim."\n"
  let txt = txt."              pythoncritic  :  pythoncritic -severity ".s:Python_PythoncriticSeverity
				\				.' ['.s:PCseverityName[s:Python_PythoncriticSeverity].']'
				\				."  -verbosity ".s:Python_PythoncriticVerbosity
				\				."  ".s:Python_PythoncriticOptions."\n"
	if s:Python_InterfaceVersion != ''
		let txt = txt."  Python interface version  :  ".s:Python_InterfaceVersion."\n"
	endif
  let txt = txt."\n"
  let txt = txt."    Additional hot keys\n\n"
  let txt = txt."                Shift-F1  :  read pythondoc (for word under cursor)\n"
  let txt = txt."                      F9  :  start a debugger (".s:Python_Debugger.")\n"
  let txt = txt."                  Alt-F9  :  run syntax check          \n"
  let txt = txt."                 Ctrl-F9  :  run script                \n"
  let txt = txt."                Shift-F9  :  set command line arguments\n"
  let txt = txt."_________________________________________________________________________\n"
  let txt = txt."  Python-Support, Version ".g:Python_Version." / Dr.-Ing. Fritz Mehner / mehner@fh-swf.de\n\n"
  echo txt
endfunction   " ---------- end of function  Python_Settings  ----------
"
"------------------------------------------------------------------------------
"  run : syntax check     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_SyntaxCheck ()
  exe ":cclose"
  let l:currentbuffer   = bufname("%")
	let l:fullname        = expand("%:p")
  silent exe  ":update"
  "
  " avoid filtering the Python output if the file name does not contain blanks:
  "
	if s:MSWIN && ( l:fullname =~ ' ' ||  s:Python_EfmPython =~ ' ' )
    "
    " Use tools/efm_python.py from the VIM distribution.
    " This wrapper can handle filenames containing blanks.
    " Errorformat from tools/efm_python.py .
		" direct call 
    "
		let tmpfile = tempname()
    exe ':setlocal errorformat=%f:%l:%m'
		silent exe ":!\"".s:Python_EfmPython."\" -c % > ".tmpfile
		exe ":cfile ".tmpfile
  else
    "
		" no whitespaces
    " Errorformat from compiler/python.vim (VIM distribution).
    "
    exe ':set makeprg=python\ -c'
    exe ':setlocal errorformat=
        \%-G%.%#had\ compilation\ errors.,
        \%-G%.%#syntax\ OK,
        \%m\ at\ %f\ line\ %l.,
        \%+A%.%#\ at\ %f\ line\ %l\\,%.%#,
       \%+C%.%#'
	  let	l:fullname	= fnameescape( l:fullname )
  	silent exe  ':make  '.l:fullname
  endif

  exe ":botright cwindow"
  exe ':setlocal errorformat='
  exe "set makeprg=make"
  "
  " message in case of success
  "
	redraw!
  if l:currentbuffer ==  bufname("%")
			echohl Search
			echomsg l:currentbuffer." : Syntax is OK"
			echohl None
    return 0
  else
    setlocal wrap
    setlocal linebreak
  endif
endfunction   " ---------- end of function  Python_SyntaxCheck  ----------
"
"----------------------------------------------------------------------
"  run : toggle output destination     {{{1
"  Also called in the filetype plugin python.vim
"----------------------------------------------------------------------
function! Python_Toggle_Gvim_Xterm ()

	if g:Python_OutputGvim == "vim"
		if has("gui_running")
			exe "aunmenu  <silent>  ".g:Python_Root.'&Run.&output:\ VIM->buffer->xterm'
			exe "amenu    <silent>  ".g:Python_Root.'&Run.&output:\ BUFFER->xterm->vim              :call Python_Toggle_Gvim_Xterm()<CR>'
		endif
		let	g:Python_OutputGvim	= "buffer"
	else
		if g:Python_OutputGvim == "buffer"
			if has("gui_running")
				exe "aunmenu  <silent>  ".g:Python_Root.'&Run.&output:\ BUFFER->xterm->vim'
				if (!s:MSWIN)
					exe "amenu    <silent>  ".g:Python_Root.'&Run.&output:\ XTERM->vim->buffer             :call Python_Toggle_Gvim_Xterm()<CR>'
				else
					exe "amenu    <silent>  ".g:Python_Root.'&Run.&output:\ VIM->buffer->xterm            :call Python_Toggle_Gvim_Xterm()<CR>'
				endif
			endif
			if (!s:MSWIN) && (s:Python_Display != '')
				let	g:Python_OutputGvim	= "xterm"
			else
				let	g:Python_OutputGvim	= "vim"
			endif
		else
			" ---------- output : xterm -> gvim
			if has("gui_running")
				exe "aunmenu  <silent>  ".g:Python_Root.'&Run.&output:\ XTERM->vim->buffer'
				exe "amenu    <silent>  ".g:Python_Root.'&Run.&output:\ VIM->buffer->xterm            :call Python_Toggle_Gvim_Xterm()<CR>'
			endif
			let	g:Python_OutputGvim	= "vim"
		endif
	endif
  echomsg "output destination is '".g:Python_OutputGvim."'"

endfunction    " ----------  end of function Python_Toggle_Gvim_Xterm ----------
"
"------------------------------------------------------------------------------
"  run : Python_PythonSwitches     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_PythonSwitches ()
  let filename = fnameescape( expand("%:p") )
  if filename == ""
    redraw!
    echohl WarningMsg | echo " no file name " | echohl None
    return
  endif
  let prompt   = 'python command line switches for "'.filename.'" : '
  if exists("b:Python_Switches")
    let b:Python_Switches= Python_Input( prompt, b:Python_Switches, '' )
  else
    let b:Python_Switches= Python_Input( prompt , "", '' )
  endif
endfunction   " ---------- end of function  Python_PythonSwitches  ----------
"
"------------------------------------------------------------------------------
"  run : run     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
"
let s:Python_OutputBufferName   = "Python-Output"
let s:Python_OutputBufferNumber = -1
"
function! Python_Run ()
  "
  if &filetype != "python"
    echohl WarningMsg | echo expand("%:p").' seems not to be a Python file' | echohl None
    return
  endif
  let buffername  = expand("%")
  if fnamemodify( s:Python_PythonModuleList, ":p:t" ) == buffername || s:Python_PythondocBufferName == buffername
    return
  endif
  "
  let l:currentbuffernr = bufnr("%")
  let l:arguments       = exists("b:Python_CmdLineArgs") ? " ".b:Python_CmdLineArgs : ""
  let l:switches        = exists("b:Python_Switches") ? b:Python_Switches.' ' : ""
  let l:currentbuffer   = bufname("%")
  let l:fullname        = expand("%:p")
  let l:fullname_esc    = fnameescape( expand("%:p") )
  "
  silent exe ":update"
  silent exe ":cclose"
  "
  if  s:MSWIN
    let l:arguments = substitute( l:arguments, '^\s\+', ' ', '' )
    let l:arguments = substitute( l:arguments, '\s\+', "\" \"", 'g')
    let l:switches  = substitute( l:switches, '^\s\+', ' ', '' )
    let l:switches  = substitute( l:switches, '\s\+', "\" \"", 'g')
  endif
  "
  "------------------------------------------------------------------------------
  "  run : run from the vim command line
  "------------------------------------------------------------------------------
  if g:Python_OutputGvim == "vim"
    "
    if  s:MSWIN
      exe "!python ".l:switches.'"'.l:fullname.'" '.l:arguments
    else
      exe "!python ".l:switches.l:fullname_esc.l:arguments
    endif
    "
  endif
  "
  "------------------------------------------------------------------------------
  "  run : redirect output to an output buffer
  "------------------------------------------------------------------------------
  if g:Python_OutputGvim == "buffer"
    let l:currentbuffernr = bufnr("%")
    if l:currentbuffer ==  bufname("%")
      "
      "
      if bufloaded(s:Python_OutputBufferName) != 0 && bufwinnr(s:Python_OutputBufferNumber) != -1
        exe bufwinnr(s:Python_OutputBufferNumber) . "wincmd w"
        " buffer number may have changed, e.g. after a 'save as'
        if bufnr("%") != s:Python_OutputBufferNumber
          let s:Python_OutputBufferNumber=bufnr(s:Python_OutputBufferName)
          exe ":bn ".s:Python_OutputBufferNumber
        endif
      else
        silent exe ":new ".s:Python_OutputBufferName
        let s:Python_OutputBufferNumber=bufnr("%")
        setlocal buftype=nofile
        setlocal noswapfile
        setlocal syntax=none
        setlocal bufhidden=delete
        setlocal tabstop=8
      endif
      "
      " run script
      "
      setlocal  modifiable
      silent exe ":update"
      if  s:MSWIN
        exe ":%!python ".l:switches.'"'.l:fullname.l:arguments.'"'
      else
        exe ":%!python ".l:switches.l:fullname_esc.l:arguments
      endif
      setlocal  nomodifiable
      "
			if winheight(winnr()) >= line("$")
				exe bufwinnr(l:currentbuffernr) . "wincmd w"
			endif
			"
    endif
  endif
  "
  "------------------------------------------------------------------------------
  "  run : run in a detached xterm  (not available for MS Windows)
  "------------------------------------------------------------------------------
  if g:Python_OutputGvim == "xterm"
    "
    if  s:MSWIN
      " same as "vim"
      exe "!python \"".l:switches.l:fullname." ".l:arguments."\""
    else
      silent exe '!xterm -title '.l:fullname_esc.' '.s:Python_XtermDefaults.' -e '.s:Python_Wrapper.' python '.l:switches.l:fullname_esc.l:arguments
			:redraw!
    endif
    "
  endif
  "
endfunction    " ----------  end of function Python_Run  ----------
"
"------------------------------------------------------------------------------
"  Python_MakeArguments : run make(1)       {{{1
"------------------------------------------------------------------------------

let s:Python_MakeCmdLineArgs   = ""     " command line arguments for Run-make; initially empty

function! Python_MakeArguments ()
	let	s:Python_MakeCmdLineArgs= Python_Input("make command line arguments : ",s:Python_MakeCmdLineArgs, 'file' )
endfunction    " ----------  end of function Python_MakeArguments ----------
"
function! Python_Make()
	" update : write source file if necessary
	exe	":update"
	" run make
	exe		":!make ".s:Python_MakeCmdLineArgs
endfunction    " ----------  end of function Python_Make ----------
"
"------------------------------------------------------------------------------
"  run : start debugger     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_Debugger ()
  "
  silent exe  ":update"
  let l:arguments 	= exists("b:Python_CmdLineArgs") ? " ".b:Python_CmdLineArgs : ""
  let filename      = expand("%:p")
  let filename_esc  = fnameescape( expand("%:p") )
  "
  if  s:MSWIN
    let l:arguments = substitute( l:arguments, '^\s\+', ' ', '' )
    let l:arguments = substitute( l:arguments, '\s\+', "\" \"", 'g')
  endif
  "
  " debugger is ' python -d ... '
  "
  if s:Python_Debugger == "python"
    if  s:MSWIN
      exe '!python -d "'.filename.l:arguments.'"'
    else
      if has("gui_running") || &term == "xterm"
        silent exe "!xterm ".s:Python_XtermDefaults.' -e python -d '.filename_esc.l:arguments.' &'
      else
        silent exe '!clear; python -d '.filename_esc.l:arguments
      endif
    endif
  endif
  "
  if has("gui_running")
    "
    " grapical debugger is 'ptkdb', uses a PythonTk interface
    "
    if s:Python_Debugger == "ptkdb"
      if  s:MSWIN
				exe '!python -d:ptkdb "'.filename.l:arguments.'"'
      else
        silent exe '!python -d:ptkdb  '.filename_esc.l:arguments.' &'
      endif
    endif
    "
    " debugger is 'ddd'  (not available for MS Windows); graphical front-end for GDB
    "
    if s:Python_Debugger == "ddd" && !s:MSWIN
      if !executable("ddd")
        echohl WarningMsg
        echo 'ddd does not exist or is not executable!'
        echohl None
        return
      else
        silent exe '!ddd '.filename_esc.l:arguments.' &'
      endif
    endif
    "
  endif
  "
	redraw!
endfunction   " ---------- end of function  Python_Debugger  ----------
"
"------------------------------------------------------------------------------
"  run : Arguments     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_Arguments ()
  let filename = fnameescape( expand("%") )
  if filename == ""
    redraw!
    echohl WarningMsg | echo " no file name " | echohl None
    return
  endif
  let prompt   = 'command line arguments for "'.filename.'" : '
  if exists("b:Python_CmdLineArgs")
    let b:Python_CmdLineArgs= Python_Input( prompt, b:Python_CmdLineArgs, 'file' )
  else
    let b:Python_CmdLineArgs= Python_Input( prompt , "", 'file' )
  endif
endfunction   " ---------- end of function  Python_Arguments  ----------
"
"------------------------------------------------------------------------------
"  run : xterm geometry     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_XtermSize ()
  let regex = '-geometry\s\+\d\+x\d\+'
  let geom  = matchstr( s:Python_XtermDefaults, regex )
  let geom  = matchstr( geom, '\d\+x\d\+' )
  let geom  = substitute( geom, 'x', ' ', "" )
  let answer= Python_Input("   xterm size (COLUMNS LINES) : ", geom )
  while match(answer, '^\s*\d\+\s\+\d\+\s*$' ) < 0
    let answer= Python_Input(" + xterm size (COLUMNS LINES) : ", geom )
  endwhile
  let answer  = substitute( answer, '\s\+', "x", "" )           " replace inner whitespaces
  let s:Python_XtermDefaults  = substitute( s:Python_XtermDefaults, regex, "-geometry ".answer , "" )
endfunction   " ---------- end of function  Python_XtermSize  ----------
"
"------------------------------------------------------------------------------
"  run : make script executable     {{{1
"  Also called in the filetype plugin python.vim
"  Only on systems where execute permission is implemented
"------------------------------------------------------------------------------
function! Python_MakeScriptExecutable ()
  let filename  = fnameescape( expand("%:p") )
  if executable(filename) == 0                  " not executable
    silent exe "!chmod u+x ".filename
    redraw!
    if v:shell_error
      echohl WarningMsg
      echo 'Could not make "'.filename.'" executable !'
    else
      echohl Search
      echo 'Made "'.filename.'" executable.'
    endif
    echohl None
	else
		echo '"'.filename.'" is already executable.'
  endif
endfunction   " ---------- end of function  Python_MakeScriptExecutable  ----------
"
"------------------------------------------------------------------------------
"  run POD checker     {{{1
"------------------------------------------------------------------------------
function! Python_PodCheck ()
  exe ":cclose"
  let l:currentbuffer   = bufname("%")
  silent exe  ":update"
  "
  if s:Python_PodcheckerWarnings == "no"
    let PodcheckerWarnings  = '-nowarnings '
  else
    let PodcheckerWarnings  = '-warnings '
  endif
  :set makeprg=podchecker

  exe ':setlocal errorformat=***\ %m\ at\ line\ %l\ in\ file\ %f'
	if  s:MSWIN
		silent exe  ':make '.PodcheckerWarnings.'"'.expand("%:p").'"'
	else
		silent exe  ':make '.PodcheckerWarnings.fnameescape( expand("%:p") )
	endif

  exe ":botright cwindow"
  exe ':setlocal errorformat='
  exe ":set makeprg=make"
  "
  " message in case of success
  "
	redraw!
  if l:currentbuffer ==  bufname("%")
    echohl Search
    echomsg  l:currentbuffer." : POD syntax is OK"
    echohl None
    return 0
  endif
  return 1
endfunction   " ---------- end of function  Python_PodCheck  ----------
"
"------------------------------------------------------------------------------
"  run : POD -> html / man / text     {{{1
"------------------------------------------------------------------------------
function! Python_POD ( format )
	let	source			= expand("%:p")
	let	source_esc	= fnameescape( expand("%:p"),  )
	let target	  	= source.'.'.a:format
	let target_esc	= source_esc.'.'.a:format

  silent exe  ":update"
	if executable( 'pod2'.a:format )
		if  s:MSWIN
			if a:format=='html'
				silent exe  ':!pod2'.a:format.' "--infile='.source.'"  "--outfile='.target.'"'
			else
				silent exe  ':!pod2'.a:format.' "'.source.'" "'.target.'"'
			endif
		else
			if a:format=='html'
				silent exe  ':!pod2'.a:format.' --infile='.source_esc.' --outfile='.target_esc
			else
				silent exe  ':!pod2'.a:format.' '.source_esc.' '.target_esc
			endif
		endif
		redraw!
		echo  "file '".target."' generated"
	else
		redraw!
		echomsg 'Application "pod2'.a:format.'" does not exist or is not executable.'
	endif
endfunction   " ---------- end of function  Python_POD  ----------

"------------------------------------------------------------------------------
"  Python_RereadTemplates     {{{1
"  rebuild commands and the menu from the (changed) template file
"------------------------------------------------------------------------------
function! Python_RereadTemplates ()
    let s:Python_Template     = {}
    let s:Python_FileVisited  = []
    call Python_ReadTemplates(s:Python_GlobalTemplateFile)
    echomsg "templates rebuilt from '".s:Python_GlobalTemplateFile."'"
		"
		if !s:MSWIN && s:installation == 'system' && filereadable( s:Python_LocalTemplateFile )
			call Python_ReadTemplates( s:Python_LocalTemplateFile )
			echomsg " and from '".s:Python_LocalTemplateFile."'"
		endif
endfunction    " ----------  end of function Python_RereadTemplates  ----------

"------------------------------------------------------------------------------
"  Python_BrowseTemplateFiles     {{{1
"------------------------------------------------------------------------------
function! Python_BrowseTemplateFiles ( type )
	if filereadable( eval( 's:Python_'.a:type.'TemplateFile' ) )
		if has("browse") && s:Python_GuiTemplateBrowser == 'gui'
			let	l:templatefile	= browse(0,"edit a template file", eval('s:Python_'.a:type.'TemplateDir'), "" )
		else
				let	l:templatefile	= ''
			if s:Python_GuiTemplateBrowser == 'explorer'
				exe ':Explore '.eval('s:Python_'.a:type.'TemplateDir')
			endif
			if s:Python_GuiTemplateBrowser == 'commandline'
				let	l:templatefile	= input("edit a template file", eval('s:Python_'.a:type.'TemplateDir'), "file" )
			endif
		endif
		if l:templatefile != ""
			:execute "update! | split | edit ".l:templatefile
		endif
	else
		echomsg a:type." template file not readable."
	endif
endfunction    " ----------  end of function Python_BrowseTemplateFiles  ----------

"------------------------------------------------------------------------------
"  Python_EditTemplates     {{{1
"------------------------------------------------------------------------------
function! Python_EditTemplates ( type )
	"
	if a:type == 'global'
		if s:installation == 'system'
			call Python_BrowseTemplateFiles('Global')
		else
			echomsg "Python-Support is user installed: no global template file"
		endif
	endif
	"
	if a:type == 'local'
		if s:installation == 'system'
			call Python_BrowseTemplateFiles('Local')
		else
			call Python_BrowseTemplateFiles('Global')
		endif
	endif
	"
endfunction    " ----------  end of function Python_EditTemplates  ----------
"
"------------------------------------------------------------------------------
"  Python_ReadTemplates     {{{1
"  read the template file(s), build the macro and the template dictionary
"
"------------------------------------------------------------------------------
function! Python_ReadTemplates ( templatefile )

  if !filereadable( a:templatefile )
    echohl WarningMsg
    echomsg "Python Support template file '".a:templatefile."' does not exist or is not readable"
    echohl None
    return
  endif

	let	skipmacros	= 0
  let s:Python_FileVisited  += [a:templatefile]

  "------------------------------------------------------------------------------
  "  read template file, start with an empty template dictionary
  "------------------------------------------------------------------------------

  let item  		= ''
	let	skipline	= 0
  for line in readfile( a:templatefile )
		" if not a comment :
    if line !~ s:Python_MacroCommentRegex
      "
			" IF
      "
      let string  = matchlist( line, s:Python_TemplateIf )
      if !empty(string) 
				if s:Python_Macro['|STYLE|'] != string[1]
					let	skipline	= 1
				endif
			endif
			"
			" ENDIF
      "
      let string  = matchlist( line, s:Python_TemplateEndif )
      if !empty(string)
				let	skipline	= 0
				continue
			endif
			"
      if skipline == 1
				continue
			endif
      "
      " macros and file includes
      "
      let string  = matchlist( line, s:Python_MacroLineRegex )
      if !empty(string) && skipmacros == 0
        let key = '|'.string[1].'|'
        let val = string[2]
        let val = substitute( val, '\s\+$', '', '' )
        let val = substitute( val, "[\"\']$", '', '' )
        let val = substitute( val, "^[\"\']", '', '' )
        "
        if key == '|includefile|' && count( s:Python_FileVisited, val ) == 0
					let path   = fnamemodify( a:templatefile, ":p:h" )
          call Python_ReadTemplates( path.'/'.val )    " recursive call
        else
          let s:Python_Macro[key] = escape( val, '&' )
        endif
        continue                                     " next line
      endif
      "
      " template header
      "
      let name  = matchstr( line, s:Python_TemplateLineRegex )
      "
      if name != ''
        let part  = split( name, '\s*==\s*')
        let item  = part[0]
        if has_key( s:Python_Template, item ) && s:Python_TemplateOverwrittenMsg == 'yes'
          echomsg "existing Python Support template '".item."' overwritten"
        endif
        let s:Python_Template[item] = ''
				let skipmacros	= 1
        "
				" control insertion
				"
        let s:Python_InsertionAttribute[item] = 'below'
        if has_key( s:InsertionAttribute, get( part, 1, 'NONE' ) )
          let s:Python_InsertionAttribute[item] = part[1]
        endif
        "
				" control indentation
				"
        let s:Python_IndentAttribute[item] = 'indent'
        if has_key( s:IndentAttribute, get( part, 2, 'NONE' ) )
          let s:Python_IndentAttribute[item] = part[2]
        endif
      else
        if item != ''
          let s:Python_Template[item] = s:Python_Template[item].line."\n"
        endif
      endif
    endif
  endfor

endfunction    " ----------  end of function Python_ReadTemplates  ----------

"------------------------------------------------------------------------------
" Python_OpenFold     {{{1
" Open fold and go to the first or last line of this fold.
"------------------------------------------------------------------------------
function! Python_OpenFold ( mode )
	if foldclosed(".") >= 0
		" we are on a closed  fold: get end position, open fold, jump to the
		" last line of the previously closed fold
		let	foldstart	= foldclosed(".")
		let	foldend		= foldclosedend(".")
		normal zv
		if a:mode == 'below'
			exe ":".foldend
		endif
		if a:mode == 'start'
			exe ":".foldstart
		endif
	endif
endfunction    " ----------  end of function Python_OpenFold  ----------

"------------------------------------------------------------------------------
"  Python_InsertTemplate     {{{1
"  insert a template from the template dictionary
"  do macro expansion
"------------------------------------------------------------------------------
function! Python_InsertTemplate ( key, ... )

	if !has_key( s:Python_Template, a:key )
		echomsg "Template '".a:key."' not found. Please check your template file in '".s:Python_GlobalTemplateDir."'"
		return
	endif

	if &foldenable
		let	foldmethod_save	= &foldmethod
		set foldmethod=manual
	endif
  "------------------------------------------------------------------------------
  "  insert the user macros
  "------------------------------------------------------------------------------

	" use internal formatting to avoid conficts when using == below
	"
	let	equalprg_save	= &equalprg
	set equalprg=

  let mode  = s:Python_InsertionAttribute[a:key]
  let indent = s:Python_IndentAttribute[a:key]

	" remove <SPLIT> and insert the complete macro
	"
	if a:0 == 0
		let val = Python_ExpandUserMacros (a:key)
		if val	== ""
			return
		endif
		let val	= Python_ExpandSingleMacro( val, '<SPLIT>', '' )

		if mode == 'below'
			call Python_OpenFold('below')
			let pos1  = line(".")+1
			put  =val
			let pos2  = line(".")
			" proper indenting
			if indent == 'indent'
				exe ":".pos1
				let ins	= pos2-pos1+1
				exe "normal ".ins."=="
			endif
			"
		elseif mode == 'above'
			let pos1  = line(".")
			put! =val
			let pos2  = line(".")
			" proper indenting
			if indent == 'indent'
				exe ":".pos1
				let ins	= pos2-pos1+1
				exe "normal ".ins."=="
			endif
			"
		elseif mode == 'start'
			normal gg
			call Python_OpenFold('start')
			let pos1  = 1
			put! =val
			let pos2  = line(".")
			" proper indenting
			if indent == 'indent'
				exe ":".pos1
				let ins	= pos2-pos1+1
				exe "normal ".ins."=="
			endif
			"
		elseif mode == 'append'
			if &foldenable && foldclosed(".") >= 0
				echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
				exe "set foldmethod=".foldmethod_save
				return
			else
				let pos1  = line(".")
				put =val
				let pos2  = line(".")-1
				exe ":".pos1
				:join!
			endif
			"
		elseif mode == 'insert'
			if &foldenable && foldclosed(".") >= 0
				echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
				exe "set foldmethod=".foldmethod_save
				return
			else
				let val   = substitute( val, '\n$', '', '' )
				let currentline	= getline( "." )
				let pos1  = line(".")
				let pos2  = pos1 + count( split(val,'\zs'), "\n" )
				" assign to the unnamed register "" :
				let @"=val
				normal p
				" reformat only multiline inserts and previously empty lines
				if ( pos2-pos1 > 0 || currentline =~ '' ) && indent == 'indent'
					exe ":".pos1
					let ins	= pos2-pos1+1
					exe "normal ".ins."=="
				endif
			endif
			"
		endif
		"
	else
		"
		" =====  visual mode  ===============================
		"
		if  a:1 == 'v'
			let val = Python_ExpandUserMacros (a:key)
			let val	= Python_ExpandSingleMacro( val, s:Python_TemplateJumpTarget2, '' )
			if val	== ""
				return
			endif

			if match( val, '<SPLIT>\s*\n' ) >= 0
				let part	= split( val, '<SPLIT>\s*\n' )
			else
				let part	= split( val, '<SPLIT>' )
			endif

			if len(part) < 2
				let part	= [ "" ] + part
				echomsg 'SPLIT missing in template '.a:key
			endif
			"
			" 'visual' and mode 'insert':
			"   <part0><marked area><part1>
			" part0 and part1 can consist of several lines
			"
			if mode == 'insert'
				let pos1  = line(".")
				let pos2  = pos1
				let	string= @*
				let replacement	= part[0].string.part[1]
				" remove trailing '\n'
				let replacement   = substitute( replacement, '\n$', '', '' )
				exe ':s/'.string.'/'.replacement.'/'
			endif
			"
			" 'visual' and mode 'below':
			"   <part0>
			"   <marked area>
			"   <part1>
			" part0 and part1 can consist of several lines
			"
			if mode == 'below'

				:'<put! =part[0]
				:'>put  =part[1]

				let pos1  = line("'<") - len(split(part[0], '\n' ))
				let pos2  = line("'>") + len(split(part[1], '\n' ))
				"			" proper indenting
				if indent == 'indent'
					exe ":".pos1
					let ins	= pos2-pos1+1
					exe "normal ".ins."=="
				endif
			endif
			"
		endif		" ---------- end visual mode
	endif

	" restore formatter programm
	let &equalprg	= equalprg_save

  "------------------------------------------------------------------------------
  "  position the cursor
  "------------------------------------------------------------------------------
  exe ":".pos1
  let mtch = search( '<CURSOR>', 'c', pos2 )
	if mtch != 0
		let line	= getline(mtch)
		if line =~ '<CURSOR>$'
			call setline( mtch, substitute( line, '<CURSOR>', '', '' ) )
			if  a:0 != 0 && a:1 == 'v' && getline(".") =~ '^\s*$'
				normal J
			else
				:startinsert!
			endif
		else
			call setline( mtch, substitute( line, '<CURSOR>', '', '' ) )
			:startinsert
		endif
	else
		" to the end of the block; needed for repeated inserts
		if mode == 'below'
			exe ":".pos2
		endif
  endif

  "------------------------------------------------------------------------------
  "  marked words
  "------------------------------------------------------------------------------
	" define a pattern to highlight
	call Python_HighlightJumpTargets ()

	if &foldenable
		" restore folding method
		exe "set foldmethod=".foldmethod_save
		normal zv
	endif

endfunction    " ----------  end of function Python_InsertTemplate  ----------

"------------------------------------------------------------------------------
"  Python_JumpCtrlJ     {{{1
"------------------------------------------------------------------------------
function! Python_HighlightJumpTargets ()
	if s:Python_Ctrl_j == 'on'
		exe 'match Search /'.s:Python_TemplateJumpTarget1.'\|'.s:Python_TemplateJumpTarget2.'/'
	endif
endfunction    " ----------  end of function Python_HighlightJumpTargets  ----------

"------------------------------------------------------------------------------
"  Python_JumpCtrlJ     {{{1
"------------------------------------------------------------------------------
function! Python_JumpCtrlJ ()
  let match	= search( s:Python_TemplateJumpTarget1.'\|'.s:Python_TemplateJumpTarget2, 'c' )
	if match > 0
		" remove the target
		call setline( match, substitute( getline('.'), s:Python_TemplateJumpTarget1.'\|'.s:Python_TemplateJumpTarget2, '', '' ) )
	else
		" try to jump behind parenthesis or strings in the current line 
		if match( getline(".")[col(".") - 1], "[\]})\"'`]"  ) != 0
			call search( "[\]})\"'`]", '', line(".") )
		endif
		normal l
	endif
	return ''
endfunction    " ----------  end of function Python_JumpCtrlJ  ----------

"------------------------------------------------------------------------------
"  Python_ExpandUserMacros     {{{1
"------------------------------------------------------------------------------
function! Python_ExpandUserMacros ( key )

  let template 								= s:Python_Template[ a:key ]
	let	s:Python_ExpansionCounter	= {}										" reset the expansion counter

  "------------------------------------------------------------------------------
  "  renew the predefined macros and expand them
	"  can be replaced, with e.g. |?DATE|
  "------------------------------------------------------------------------------
	let	s:Python_Macro['|BASENAME|']	= toupper(expand("%:t:r"))
  let s:Python_Macro['|DATE|']  		= Python_DateAndTime('d')
  let s:Python_Macro['|FILENAME|']	= expand("%:t")
  let s:Python_Macro['|PATH|']  		= expand("%:p:h")
  let s:Python_Macro['|SUFFIX|']		= expand("%:e")
  let s:Python_Macro['|TIME|']  		= Python_DateAndTime('t')
  let s:Python_Macro['|YEAR|']  		= Python_DateAndTime('y')

  "------------------------------------------------------------------------------
  "  delete jump targets if mapping for C-j is off
  "------------------------------------------------------------------------------
	if s:Python_Ctrl_j == 'off'
		let template	= substitute( template, s:Python_TemplateJumpTarget1.'\|'.s:Python_TemplateJumpTarget2, '', 'g' )
	endif

  "------------------------------------------------------------------------------
  "  look for replacements
  "------------------------------------------------------------------------------
	while match( template, s:Python_ExpansionRegex ) != -1
		let macro				= matchstr( template, s:Python_ExpansionRegex )
		let replacement	= substitute( macro, '?', '', '' )
		let template		= substitute( template, macro, replacement, "g" )

		let match	= matchlist( macro, s:Python_ExpansionRegex )

		if match[1] != ''
			let macroname	= '|'.match[1].'|'
			"
			" notify flag action, if any
			let flagaction	= ''
			if has_key( s:Python_MacroFlag, match[2] )
				let flagaction	= ' (-> '.s:Python_MacroFlag[ match[2] ].')'
			endif
			"
			" ask for a replacement
			if has_key( s:Python_Macro, macroname )
				let	name	= Python_Input( match[1].flagaction.' : ', Python_ApplyFlag( s:Python_Macro[macroname], match[2] ) )
			else
				let	name	= Python_Input( match[1].flagaction.' : ', '' )
			endif
			if name == ""
				return ""
			endif
			"
			" keep the modified name
			let s:Python_Macro[macroname]  			= Python_ApplyFlag( name, match[2] )
		endif
	endwhile

  "------------------------------------------------------------------------------
  "  do the actual macro expansion
	"  loop over the macros found in the template
  "------------------------------------------------------------------------------
	while match( template, s:Python_NonExpansionRegex ) != -1

		let macro			= matchstr( template, s:Python_NonExpansionRegex )
		let match			= matchlist( macro, s:Python_NonExpansionRegex )

		if match[1] != ''
			let macroname	= '|'.match[1].'|'

			if has_key( s:Python_Macro, macroname )
				"-------------------------------------------------------------------------------
				"   check for recursion
				"-------------------------------------------------------------------------------
				if has_key( s:Python_ExpansionCounter, macroname )
					let	s:Python_ExpansionCounter[macroname]	+= 1
				else
					let	s:Python_ExpansionCounter[macroname]	= 0
				endif
				if s:Python_ExpansionCounter[macroname]	>= s:Python_ExpansionLimit
					echomsg " recursion terminated for recursive macro ".macroname
					return template
				endif
				"-------------------------------------------------------------------------------
				"   replace
				"-------------------------------------------------------------------------------
				let replacement = Python_ApplyFlag( s:Python_Macro[macroname], match[2] )
				let template 		= substitute( template, macro, replacement, "g" )
			else
				"
				" macro not yet defined
				let s:Python_Macro['|'.match[1].'|']  		= ''
			endif
		endif

	endwhile

  return template
endfunction    " ----------  end of function Python_ExpandUserMacros  ----------

"------------------------------------------------------------------------------
"  Python_ApplyFlag     {{{1
"------------------------------------------------------------------------------
function! Python_ApplyFlag ( val, flag )
	"
	" l : lowercase
	if a:flag == ':l'
		return  tolower(a:val)
	endif
	"
	" u : uppercase
	if a:flag == ':u'
		return  toupper(a:val)
	endif
	"
	" c : capitalize
	if a:flag == ':c'
		return  toupper(a:val[0]).a:val[1:]
	endif
	"
	" L : legalized name
	if a:flag == ':L'
		return  Python_LegalizeName(a:val)
	endif
	"
	" flag not valid
	return a:val
endfunction    " ----------  end of function Python_ApplyFlag  ----------
"
"------------------------------------------------------------------------------
"  Python_ExpandSingleMacro     {{{1
"------------------------------------------------------------------------------
function! Python_ExpandSingleMacro ( val, macroname, replacement )
  return substitute( a:val, escape(a:macroname, '$' ), a:replacement, "g" )
endfunction    " ----------  end of function Python_ExpandSingleMacro  ----------

"------------------------------------------------------------------------------
"  Python_InsertMacroValue     {{{1
"------------------------------------------------------------------------------
function! Python_InsertMacroValue ( key )
	if s:Python_Macro['|'.a:key.'|'] == ''
		echomsg 'the tag |'.a:key.'| is empty'
		return
	endif
	"
	if &foldenable && foldclosed(".") >= 0
		echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
		return
	endif
	if col(".") > 1
		exe 'normal a'.s:Python_Macro['|'.a:key.'|']
	else
		exe 'normal i'.s:Python_Macro['|'.a:key.'|']
	endif
endfunction    " ----------  end of function Python_InsertMacroValue  ----------

"------------------------------------------------------------------------------
"  insert date and time     {{{1
"------------------------------------------------------------------------------
function! Python_InsertDateAndTime ( format )
	if &foldenable && foldclosed(".") >= 0
		echohl WarningMsg | echomsg s:MsgInsNotAvail  | echohl None
		return ""
	endif
	if col(".") > 1
		exe 'normal a'.Python_DateAndTime(a:format)
	else
		exe 'normal i'.Python_DateAndTime(a:format)
	endif
endfunction    " ----------  end of function Python_InsertDateAndTime  ----------

"------------------------------------------------------------------------------
"  generate date and time     {{{1
"------------------------------------------------------------------------------
function! Python_DateAndTime ( format )
	if a:format == 'd'
		return strftime( s:Python_FormatDate )
	elseif a:format == 't'
		return strftime( s:Python_FormatTime )
	elseif a:format == 'dt'
		return strftime( s:Python_FormatDate ).' '.strftime( s:Python_FormatTime )
	elseif a:format == 'y'
		return strftime( s:Python_FormatYear )
	endif
endfunction    " ----------  end of function Python_DateAndTime  ----------

"
"------------------------------------------------------------------------------
"  run : pythontidy     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
"
let s:Python_pythontidy_startscript_executable = 'no'
let s:Python_pythontidy_module_executable      = 'no'

function! Python_Pythontidy (mode)

  let Sou   = expand("%")               " name of the file in the current buffer
	if   (&filetype != 'python') && 
				\ ( a:mode != 'v' || input( "'".Sou."' seems not to be a Python file. Continue (y/n) : " ) != 'y' ) 
		echomsg "'".Sou."' seems not to be a Python file."
		return
	endif
  "
  " check if pythontidy start script is executable
  "
  if s:Python_pythontidy_startscript_executable == 'no'
    if !executable("pythontidy")
      echohl WarningMsg
      echo 'pythontidy does not exist or is not executable!'
      echohl None
      return
    else
      let s:Python_pythontidy_startscript_executable  = 'yes'
    endif
  endif
  "
  " check if pythontidy module is executable
  " WORKAROUND: after upgrading Python the module will no longer be found
  "
  if s:Python_pythontidy_module_executable == 'no'
    let pythontidy_version = system("pythontidy -v")
    if match( pythontidy_version, 'copyright\c' )      >= 0 &&
    \  match( pythontidy_version, 'Steve\s\+Hancock' ) >= 0
      let s:Python_pythontidy_module_executable = 'yes'
    else
      echohl WarningMsg
      echo 'The module Python::Tidy can not be found! Please reinstall pythontidy.'
      echohl None
      return
    endif
  endif
  " ----- normal mode ----------------
  if a:mode=="n"
    if Python_Input("reformat whole file [y/n/Esc] : ", "y", '' ) != "y"
      return
    endif
    silent exe  ":update"
    let pos1  = line(".")
    if  s:MSWIN
      silent exe  "%!pythontidy"
    else
      silent exe  "%!pythontidy 2>/dev/null"
    endif
    exe ':'.pos1
    echo 'File "'.Sou.'" reformatted.'
  endif
  " ----- visual mode ----------------
  if a:mode=="v"

    let pos1  = line("'<")
    let pos2  = line("'>")
    if  s:MSWIN
      silent exe  pos1.",".pos2."!pythontidy"
    else
      silent exe  pos1.",".pos2."!pythontidy 2>/dev/null"
    endif
    echo 'File "'.Sou.'" (lines '.pos1.'-'.pos2.') reformatted.'
  endif
  "
  if filereadable("pythontidy.ERR")
    echohl WarningMsg
    echo 'Pythontidy detected an error when processing file "'.Sou.'". Please see file pythontidy.ERR'
    echohl None
  endif
  "
endfunction   " ---------- end of function  Python_Pythontidy  ----------

"------------------------------------------------------------------------------
"  run : Save buffer with timestamp     {{{1
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_SaveWithTimestamp ()
  let file   = fnameescape( expand("%") ) " name of the file in the current buffer
  if file == ""
		" do we have a quickfix buffer : syntax errors / profiler report
		if &filetype == 'qf'
			let file	= getcwd().'/Quickfix-List'
		else
			redraw!
			echohl WarningMsg | echo " no file name " | echohl None
			return
		endif
  endif
  let file   = file.'.'.strftime(s:Python_TimestampFormat)
  silent exe ":write ".file
  echomsg 'file "'.file.'" written'
endfunction   " ---------- end of function  Python_SaveWithTimestamp  ----------
"
"------------------------------------------------------------------------------
"  run : hardcopy     {{{1
"    MSWIN : a printer dialog is displayed
"    other : print PostScript to file
"  Also called in the filetype plugin python.vim
"------------------------------------------------------------------------------
function! Python_Hardcopy (mode)
  let outfile = expand("%")
  if outfile == ""
    redraw!
    echohl WarningMsg | echo " no file name " | echohl None
    return
  endif
	let outdir	= getcwd()
	if outdir == substitute( s:Python_PythonModuleList, '/[^/]\+$', '', '' ) || filewritable(outdir) != 2
		let outdir	= $HOME
	endif
	if  !s:MSWIN
		let outdir	= outdir.'/'
	endif

	let old_printheader=&printheader
	exe  ':set printheader='.s:Python_Printheader
	" ----- normal mode ----------------
	if a:mode=="n"
		silent exe  'hardcopy > '.outdir.outfile.'.ps'
		if  !s:MSWIN
			echo 'file "'.outfile.'" printed to "'.outdir.outfile.'.ps"'
		endif
	endif
	" ----- visual mode ----------------
	if a:mode=="v"
		silent exe  "*hardcopy > ".outdir.outfile.".ps"
		if  !s:MSWIN
			echo 'file "'.outfile.'" (lines '.line("'<").'-'.line("'>").') printed to "'.outdir.outfile.'.ps"'
		endif
	endif
	exe  ':set printheader='.escape( old_printheader, ' %' )
endfunction   " ---------- end of function  Python_Hardcopy  ----------
"
"------------------------------------------------------------------------------
"  run : help pythonsupport      {{{1
"------------------------------------------------------------------------------
function! Python_HelpPythonsupport ()
  try
    :help pythonsupport
  catch
    exe ':helptags '.s:plugin_dir.'doc'
    :help pythonsupport
  endtry
endfunction    " ----------  end of function Python_HelpPythonsupport ----------
"
"------------------------------------------------------------------------------
"  run : pythoncritic      {{{1
"------------------------------------------------------------------------------
"
" All formats consist of 2 parts:
"  1. the pythoncritic message format
"  2. the trailing    '%+A%.%#\ at\ %f\ line\ %l%.%#'
" Part 1 rebuilds the original pythoncritic message. This is done to make
" parsing of the messages easier.
" Part 2 captures errors from inside pythoncritic if any.
" Some verbosity levels are treated equal to give quickfix the filename.
"
" verbosity rebuilt
"
let s:PCverbosityFormat1 	= 1
let s:PCverbosityFormat2 	= 2
let s:PCverbosityFormat3 	= 3
let s:PCverbosityFormat4 	= escape( '"%f:%l:%c:%m.  %e  (Severity: %s)\n"', '%' )
let s:PCverbosityFormat5 	= escape( '"%f:%l:%c:%m.  %e  (Severity: %s)\n"', '%' )
let s:PCverbosityFormat6 	= escape( '"%f:%l:%m, near ' . "'%r'." . '  (Severity: %s)\n"', '%' )
let s:PCverbosityFormat7 	= escape( '"%f:%l:%m, near ' . "'%r'." . '  (Severity: %s)\n"', '%' )
let s:PCverbosityFormat8 	= escape( '"%f:%l:%c:[%p] %m. (Severity: %s)\n"', '%' )
let s:PCverbosityFormat9 	= escape( '"%f:%l:[%p] %m, near ' . "'%r'" . '. (Severity: %s)\n"', '%' )
let s:PCverbosityFormat10	= escape( '"%f:%l:%c:%m.\n  %p (Severity: %s)\n%d\n"', '%' )
let s:PCverbosityFormat11	= escape( '"%f:%l:%m, near ' . "'%r'" . '.\n  %p (Severity: %s)\n%d\n"', '%' )
"
" parses output for different verbosity levels:
"
let s:PCInnerErrorFormat	= ',\%+A%.%#\ at\ %f\ line\ %l%.%#'
let s:PCerrorFormat1 			= '%f:%l:%c:%m'         . s:PCInnerErrorFormat
let s:PCerrorFormat2 			= '%f:\ (%l:%c)\ %m'    . s:PCInnerErrorFormat
let s:PCerrorFormat3 			= '%m\ at\ %f\ line\ %l'. s:PCInnerErrorFormat
let s:PCerrorFormat4 			= '%f:%l:%c:%m'         . s:PCInnerErrorFormat
let s:PCerrorFormat5 			= '%f:%l:%c:%m'         . s:PCInnerErrorFormat
let s:PCerrorFormat6 			= '%f:%l:%m'            . s:PCInnerErrorFormat
let s:PCerrorFormat7 			= '%f:%l:%m'            . s:PCInnerErrorFormat
let s:PCerrorFormat8 			= '%f:%l:%m'            . s:PCInnerErrorFormat
let s:PCerrorFormat9 			= '%f:%l:%m'            . s:PCInnerErrorFormat
let s:PCerrorFormat10			= '%f:%l:%m'            . s:PCInnerErrorFormat
let s:PCerrorFormat11			= '%f:%l:%m'            . s:PCInnerErrorFormat
"
"------------------------------------------------------------------------------
"  run : pythoncritic (PC)
"------------------------------------------------------------------------------
function! Python_Pythoncritic ()
  let l:currentbuffer = bufname("%")
  if &filetype != "python"
    echohl WarningMsg | echo l:currentbuffer.' seems not to be a Python file' | echohl None
    return
  endif
  if executable("pythoncritic") == 0                  " not executable
    echohl WarningMsg | echo 'pythoncritic not installed or not executable' | echohl None
    return
  endif
  let s:Python_PythoncriticMsg = ""
  exe ":cclose"
  silent exe  ":update"
	"
  let pythoncriticoptions	=
		  \      ' -severity '.s:Python_PythoncriticSeverity
      \     .' -verbose '.eval("s:PCverbosityFormat".s:Python_PythoncriticVerbosity)
      \     .' '.escape( s:Python_PythoncriticOptions, s:esc_chars )
      \     .' '
	"
  exe  ':setlocal errorformat='.eval("s:PCerrorFormat".s:Python_PythoncriticVerbosity)
	:set makeprg=pythoncritic
  "
	if  s:MSWIN
		silent exe ':make '.pythoncriticoptions.'"'.expand("%:p").'"'
	else
		silent exe ':make '.pythoncriticoptions.fnameescape( expand("%:p") )
	endif
  "
	redraw!
  exe ":botright cwindow"
  exe ':setlocal errorformat='
  exe "set makeprg=make"
  "
  " message in case of success
  "
	let sev_and_verb	= 'severity '.s:Python_PythoncriticSeverity.
				\				      ' ['.s:PCseverityName[s:Python_PythoncriticSeverity].']'.
				\							', verbosity '.s:Python_PythoncriticVerbosity
	"
  if l:currentbuffer ==  bufname("%")
		let s:Python_PythoncriticMsg	= l:currentbuffer.' :  NO CRITIQUE  ('.sev_and_verb.')'
  else
    setlocal wrap
    setlocal linebreak
		let s:Python_PythoncriticMsg	= 'pythoncritic : '.sev_and_verb
  endif
	redraw!
  echohl Search | echo s:Python_PythoncriticMsg | echohl None
endfunction   " ---------- end of function  Python_Pythoncritic  ----------
"
"-------------------------------------------------------------------------------
"   set severity for pythoncritic     {{{1
"-------------------------------------------------------------------------------
let s:PCseverityName	= [ "DUMMY", "brutal", "cruel", "harsh", "stern", "gentle" ]
let s:PCverbosityName	= [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11' ]

function!	Python_PythonCriticSeverityList ( ArgLead, CmdLine, CursorPos )
	return filter( copy( s:PCseverityName[1:] ), 'v:val =~ "\\<'.a:ArgLead.'\\w*"' )
endfunction    " ----------  end of function Python_PythonCriticSeverityList  ----------

function!	Python_PythonCriticVerbosityList ( ArgLead, CmdLine, CursorPos )
	return filter( copy( s:PCverbosityName), 'v:val =~ "\\<'.a:ArgLead.'\\w*"' )
endfunction    " ----------  end of function Python_PythonCriticVerbosityList  ----------

function! Python_PythonCriticSeverity ( severity )
	let s:Python_PythoncriticSeverity = 3                         " the default
	let	sev	= a:severity
	let sev	= substitute( sev, '^\s\+', '', '' )  	     			" remove leading whitespaces
	let sev	= substitute( sev, '\s\+$', '', '' )	       			" remove trailing whitespaces
	"
	if sev =~ '^\d$' && 1 <= sev && sev <= 5
		" parameter is numeric
		let s:Python_PythoncriticSeverity = sev
		"
	elseif sev =~ '^\a\+$' 
		" parameter is a word
		let	nr	= index( s:PCseverityName, tolower(sev) )
		if nr > 0
			let s:Python_PythoncriticSeverity = nr
		endif
	else
		"
		echomsg "wrong argument '".a:severity."' / severity is set to ".s:Python_PythoncriticSeverity
		return
	endif
	echomsg "pythoncritic severity is set to ".s:Python_PythoncriticSeverity
endfunction    " ----------  end of function Python_PythonCriticSeverity  ----------
"
"-------------------------------------------------------------------------------
"   set verbosity for pythoncritic     {{{1
"-------------------------------------------------------------------------------
function! Python_PythonCriticVerbosity ( verbosity )
	let s:Python_PythoncriticVerbosity = 4
	let	vrb	= a:verbosity
  let vrb	= substitute( vrb, '^\s\+', '', '' )  	     			" remove leading whitespaces
  let vrb	= substitute( vrb, '\s\+$', '', '' )	       			" remove trailing whitespaces
  if vrb =~ '^\d\{1,2}$' && 1 <= vrb && vrb <= 11
    let s:Python_PythoncriticVerbosity = vrb
		echomsg "pythoncritic verbosity is set to ".s:Python_PythoncriticVerbosity
	else
		echomsg "wrong argument '".a:verbosity."' / pythoncritic verbosity is set to ".s:Python_PythoncriticVerbosity
  endif
endfunction    " ----------  end of function Python_PythonCriticVerbosity  ----------
"
"-------------------------------------------------------------------------------
"   set options for pythoncritic     {{{1
"-------------------------------------------------------------------------------
function! Python_PythonCriticOptions ( ... )
	let s:Python_PythoncriticOptions = ""
	if a:0 > 0
		let s:Python_PythoncriticOptions = a:1
	endif
endfunction    " ----------  end of function Python_PythonCriticOptions  ----------
"
"------------------------------------------------------------------------------
"  Check the pythoncritic default severity and verbosity.
"------------------------------------------------------------------------------
silent call Python_PythonCriticSeverity (s:Python_PythoncriticSeverity)
silent call Python_PythonCriticVerbosity(s:Python_PythoncriticVerbosity)

"------------------------------------------------------------------------------
"  Python_CreateGuiMenus     {{{1
"------------------------------------------------------------------------------
let s:Python_MenuVisible = 0								" state : 0 = not visible / 1 = visible
"
function! Python_CreateGuiMenus ()
  if s:Python_MenuVisible != 1
		aunmenu <silent> &Tools.Load\ Python\ Support
    amenu   <silent> 40.1000 &Tools.-SEP100- :
    amenu   <silent> 40.1160 &Tools.Unload\ Python\ Support :call Python_RemoveGuiMenus()<CR>
    call pythonsupportgui#Python_InitMenu()
    let s:Python_MenuVisible = 1
  endif
endfunction    " ----------  end of function Python_CreateGuiMenus  ----------

"------------------------------------------------------------------------------
"  Python_ToolMenu     {{{1
"------------------------------------------------------------------------------
function! Python_ToolMenu ()
    amenu   <silent> 40.1000 &Tools.-SEP100- :
    amenu   <silent> 40.1160 &Tools.Load\ Python\ Support :call Python_CreateGuiMenus()<CR>
endfunction    " ----------  end of function Python_ToolMenu  ----------

"------------------------------------------------------------------------------
"  Python_RemoveGuiMenus     {{{1
"------------------------------------------------------------------------------
function! Python_RemoveGuiMenus ()
  if s:Python_MenuVisible == 1
    if g:Python_Root == ""
      aunmenu <silent> Comments
      aunmenu <silent> Statements
      aunmenu <silent> Idioms
      aunmenu <silent> Snippets
      aunmenu <silent> Regex
      aunmenu <silent> File-Tests
      aunmenu <silent> Spec-Var
      aunmenu <silent> POD
      aunmenu <silent> Profiling
      aunmenu <silent> Run
      aunmenu <silent> help
    else
      exe "aunmenu <silent> ".g:Python_Root
    endif
    "
    aunmenu <silent> &Tools.Unload\ Python\ Support
		call Python_ToolMenu()
    "
    let s:Python_MenuVisible = 0
  endif
endfunction    " ----------  end of function Python_RemoveGuiMenus  ----------

"------------------------------------------------------------------------------
"  Python_do_tags     {{{1
"  tag a new file (Python::Tags)
"------------------------------------------------------------------------------
"function! Python_do_tags( filename, tagfile )
	"python <<EOF
	"my $filename	= VIM::Eval('a:filename');

	"$naive_tagger->process(files => $filename, refresh=>1 );

	"my $tagsfile	= VIM::Eval('a:tagfile');
	"VIM::SetOption("tags+=$tagsfile");

	"# of course, it may not even output, for example, if there's nothing new to process
	"$naive_tagger->output( outfile => $tagsfile );
"EOF
"endfunction    " ----------  end of function Python_do_tags  ----------
"
"------------------------------------------------------------------------------
"  show / hide the menus
"  define key mappings (gVim only)
"------------------------------------------------------------------------------
"
if has("gui_running")
	"
	call Python_ToolMenu()

  if s:Python_LoadMenus == 'yes'
    call Python_CreateGuiMenus()
  endif
  "
  nmap	<silent>  <Leader>lps		:call Python_CreateGuiMenus()<CR>
  nmap	<silent>  <Leader>ups		:call Python_RemoveGuiMenus()<CR>
  "
endif
"
"------------------------------------------------------------------------------
"  Automated header insertion
"------------------------------------------------------------------------------
if has("autocmd")

	autocmd BufNewFile  *.py  call Python_InsertTemplate('comment.file-description-pl')
" autocmd BufNewFile  *.pm  call Python_InsertTemplate('comment.file-description-pm')
"autocmd BufNewFile  *.t   call Python_InsertTemplate('comment.file-description-t')

	autocmd BufRead  *.py  call Python_HighlightJumpTargets()
	"autocmd BufRead  *.pm  call Python_HighlightJumpTargets()
	"autocmd BufRead  *.t   call Python_HighlightJumpTargets() 
  "
  "autocmd BufRead            *.pod  set filetype=python
  "autocmd BufNewFile         *.pod  set filetype=python | call Python_InsertTemplate('comment.file-description-pod')
  "autocmd BufNewFile,BufRead *.t    set filetype=python
  "
  " Wrap error descriptions in the quickfix window.
  autocmd BufReadPost quickfix  setlocal wrap | setlocal linebreak
  "
endif
"
let g:Python_PythonRegexAnalyser			= 'yes'
"
"-------------------------------------------------------------------------------
"   initialize the Python interface     {{{1
"-------------------------------------------------------------------------------
function! Python_InitializePythonInterface( )
	if has('pythonXXX')
    python <<EOF
		#
		# ---------------------------------------------------------------
		# find out the version of the Python interface
		# ---------------------------------------------------------------
		my $pythonversion=sprintf "%vd", $^V;
		VIM::DoCommand("let s:Python_InterfaceVersion = \"$pythonversion\"");
		#
		# ---------------------------------------------------------------
		# Python_RegexVisualize (function)
		# ---------------------------------------------------------------
		# -- empty --
		#
		# ---------------------------------------------------------------
		# Python_RegexExplain (function)
		# try to load the regex analyzer module; report failure
		# ---------------------------------------------------------------
		eval "require YAPE::Regex::Explain";
		if ( $@ ) {
			VIM::DoCommand("let g:Python_PythonRegexAnalyser = 'no'");
			}
		#
EOF

		if g:Python_PythonTags == 'enabled'
			python <<EOF
					# ---------------------------------------------------------------
					# initialize Python::Tags usage
					# ---------------------------------------------------------------
					eval "require Python::Tags";
					if ( $@ ) {
						VIM::DoCommand("let g:Python_PythonTags = 'disabled' ");
					}
					else {
						$naive_tagger = Python::Tags::Naive->new( max_level=>2 );
						# only go one level down by default
					}
EOF

		" if g:Python_PythonTags is still enabled
		if g:Python_PythonTags == 'enabled'
			autocmd BufRead,BufWritePost *.pm,*.pl,*.t	call Python_do_tags( expand('%'), g:Python_PythonTagsTempfile )
		endif

		endif " ----- g:Python_PythonTags == 'enabled'

	endif		" ----- has('python')
endfunction    " ----------  end of function Python_InitializePythonInterface  ----------
"
"------------------------------------------------------------------------------
"  READ THE TEMPLATE FILES
"------------------------------------------------------------------------------
call Python_ReadTemplates(s:Python_GlobalTemplateFile)
if !s:MSWIN && s:installation == 'system' && filereadable( s:Python_LocalTemplateFile )
	call Python_ReadTemplates( s:Python_LocalTemplateFile )
endif
"
call Python_InitializePythonInterface()
"
" vim: tabstop=2 shiftwidth=2 foldmethod=marker
