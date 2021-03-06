" Vim syntax file
" Language:	Python
" Maintainer:	Dmitry Vasiliev <dima@hlabs.spb.ru>
" URL:		http://www.hlabs.spb.ru/vim/python.vim
" Last Change:	$Date: 2006-03-06 13:52:12 +0300 (Пнд, 06 Мар 2006) $
" Filenames:	*.py
" Version:	2.5.3
" $Rev: 344 $
"
" Based on python.vim (from Vim 6.1 distribution)
" by Neil Schemenauer <nas@python.ca>
"

"
" Options:
"
"    For set option do: let OPTION_NAME = 1
"    For clear option do: let OPTION_NAME = 0
"
" Option names:
"
"    For highlight builtin functions:
"       python_highlight_builtins
"
"    For highlight standard exceptions:
"       python_highlight_exceptions
"
"    For highlight string formatting:
"       python_highlight_string_formatting
"
"    For highlight indentation errors:
"       python_highlight_indent_errors
"
"    For highlight trailing spaces:
"       python_highlight_space_errors
"
"    For highlight doc-tests:
"       python_highlight_doctests
"
"    If you want all possible Python highlighting:
"    (This option not override previously set options)
"       python_highlight_all
"
"    For fast machines:
"       python_slow_sync
"

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

if exists("python_highlight_all") && python_highlight_all != 0
  " Not override previously set options
  if !exists("python_highlight_builtins")
    let python_highlight_builtins = 1
  endif
  if !exists("python_highlight_exceptions")
    let python_highlight_exceptions = 1
  endif
  if !exists("python_highlight_string_formatting")
    let python_highlight_string_formatting = 1
  endif
  if !exists("python_highlight_indent_errors")
    let python_highlight_indent_errors = 1
  endif
  if !exists("python_highlight_space_errors")
    let python_highlight_space_errors = 1
  endif
  if !exists("python_highlight_doctests")
    let python_highlight_doctests = 1
  endif
endif

" Keywords
syn keyword pythonStatement	break continue del
syn keyword pythonStatement	exec return
syn keyword pythonStatement	pass print raise
syn keyword pythonStatement	global assert
syn keyword pythonStatement	lambda yield
syn keyword pythonStatement	def class nextgroup=pythonFunction skipwhite
syn match   pythonFunction	"\h\w*" display contained
syn keyword pythonRepeat	for while
syn keyword pythonConditional	if elif else
syn keyword pythonImport	import from as
syn keyword pythonException	try except finally
syn keyword pythonOperator	and in is not or with
syn keyword pythonConstant True None False self

" Decorators (new in Python 2.4)
syn match   pythonDecorator	"@" display nextgroup=pythonFunction skipwhite

" Comments
syn match   pythonComment	"#.*$" display contains=pythonTodo
syn match   pythonRun		"\%^#!.*$"
syn match   pythonCoding	"\%^.*\(\n.*\)\?#.*coding[:=]\s*[0-9A-Za-z-_.]\+.*$"
syn keyword pythonTodo		TODO FIXME XXX contained

" Errors
syn match pythonError		"\<\d\+\D\+\>" display
syn match pythonError		"[$?]" display

" TODO: Mixing spaces and tabs also may be used for pretty formatting multiline
" statements. For now I don't know how to work around this.
if exists("python_highlight_indent_errors") && python_highlight_indent_errors != 0
  syn match pythonIndentError	"^\s*\( \t\|\t \)\s*\S"me=e-1 display
endif

" Trailing space errors
if exists("python_highlight_space_errors") && python_highlight_space_errors != 0
  syn match pythonSpaceError	"\s\+$" display
endif

" Strings
syn region pythonString		start=+'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonEscape,pythonEscapeError
syn region pythonString		start=+"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonEscape,pythonEscapeError
syn region pythonString		start=+"""+ end=+"""+ keepend contains=pythonEscape,pythonEscapeError,pythonDocTest2,pythonSpaceError
syn region pythonString		start=+'''+ end=+'''+ keepend contains=pythonEscape,pythonEscapeError,pythonDocTest,pythonSpaceError

syn match  pythonEscape		+\\[abfnrtv'"\\]+ display contained
syn match  pythonEscape		"\\\o\o\=\o\=" display contained
syn match  pythonEscapeError	"\\\o\{,2}[89]" display contained
syn match  pythonEscape		"\\x\x\{2}" display contained
syn match  pythonEscapeError	"\\x\x\=\X" display contained
syn match  pythonEscape		"\\$"

" Unicode strings
syn region pythonUniString	start=+[uU]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonEscape,pythonUniEscape,pythonEscapeError,pythonUniEscapeError
syn region pythonUniString	start=+[uU]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonEscape,pythonUniEscape,pythonEscapeError,pythonUniEscapeError
syn region pythonUniString	start=+[uU]"""+ end=+"""+ keepend contains=pythonEscape,pythonUniEscape,pythonEscapeError,pythonUniEscapeError,pythonDocTest2,pythonSpaceError
syn region pythonUniString	start=+[uU]'''+ end=+'''+ keepend contains=pythonEscape,pythonUniEscape,pythonEscapeError,pythonUniEscapeError,pythonDocTest,pythonSpaceError

syn match  pythonUniEscape	"\\u\x\{4}" display contained
syn match  pythonUniEscapeError	"\\u\x\{,3}\X" display contained
syn match  pythonUniEscape	"\\U\x\{8}" display contained
syn match  pythonUniEscapeError	"\\U\x\{,7}\X" display contained
syn match  pythonUniEscape	"\\N{[A-Z ]\+}" display contained
syn match  pythonUniEscapeError	"\\N{[^A-Z ]\+}" display contained

" Raw strings
syn region pythonRawString	start=+[rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape
syn region pythonRawString	start=+[rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape
syn region pythonRawString	start=+[rR]"""+ end=+"""+ keepend contains=pythonDocTest2,pythonSpaceError
syn region pythonRawString	start=+[rR]'''+ end=+'''+ keepend contains=pythonDocTest,pythonSpaceError

syn match pythonRawEscape	+\\['"]+ display transparent contained

" Unicode raw strings
syn region pythonUniRawString	start=+[uU][rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,pythonUniRawEscape,pythonUniRawEscapeError
syn region pythonUniRawString	start=+[uU][rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,pythonUniRawEscape,pythonUniRawEscapeError
syn region pythonUniRawString	start=+[uU][rR]"""+ end=+"""+ keepend contains=pythonUniRawEscape,pythonUniRawEscapeError,pythonDocTest2,pythonSpaceError
syn region pythonUniRawString	start=+[uU][rR]'''+ end=+'''+ keepend contains=pythonUniRawEscape,pythonUniRawEscapeError,pythonDocTest,pythonSpaceError

syn match  pythonUniRawEscape		"\([^\\]\(\\\\\)*\)\@<=\\u\x\{4}" display contained
syn match  pythonUniRawEscapeError	"\([^\\]\(\\\\\)*\)\@<=\\u\x\{,3}\X" display contained

if exists("python_highlight_string_formatting") && python_highlight_string_formatting != 0
  " String formatting
  syn match pythonStrFormat	"%\(([^)]\+)\)\=[-#0 +]*\d*\(\.\d\+\)\=[hlL]\=[diouxXeEfFgGcrs%]" contained containedin=pythonString,pythonUniString,pythonRawString,pythonUniRawString
  syn match pythonStrFormat	"%[-#0 +]*\(\*\|\d\+\)\=\(\.\(\*\|\d\+\)\)\=[hlL]\=[diouxXeEfFgGcrs%]" contained containedin=pythonString,pythonUniString,pythonRawString,pythonUniRawString
endif

if exists("python_highlight_doctests") && python_highlight_doctests != 0
  " DocTests
  syn region pythonDocTest	start="^\s*>>>" end=+'''+he=s-1 end="^\s*$" contained
  syn region pythonDocTest2	start="^\s*>>>" end=+"""+he=s-1 end="^\s*$" contained
endif

" Numbers (ints, longs, floats, complex)
syn match   pythonHexNumber	"\<0[xX]\x\+[lL]\=\>" display
syn match   pythonHexNumber	"\<0[xX]\>" display
syn match   pythonNumber	"\<\d\+[lLjJ]\=\>" display
syn match   pythonFloat		"\.\d\+\([eE][+-]\=\d\+\)\=[jJ]\=\>" display
syn match   pythonFloat		"\<\d\+[eE][+-]\=\d\+[jJ]\=\>" display
syn match   pythonFloat		"\<\d\+\.\d*\([eE][+-]\=\d\+\)\=[jJ]\=" display

syn match   pythonOctalError	"\<0\o*[89]\d*[lL]\=\>" display
syn match   pythonHexError	"\<0[xX]\X\+[lL]\=\>" display

if exists("python_highlight_builtins") && python_highlight_builtins != 0
  " Builtin functions, types and objects
  syn keyword pythonBuiltinObj	True False Ellipsis None NotImplemented

  syn keyword pythonBuiltinFunc	__import__ abs all any apply
  syn keyword pythonBuiltinFunc	basestring bool buffer callable
  syn keyword pythonBuiltinFunc	chr classmethod cmp coerce compile complex
  syn keyword pythonBuiltinFunc	delattr dict dir divmod enumerate eval
  syn keyword pythonBuiltinFunc	execfile file filter float frozenset getattr
  syn keyword pythonBuiltinfunc globals hasattr hash help hex id 
  syn keyword pythonBuiltinFunc	input int intern isinstance
  syn keyword pythonBuiltinFunc	issubclass iter len list locals long map max
  syn keyword pythonBuiltinFunc	min object oct open ord pow property range
  syn keyword pythonBuiltinFunc	raw_input reduce reload repr
  syn keyword pythonBuiltinFunc reversed round set setattr
  syn keyword pythonBuiltinFunc	slice sorted staticmethod str sum super tuple
  syn keyword pythonBuiltinFunc	type unichr unicode vars xrange zip
endif

if exists("python_highlight_exceptions") && python_highlight_exceptions != 0
  " Builtin exceptions and warnings
  syn keyword pythonExClass	Exception StandardError ArithmeticError
  syn keyword pythonExClass	LookupError EnvironmentError

  syn keyword pythonExClass	AssertionError AttributeError EOFError
  syn keyword pythonExClass	FloatingPointError IOError ImportError
  syn keyword pythonExClass	IndexError KeyError KeyboardInterrupt
  syn keyword pythonExClass	MemoryError NameError NotImplementedError
  syn keyword pythonExClass	OSError OverflowError ReferenceError
  syn keyword pythonExClass	RuntimeError StopIteration SyntaxError
  syn keyword pythonExClass	IndentationError TabError
  syn keyword pythonExClass	SystemError SystemExit TypeError
  syn keyword pythonExClass	UnboundLocalError UnicodeError
  syn keyword pythonExClass	UnicodeEncodeError UnicodeDecodeError
  syn keyword pythonExClass	UnicodeTranslateError ValueError
  syn keyword pythonExClass	WindowsError ZeroDivisionError

  syn keyword pythonExClass	Warning UserWarning DeprecationWarning
  syn keyword pythonExClass	PendingDepricationWarning SyntaxWarning
  syn keyword pythonExClass	RuntimeWarning FutureWarning
endif

if exists("python_slow_sync") && python_slow_sync != 0
  syn sync minlines=2000
else
  " This is fast but code inside triple quoted strings screws it up. It
  " is impossible to fix because the only way to know if you are inside a
  " triple quoted string is to start from the beginning of the file.
  syn sync match pythonSync grouphere NONE "):$"
  syn sync maxlines=200
endif

if version >= 508 || !exists("did_python_syn_inits")
  if version <= 508
    let did_python_syn_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink pythonStatement	Statement
  HiLink pythonImport		Statement
  HiLink pythonFunction		Function
  HiLink pythonConditional	Conditional
  HiLink pythonRepeat		Repeat
  HiLink pythonException	Exception
  HiLink pythonOperator		Operator
  HiLink pythonConstant		PreProc

  HiLink pythonDecorator	Define

  HiLink pythonComment		Comment
  HiLink pythonCoding		Special
  HiLink pythonRun		Special
  HiLink pythonTodo		Todo

  HiLink pythonError		Error
  HiLink pythonIndentError	Error
  HiLink pythonSpaceError	Error

  HiLink pythonString		String
  HiLink pythonUniString	String
  HiLink pythonRawString	String
  HiLink pythonUniRawString	String

  HiLink pythonEscape			Special
  HiLink pythonEscapeError		Error
  HiLink pythonUniEscape		Special
  HiLink pythonUniEscapeError		Error
  HiLink pythonUniRawEscape		Special
  HiLink pythonUniRawEscapeError	Error

  HiLink pythonStrFormat	Special

  HiLink pythonDocTest		Special
  HiLink pythonDocTest2		Special

  HiLink pythonNumber		Number
  HiLink pythonHexNumber	Number
  HiLink pythonFloat		Float
  HiLink pythonOctalError	Error
  HiLink pythonHexError		Error

  HiLink pythonBuiltinObj	Structure
  HiLink pythonBuiltinFunc	Function

  HiLink pythonExClass	Structure

  delcommand HiLink
endif

let b:current_syntax = "python"
