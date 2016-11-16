
TITLE DirWalk	(MD5-DirWalk.asm)

INCLUDE Irvine32.inc
INCLUDE macros.inc

.386
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
GetCommandLine PROTO

.data

	BUFF_SIZE = 500

	buffer BYTE BUFF_SIZE DUP(?)

	bytesRead DWORD ?
	bytesWritten DWORD ?

	inFileName BYTE "C:\Users\<username>\Documents\Test.txt", 0
	outFileName BYTE "C:\Users\<username>\Documents\Output.txt", 0

	;inFileName BYTE ?
	;outFileName BYTE ?

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

.code

;----------------------------------------------------------------------------------
;	MD5_Hash
;
;	Calculates the hash value of message and returns 128 bit hash
;	
;	Receives: EAX, EBX, ECX, ....
;
;	Returns: EAX = Hash value
;----------------------------------------------------------------------------------
MD5_Hash PROC


	ret
MD5_Hash ENDP

main PROC

	;call GetCommandLine
	;jmp THEEND

	mov edx, OFFSET inFileName
	call OpenInputFile
	cmp eax, INVALID_HANDLE_VALUE
	je THEEND
	mov inFileHandle, eax
	mov eax, inFileHandle
	mov edx, OFFSET buffer
	mov ecx, BUFF_SIZE
	call ReadFromFile
	jc THEEND
	mov bytesRead, eax
	mov eax, inFileHandle
	call CloseFile
	cmp eax, 0
	jz THEEND
	mov edx, OFFSET outFileName
	call CreateOutputFile
	cmp eax, INVALID_HANDLE_VALUE
	je THEEND
	mov outFileHandle, eax
	mov eax, outFileHandle
	mov edx, OFFSET buffer
	mov ecx, bytesRead
	call WriteToFile
	jc THEEND
	mov bytesWritten, eax
	
	mov eax, K + 252
	call WriteHex

THEEND:

	INVOKE ExitProcess, 0

main ENDP
END main