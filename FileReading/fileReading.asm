.model tiny
.code

    org 80h		
    cmd_length DB ?
    cmd_line DB ?
    org 100h	
	
start:

    JMP main

display macro str
  
        PUSH AX
        PUSH DX
		
        LEA DX, str
        MOV AH, 09h
        INT 21h
		
        POP DX
        POP AX 
		
endm

handler09 proc; is CALLed by 09h, AL - scancode
	
	PUSH ES	
	PUSH AX
	
	IN AL, 60h
	
	CMP AL, 1Dh
	JNE notCtrlDown
	MOV ctrlHeld, 01h
	JMP handleFinish
	
notCtrlDown:

	CMP	AL, 9Dh
	JNE notCtrlUp
	MOV ctrlHeld, 0
	JMP handleFinish
	
notCtrlUp:

	CMP AL, 2Eh
	JNE notCDown
	CMP ctrlHeld, 01h
	JNE notCDown
	MOV displayPerm, 0
	JMP handleFinish
	
notCDown:
	
	CMP AL, 0AEh
	JE handleFinish
	MOV displayPerm, 01h
	
handleFinish:

	MOV AL, 20h
	OUT 20h, AL
	POP AX
	POP ES
	IRET
	
endp

;handler1B proc
;
;    MOV displayPerm, 0
;    IRET
;	
;endp

main:

	CLD
	MOV CL, cmd_length
	CMP CL, 0
	JNE fileNamePassing
	LEA DX, noFile
	JMP exit
	
fileNamePassing:

	MOV CX, -1
	LEA DI, cmd_line+1
	MOV AL, 0Dh
	REPNE SCASB
	DEC DI
	MOV BYTE PTR [DI], 0

    MOV AH, 3Dh        		;open file
    MOV AL, 00h				;mode - read
    LEA DX, cmd_line+1		;file name
    INT 21h
	
        JNC noCarry
		CMP AX, 02h
		MOV DX, OFFSET fileNotFound
		CMP AX, 03h
		MOV DX, OFFSET pathNotFound
		CMP AX, 04h
		MOV DX, OFFSET tooManyOpenFiles
		CMP AX, 05h
		MOV DX, OFFSET accessDenied
		CMP AX, 0Ch
		MOV DX, OFFSET invalidAccess
		JMP exit
		
noCarry:		
		
    MOV fileDescriptor, AX
	
    MOV AH, 35h					;get int. address
    MOV AL, 09h					;interruption - 09h
    INT 21h
	MOV WORD PTR int09h + 2, ES		;ES - segment address of interruption
    MOV WORD PTR int09h, BX		;BX - offset of interruption

    ;MOV AH, 35h				;get address of INT 23h
    ;MOV AL, 1Bh
    ;INT 21h
	;MOV WORD PTR int1Bh + 2, ES
    ;MOV WORD PTR int1Bh, BX
	
	PUSH CS
	POP DS

    MOV AH, 25h				;set INT address
    MOV AL, 09h				;of INT 09h
    MOV DX, OFFSET handler09	;to procedure handler09
    INT 21h

    ;MOV AH, 25h				;also set INT 23h to a handle
    ;MOV AL, 1Bh
    ;MOV DX, OFFSET handler1B
    ;INT 21h
	
    MOV BX, fileDescriptor
	
mainLoop:

		MOV AH, 3Fh
        MOV CX, 1
        MOV DX, OFFSET readSymbol
        INT 21h						;read one symbol from file
        JC mainLoopExit
        CMP AX, 0
        JE mainLoopExit
        
        MOV AH, 02h			;AH=02h - symbol to STDOUT
		MOV DL, readSymbol
        
mainLoopWait:
		
        CMP displayPerm, 0			;wait until displayPerm is 1
        JE mainLoopWait

        INT 21h

		MOV AH, 86h			;INT 15h AH=86h  - BIOS sleep
        MOV CX, 1
        MOV DX, 1h
        INT 15h

        JMP mainLoop
    
mainLoopExit:

    MOV AH, 3Eh			;close file
    MOV BX, fileDescriptor
    INT 21h

    MOV AH, 25h
    MOV AL, 09h
    PUSH DS
    MOV DS, WORD PTR CS:int09h + 2
    MOV DX, WORD PTR CS:int09h
    INT 21h
    POP DS

    ;MOV AH, 25h
    ;MOV AL, 1Bh
    ;PUSH DS
    ;MOV DS, WORD PTR CS:int1Bh + 2
    ;MOV DX, WORD PTR CS:int1Bh
    ;INT 21h
    ;POP DS
	
	MOV DX, OFFSET success

exit:

	MOV AH, 09h
	INT 21h

    RET
	
	fileNotFound DB "file could not be found", 0Dh, 0Ah, '$'
	pathNotFound DB "path could not be found", 0Dh, 0Ah, '$'
	tooManyOpenFiles DB "too many open files", 0Dh, 0Ah, '$'
	accessDenied DB "access denied", 0Dh, 0Ah, '$'
	invalidAccess DB "invalid access mode", 0Dh, 0Ah, '$'
	noFile DB "no file name passed in cmd", 0Dh, 0Ah, '$'
	success DB "success!", 0Dh, 0Ah, '$'
	int1Bh          DD ?
    int09h          DD ?
    displayPerm     DB 01h
    fileDescriptor  DW ?
    readSymbol      DB ?
	ctrlHeld 		DB 0
	

end start