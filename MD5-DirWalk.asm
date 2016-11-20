
TITLE DirWalk			(MD5 - DirWalk.asm)

INCLUDE Irvine32.inc
INCLUDE macros.inc

.386
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
GetCommandLine PROTO

extract_param PROTO, pDestination : PTR BYTE

.data

	QUOTE = 022h
	BACK_SLASH = 05Ch

	BUFF_SIZE = 16384

	temp_out_name BYTE "DirWalker_Output.txt", 0

	WDBUFFER_SIZE = 12

	bufferL BYTE WDBUFFER_SIZE DUP(? ), 0

	curDateTime FILETIME <>

	buffer BYTE BUFF_SIZE DUP(? )

	bytesRead DWORD ?

	inFileName BYTE 129 DUP(?)

	inFileHandle HANDLE ?
	outFileHandle HANDLE ?

	S	DWORD	7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
		DWORD	5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20
		DWORD	4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23
		DWORD	6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21

	K	DWORD	0D76AA478h, 0E8C7B756h, 0242070DBh, 0C1BDCEEEh
		DWORD	0F57C0FAFh, 04787C62Ah, 0A8304613h, 0FD469501h
		DWORD	0698098D8h, 08B44F7AFh, 0FFFF5BB1h, 0895CD7BEh
		DWORD	06B901122h, 0FD987193h, 0A679438Eh, 049B40821h
		DWORD	0F61E2562h, 0C040B340h, 0265E5A51h, 0E9B6C7AAh
		DWORD	0D62F105Dh, 002441453h, 0D8A1E681h, 0E7D3FBC8h
		DWORD	021E1CDE6h, 0C33707D6h, 0F4D50D87h, 0455A14EDh
		DWORD	0A9E3E905h, 0FCEFA3F8h, 0676F02D9h, 08D2A4C8Ah
		DWORD	0FFFA3942h, 08771F681h, 06D9D6122h, 0FDE5380Ch
		DWORD	0A4BEEA44h, 04BDECFA9h, 0F6BB4B60h, 0BEBFBC70h
		DWORD	0289B7EC6h, 0EAA127FAh, 0D4EF3085h, 004881D05h
		DWORD	0D9D4D039h, 0E6DB99E5h, 01FA27CF8h, 0C4AC5665h
		DWORD	0F4292244h, 0432AFF97h, 0AB9423A7h, 0FC93A039h
		DWORD	0655B59C3h, 08F0CCC92h, 0FFEFF47Dh, 085845DD1h
		DWORD	06FA87E4Fh, 0FE2CE6E0h, 0A3014314h, 04E0811A1h
		DWORD	0F7537E82h, 0BD3AF235h, 02AD7D2BBh, 0EB86D391h

	A0	DWORD	067452301h
	B0	DWORD	0EFCDAB89h
	C0	DWORD	098BADCFEh
	D0	DWORD	010325476h

	CommandLineArgs 	BYTE 129 DUP(?)
	Param0  				BYTE 129 DUP(?)
	Param1  				BYTE 129 DUP(?)

	A1 DWORD ?
	B1 DWORD ?
	C1 DWORD ?
	D1 DWORD ?

	M DWORD 16 DUP(? )

	F DWORD ?
	g DWORD ?

.code

num_to_str PROC

	mov eax, bytesRead
	shl eax, 3

	mov ebx, 10
	mov ecx, 0

	L1:
		mov edx, 0
		div ebx
		inc ecx
		push edx
		cmp eax, 0
		jne L1

	mov eax, 8
	sub eax, ecx
	mov edx, ecx
	mov ecx, eax

	L2 :
		mov buffer[esi], '0'
		inc esi
		loop L2

	mov ecx, edx
	L3 :
		pop edx
		add dl, 48
		mov buffer[esi], dl
		inc esi
		loop L3

	ret
num_to_str ENDP


; ----------------------------------------------------------------------------------
MD5_Hash PROC
;
;	Calculates the hash value of message and returns 128 bit hash
;
;	Receives: EAX, EBX, ECX, ....
;
;	Returns: EAX = Sum
; ----------------------------------------------------------------------------------

	mov eax, bytesRead
	call WriteDec
	mWrite '\n'
	mov buffer[eax], '1'

	inc eax
	shl eax, 3; shl equ bitwise multiplication, 2 * *3 = 8, multiply bytes to get bits
	and eax, 511; and equ bitwise modulus, 2 * *9 - 1 = 511, modulus bits by 512 for rem


	call WriteDec
	mWrite '\n'

	cmp eax, 448
	jg bottom

	mov ecx, 448; number of zeros to pad message until 64 shy of full 512 bit chunks
	sub ecx, eax
	mov eax, ecx
	jmp top

	bottom :
	call WriteDec
	mWrite '\n'
	sub eax, 448
	call WriteDec
	mWrite '\n'
	mov edx, 512
	sub edx, eax

	mov eax, edx

	top :
	call WriteDec

	mov ecx, eax
	shr ecx, 3
	mov eax, ecx
	mWrite '/n'
	call WriteDec
	mov esi, bytesRead
	inc esi
	L1 :
		mov buffer[esi], '0'
		inc esi
	loop L1

	mWrite '+'
	mov eax, esi
	call WriteDec

	mWrite ':::'
	call WriteDec

	call num_to_str

	mWrite '-----------'
	mov edx, OFFSET buffer
	call WriteString

	mov esi, 0
	mov ecx, 16
	MLOOP:
	; (esi * 64) + (g * 4)


	ret
MD5_Hash ENDP


; ----------------------------------------------------------------------------------
get_quote_pos PROC
;
;	Calls: esi = Address of string
;
;	Finds the first quote in a string
;	Note: Goes into an infinite loop if no quote in string (TODO: <--Fix this)
;
;	Returns: esi = Address of string after first quote
; ----------------------------------------------------------------------------------

	L1 :
		mov al, [esi]
		inc esi
		cmp al, QUOTE
		jne L1

	ret
get_quote_pos ENDP


; ----------------------------------------------------------------------------------
extract_param PROC, pDestination:PTR BYTE
;
;	Calls:	esi = Address of command line arguments
;			pDestination = Address of Parameter
;
;	Populates the destination address with the first parameter found in esi
;
;	Returns: esi = Address of pDestination offset at one byte past the first parameter
; ----------------------------------------------------------------------------------

	call get_quote_pos
	mov edx, esi
	call get_quote_pos
	push esi

	mov ecx, esi
	dec ecx
	sub ecx, edx

	mov esi, edx
	mov edi, pDestination
	rep movsb

	pop esi

	ret
extract_param ENDP


; ----------------------------------------------------------------------------------
get_cmdln_args PROC
;
;	Populates CommandLineArgs with the command line arguments
; ----------------------------------------------------------------------------------

	mov edx, OFFSET CommandLineArgs
	call GetCommandTail

	mov esi, edx
	INVOKE extract_param, OFFSET Param0
	INVOKE extract_param, OFFSET Param1

	ret
get_cmdln_args ENDP


; ----------------------------------------------------------------------------------
main PROC
;
;	Main Procedure
; ----------------------------------------------------------------------------------

; Get command line arguments
call get_cmdln_args

; Validate input file param
mov edx, OFFSET Param0
call StrLength
cmp eax, 3
jl GUI

; Open input file
call OpenInputFile
cmp eax, INVALID_HANDLE_VALUE
je ERR_CODE_0

; Read from input file
mov inFileHandle, eax
mov edx, OFFSET buffer
mov ecx, BUFF_SIZE
call ReadFromFile
jc ERR_CODE_1
mov bytesRead, eax

; Hash the file contents
call MD5_Hash

; Close input file
mov eax, inFileHandle
call CloseFile

; Validate output file param
mov edx, OFFSET Param1
call StrLength
cmp eax, 3
jl CREATE_OUT_FILE

; Try to open existing output file
INVOKE CreateFile, edx, GENERIC_WRITE, DO_NOT_SHARE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
cmp eax, INVALID_HANDLE_VALUE
je ERR_CODE_0

CREATE_OUT_FILE:
; scan param0 back to front, find first index '\'
; set direction flag
mov edx, OFFSET Param0
call WriteString
call StrLength
mWrite '+'
call WriteDec
std
mov ecx, eax
mov al, BACK_SLASH
lea edi, [Param0 + ecx]
repne scasb
mWrite 'THIS'
lea edx, [edi + 2]
call WriteString

cld
add ecx, 2
mov esi, OFFSET Param0
mov edi, OFFSET Param1
rep movsb

; push edi

; INVOKE GetDateTime, ADDR curDateTime
; mov eax, curDateTime.loDateTime
; call WriteDec
; and eax, 48


;mov ecx, 4
;pop edi
;rep stosb

mov ecx, LENGTHOF temp_out_name
mov esi, OFFSET temp_out_name
rep movsb

mov edx, OFFSET Param0
mWrite "Input:"
call WriteString

mov edx, OFFSET Param1
mWrite "Output:"
call WriteString

; copy param0 from beginning to first index of '\' into param1
; mov eax, "\DirWalker_OutputDATE.txt"
; call StrLen on eax
; mov val of len into ecx
; store eax in param1[last]

; call CreateOutputFile
; cmp eax, INVALID_HANDLE_VALUE
; je ERR_CODE_0

SEEK_EOF:
; mov outFileHandle, eax


GUI:

jmp THEEND

ERR_CODE_1:
call WriteWindowsMsg
mov eax, inFileHandle
call CloseFile

ERR_CODE_0:
mWrite "Invalid Input"

THEEND:

INVOKE ExitProcess, 0

main ENDP
END main