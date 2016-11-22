
TITLE DirWalk		(MD5 - DirWalk.asm)

INCLUDE Irvine32.inc
INCLUDE macros.inc

.386
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD
GetCommandLine PROTO

ExtractParam PROTO, pDestination:PTR BYTE


leftrotate MACRO num1, num2
.code
	
	pushad
	
	mov eax, num1
	mov ebx, num2

	mov cl, bl
	rol eax, cl
	mov edx, 32
	neg ebx
	add edx, ebx
	mov ebx, eax
	ror eax, cl

	popad

ENDM

.data

	CARRIAGE_RETURN		= 0Dh
	LINE_FEED			= 0Ah
	QUOTE				= 022h
	BACK_SLASH			= 05Ch
	PERIOD				= 02Eh
	TAB					= 09h

	ASCII_CON = 48

	DIGEST_SZ = 16

	CHUNK_SZ	= 512
	PAD_SZ		= 448

	IN_BUFF_SZ	= 16384
	OUT_BUFF_SZ = 148


	DefaultFileName BYTE "_DirWalker_Output.txt",0
	DefaultKeyWord BYTE "DEFAULT_OUT6102",0

	HexVals BYTE "0123456789ABCDEF"


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

.data

	CommandLineArgs		BYTE 129 DUP(?)
	Param0  			BYTE 129 DUP(?)
	Param1				BYTE 129 DUP(?)

	Param0Len	DWORD ?
	Param1Len	DWORD ?

	inBuffer	BYTE IN_BUFF_SZ  DUP(?)
	outBuffer	BYTE OUT_BUFF_SZ DUP(?)

	bytesRead		DWORD ?
	bytesWritten	DWORD ?

	inFileHandle	HANDLE ?
	outFileHandle	HANDLE ?

	digest BYTE DIGEST_SZ DUP(?)

	A1 DWORD ?
	B1 DWORD ?
	C1 DWORD ?
	D1 DWORD ?

	M DWORD DIGEST_SZ DUP(?)

	F DWORD ?
	g DWORD ?

.code

; ----------------------------------------------------------------------------------
LoadInits PROC USES eax
;
;	move initial values(a0, b0, c0, d0) into temp ones
;   (a1, b1, c1, d1)
; ----------------------------------------------------------------------------------

	mov eax, a0
	mov a1, eax

	mov eax, b0
	mov b1, eax

	mov eax, c0
	mov c1, eax

	mov eax, d0
	mov d1, eax

	ret
LoadInits ENDP


; ----------------------------------------------------------------------------------
Scramble PROC USES eax ebx edx
;    
;	 dTemp: = D
;    D: = C
;    C: = B
; ----------------------------------------------------------------------------------

	mov ebx, d1		; dTemp = d1
	
	mov edx, c1
	mov d1, edx		; d1 = c1
	
	mov edx, b1
	mov c1, edx		; c1 = b1
	
	add eax, a1
	mov a1, ebx		; mov a1, dtemp

	ret
Scramble ENDP


; ----------------------------------------------------------------------------------
AddHashResult PROC
;
;	Adds a chunk's hash to the result a0, b0, c0, d0
; ----------------------------------------------------------------------------------

	mov eax, a1
	add eax, a0
	mov a0, eax

	mov eax, b1
	add eax, b0
	mov b0, eax

	mov eax, c1
	add eax, c0
	mov c0, eax

	mov eax, d1
	add eax, d0
	mov d0, eax
		
	ret
AddHashResult ENDP


;------------------------------------------------------
StoreHexB PROC, Index:DWORD
	LOCAL displaySize:DWORD
;
;	Irvine 32 Library - WriteHexB - Repurposed
;------------------------------------------------------

	DOUBLEWORD_BUFSIZE = 8

.data
	bufferLHB BYTE DOUBLEWORD_BUFSIZE DUP(?),0

.code
	pushad
	mov displaySize,ebx

	.IF EBX == 1
		and eax,0FFh
	.ELSE
		.IF EBX == 2
		  and eax,0FFFFh
		.ELSE
		  mov displaySize,4
		.ENDIF
	.ENDIF

	mov edi,displaySize
	shl edi,1
	mov bufferLHB[edi],0
	dec edi

	mov ecx,0
	mov ebx,16

	L1:
		mov edx,0
		div ebx

		xchg eax,edx
		push  ebx
		mov   ebx,OFFSET HexVals
		xlat
		pop   ebx
		mov bufferLHB[edi],al
		dec edi
		xchg eax,edx

		inc ecx
	or eax,eax
	jnz L1

	mov eax,displaySize
	shl eax,1
	sub eax,ecx
	jz  L3 
		
	mov ecx,eax

	L2:
		mov bufferLHB[edi],'0'
		dec edi
	loop L2

	L3:
	mov ecx,displaySize
	shl ecx,1
	inc edi
	mov edx,OFFSET bufferLHB
	add edx,edi
	;call WriteString

	mov eax, Index
	mov ecx, 4
	mov esi, OFFSET bufferLHB
	lea edi, outBuffer[eax * 4]
	rep movsb
		

	popad
	
	ret
StoreHexB ENDP

;------------------------------------------------------
StoreHex PROC, Index:DWORD
;
;	Irvine 32 Library - WriteHex - Repurposed
;------------------------------------------------------
	
	push ebx
	mov  ebx,4
	INVOKE StoreHexB, Index
	pop  ebx
	
	ret
StoreHex ENDP




		; ----------------------------------------------------------------------------------
		print_result PROC USES eax
		;
	;	populate the character digest with a0, b0, c0, d0 and print it
		;
	; ----------------------------------------------------------------------------------

		mov eax, a0
		mov DWORD PTR digest, eax
		mov eax, b0
		mov DWORD PTR digest + 4, eax
		mov eax, c0
		mov DWORD PTR digest + 8, eax
		mov eax, d0
		mov DWORD PTR digest + 12, eax

		mov esi, 0
		mov ecx, 4
		L1 :
			mov eax, DWORD PTR[digest + esi * 4]
			inc esi
			INVOKE StoreHex, esi
		loop L1
		
		ret
print_result ENDP


		; ----------------------------------------------------------------------------------
		MD5_Hash PROC
		;
	;	Calculates the hash value of message and returns 128 bit hash
		;
	;	Receives: EAX, EBX, ECX, ....
		;
	;	Returns: EAX = Sum
		; ----------------------------------------------------------------------------------

		shr esi, 6; divide esi by 64
		mov ecx, esi; contains total number of 512 blocks
		mov esi, 0

		outer_loop:
	call LoadInits
		push ecx
		mov ecx, 16
		round1 :
		mov ebx, c1
		mov edx, d1
		xor ebx, edx
		mov eax, b1
		and eax, ebx
		xor eax, edx

		call Scramble

		; first parameter of leftrotate

		; use ecx 0 - 15 to index K and S
		push ecx
		neg ecx
		add ecx, 16

		add eax, [K + ecx * TYPE K]

		mov edi, DWORD PTR[inBuffer + esi * 4]
		rol edi, 16
		add eax, edi

		; second parameter of leftrotate
		mov ebx, [S + ecx * TYPE S]

		pop ecx

		leftrotate eax, ebx

		mov ebx, b1
		add ebx, eax
		mov b1, ebx

		call AddHashResult
		inc esi

		dec ecx
		or ecx, ecx
		jnz round1

		mov ecx, 16
		mov edi, esi

		round2 :
	mov eax, c1
		mov ebx, b1
		xor ebx, eax
		mov edx, d1
		and edx, ebx
		xor eax, edx; eax is F

		call Scramble

		; use ecx 16 - 31 to index K and S
		push ecx
		neg ecx
		add ecx, 32
		add eax, [K + ecx * TYPE K]
		push eax

		; calculate index for message
		; (5×i + 1) mod 16
		mov eax, esi
		mov ebx, 5
		mul eax
		add eax, 1
		mov edx, 0
		mov ebx, 16
		div eax; edx contains remainder
		pop eax

		push edi
		add edi, edx
		mov edi, DWORD PTR[inBuffer + edi * 4]
		rol edi, 16
		pop edi
		add eax, edi

		mov ebx, [S + ecx * TYPE S]
		pop ecx

		leftrotate eax, ebx

		mov ebx, b1
		add ebx, eax
		mov b1, ebx

		call AddHashResult
		inc esi

		dec ecx
		or ecx, ecx
		jnz round2

		mov ecx, 16
		mov edi, esi

		round3 :
	mov edx, d1
		mov ebx, c1
		xor ebx, edx
		mov eax, b1
		xor eax, ebx

		call Scramble

		; use ecx 32 - 47 to index K and S
		push ecx
		neg ecx
		add ecx, 48
		add eax, [K + ecx * TYPE K]
		push eax

		; calculate index for message
		; (3×i + 5) mod 16
		mov eax, esi
		mov ebx, 3
		mul eax
		add eax, 5
		mov edx, 0
		mov ebx, 16
		div eax; edx contains remainder
		pop eax
		push edi
		add edi, edx
		mov edi, DWORD PTR[inBuffer + esi * 4]
		rol edi, 16
		add eax, edi
		pop edi
		mov ebx, [S + ecx * TYPE S]
		pop ecx

		leftrotate eax, ebx

		mov ebx, b1
		add ebx, eax
		mov b1, ebx

		call AddHashResult
		inc esi

		dec ecx
		or ecx, ecx
		jnz round3

		mov ecx, 16
		round4:
	mov edx, d1
		not edx
		mov ebx, b1
		or ebx, edx
		mov eax, c1
		xor eax, ebx

		call Scramble

		; use ecx 48 - 63 to index K and S
		push ecx
		neg ecx
		add ecx, 64
		add eax, [K + ecx * TYPE K]
		push eax

		; calculate index for message
		; (7xi) mod 16
		mov eax, esi
		mov ebx, 7
		mul eax
		mov edx, 0
		mov ebx, 16
		div eax; edx contains remainder
		pop eax
		push edi
		add edi, edx
		mov edi, DWORD PTR[inBuffer + edi * 4]
		rol edi, 16
		add eax, edi
		pop edi
		mov ebx, [S + ecx * TYPE S]
		pop ecx

		leftrotate eax, ebx

		mov ebx, b1
		add ebx, eax
		mov b1, ebx

		call AddHashResult
		inc esi

		dec ecx
		or ecx, ecx
		jnz round4

		pop ecx
		dec ecx
		or ecx, ecx
		jnz outer_loop


		call print_result

		ret
MD5_Hash ENDP


; ----------------------------------------------------------------------------------
AppendPadding PROC
;
;	Appends inBuffer with '1', n '0's, and original inBuffer bit length
;	Padding makes the inBuffer size a multiple of 512 (CHUNK_SZ)
; ----------------------------------------------------------------------------------

	mov esi, BytesRead
	mov eax, esi

	mov inBuffer[esi], '1'

	inc esi
	inc eax

	shl eax, 3
	and eax, CHUNK_SZ - 1

	mov ecx, PAD_SZ
	mov edx, CHUNK_SZ

	cmp eax, ecx
	jg LARGER

	; Smaller
	sub ecx, eax
	jmp ZERO_PADDED

	LARGER:
	sub eax, ecx
	sub edx, eax
	mov ecx, edx

	ZERO_PADDED:
	shr ecx, 3
	L0 :
		mov inBuffer[esi], '0'
		inc esi
	loop L0

	; Bit Len to Str
	mov eax, bytesRead
	shl eax, 3

	mov ebx, 10
	mov ecx, 0

	L1 :
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
		mov inBuffer[esi], '0'
		inc esi
	loop L2

	mov ecx, edx
	L3 :
		pop edx
		add dl, ASCII_CON
		mov inBuffer[esi], dl
		inc esi
	loop L3

	ret
AppendPadding ENDP


; ----------------------------------------------------------------------------------
GetQuotePos PROC
;
;	Calls: esi = Address of string
;
;	Finds the first quote in a string
;	Note: Goes into an infinite loop if no quote in string (TODO: <--Fix this)
;
;	Returns: esi = Address of string after first quote
; ----------------------------------------------------------------------------------

	L0 :
		mov al, [esi]
		inc esi
		cmp al, QUOTE
	jne L0

	ret
GetQuotePos ENDP


; ----------------------------------------------------------------------------------
ExtractParam PROC, pDestination:PTR BYTE
;
;	Calls:	esi = Address of command line arguments
;			pDestination = Address of Parameter
;
;	Populates the destination address with the first parameter found in esi
;
;	Returns: esi = Address of pDestination offset at one byte past the first parameter
; ----------------------------------------------------------------------------------

	call GetQuotePos
	mov edx, esi
	call GetQuotePos
	push esi

	mov ecx, esi
	dec ecx
	sub ecx, edx

	mov esi, edx
	mov edi, pDestination
	rep movsb

	pop esi

	ret
ExtractParam ENDP


; ----------------------------------------------------------------------------------
GetCmdArgs PROC
;
;	Populates CommandLineArgs with the command line arguments
; ----------------------------------------------------------------------------------

	mov edx, OFFSET CommandLineArgs
	call GetCommandTail

	mov esi, edx
	INVOKE ExtractParam, OFFSET Param0
	INVOKE ExtractParam, OFFSET Param1

	ret
GetCmdArgs ENDP


; ----------------------------------------------------------------------------------
main PROC
;
;	Main Procedure
; ----------------------------------------------------------------------------------

	; Get command line arguments
	call GetCmdArgs

	; Validate input file param
	mov edx, OFFSET Param0
	call StrLength
	mov Param0Len, eax
	cmp eax, 3
	jl QUIT

	; Open input file
	call OpenInputFile
	cmp eax, INVALID_HANDLE_VALUE
	je ERR_CODE_1

	; Read from input file
	mov inFileHandle, eax
	mov edx, OFFSET inBuffer
	mov ecx, IN_BUFF_SZ
	call ReadFromFile
	jc ERR_CODE_2
	mov bytesRead, eax

	; Close input file
	mov eax, inFileHandle
	call CloseFile

	call AppendPadding

	; Hash the file contents
	call MD5_Hash

	jmp QUIT

	; Validate output file param
	mov edx, OFFSET Param1
	INVOKE Str_compare, edx, ADDR DefaultKeyWord
	je CREATE_DEFAULT

	call StrLength
	mov Param1Len, eax
	cmp eax, 3
	jle QUIT
	
	; Open Existing File
	INVOKE CreateFile, edx, GENERIC_WRITE, DO_NOT_SHARE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	cmp eax, INVALID_HANDLE_VALUE
	je ERR_CODE_4
	jmp SEEK_EOF

	CREATE_DEFAULT :
	mov ecx, Param0Len
	std
	mov al, PERIOD
	lea edi, [Param0 + ecx]
	repne scasb

	cld
	inc ecx
	mov esi, OFFSET Param0
	mov edi, OFFSET Param1
	rep movsb

	mov ecx, LENGTHOF DefaultFileName
	mov esi, OFFSET DefaultFileName
	rep movsb

	mov edx, OFFSET Param1
	call CreateOutputFile
	cmp eax, INVALID_HANDLE_VALUE
	je ERR_CODE_3
	jmp SEEK_EOF
		
	SEEK_EOF :
	mov outFileHandle, eax
	INVOKE SetFilePointer, outFileHandle, 0, 0, FILE_END

	; Populate outBuffer
	;mov ecx, Param0Len
	;mov edi, OFFSET outBuffer
	;mov esi, OFFSET Param0
	;rep movsb

	;mov ecx, DIGEST_SZ + 2
	;mov esi, OFFSET digest
	;rep movsb

	;mov edx, OFFSET outBuffer
	;call WriteString

	; Append the hash value to the end
	;INVOKE WriteFile, outFileHandle, ADDR outBuffer, DIGEST_SZ + 2, ADDR bytesWritten, 0
	;INVOKE CloseHandle, outFileHandle
	
	jmp QUIT


	ERR_CODE_1 :
		mWrite "Unable to open the input file"
		jmp QUIT

	ERR_CODE_2 :
		mWrite "There was a problem reading from the input file"
		call WriteWindowsMsg
		call CloseFile
		jmp QUIT

	ERR_CODE_3:
		mWrite "Unable to create the default output file"
		jmp QUIT

	ERR_CODE_4 :
		mWrite "Unable to open the output file"

	QUIT:

	INVOKE ExitProcess, 0

main ENDP
END main