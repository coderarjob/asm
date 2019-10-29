#The NASM Preprocessor

-----------------------
NASM preprocessor supports conditional assembly, multi-level file inclusion,
single-line and multi-line macros.
Preprocessor directives all begin with a **%** sign.

The proprocessor collapses all lines with end with a backslash (\) character
into a single line. Thus:

`

	%define THIS_VERY_LONG_MACRO_NAME_IS_DEFINED_TO \
			THIS_VALUE
`

will work like a single-line macro without the backslash-newline sequence.

**Note: Macros are expanded only whtn it is called.**

----------
###Single line macro in nasm

----------
https://www.nasm.us/doc/nasmdoc4.html

Single line mactos are defined using the %define preprocessor directive. The
definations work in a similar way to C.

`

	%define ctrl	0x1F &
	%define param(a,b)	((a)+(a) * (b))

	mov byte[param(2,ebx)],ctrl 'D'
`

will be expanded to `mov byte [(2)+(2)*ebx], 0x1F & 'D'`.

**Note: Macros are case sensitive**

`%define foo bar`, only expands `foo` not Foo, or FOO.

But by using `%idefine` instead of `%define` ('i' stands for 'insensitive') you
can define all the case variants of a macro, sot that `%idefine foo bar` would
cause foo, Foo, FOO, fOO ans so on all to expand to bar.

----------
####Redefining macros

----------
You can define a macro `%define foo bar` and redefine it `%define foo baz` at a
later point in the source file. **It will be expanded accoring to the most
recent defination.**

`
	
	%define TRUE 1
	MOV EAX, TRUE

	%define TRUE 0
	MOV EAX, TRUE
`

will get expanded as

`

	MOV EAX, 1
	MOV EAX, 0
`
