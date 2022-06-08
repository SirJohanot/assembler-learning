.model tiny
.code

    org 80h		
    cmd_length DB ?
    cmd_line DB ?
    org 100h	
	
start:

    CLD
    MOV CL, cmd_length
    CMP CL, 01h         			
    JNL parameterPassed
	MOV DX, OFFSET noParametersPassed
	JMP exit

parameterPassed:

    MOV CX, -1
    MOV DI, OFFSET cmd_line    	
	
getParam:           			

    MOV AL, ' '
    REPE SCASB
    DEC DI
    CALL getExecNumber
	CMP execNum, 0
	JG execute
	MOV DX, OFFSET noParametersPassed
	JMP exit
		
execute:     

	stack_offset = program_length + 100h + 200h
    MOV SP, stack_offset

    MOV AH, 4Ah							;4Ah - resize current memory block (AX - new block seg address)
    MOV BX, stack_offset SHR 4 + 1  	;new size of block (ES is already the seg adress of the programm because COM)
    INT 21h

    MOV AX, CS							;set environment
    MOV WORD PTR EPB+4, AX   			;command line seg
    MOV WORD PTR EPB+8, AX     			;first FCB seg
    MOV WORD PTR EPB+0Ch, AX    		;second FCB seg

	XOR CX, CX
    MOV CL, execNum    					;number to CX for loop
	
cycle:

    CALL incNumber
	CALL printNumber
	
    MOV AX, 4B00h						;AH = 4Bh - execute, AL = 00h - load and execute
    MOV DX, OFFSET executable					;path to program (DS:DX)
    MOV BX, OFFSET EPB							;offset of EPB to BX
    INT 21h             				
	
	JNC next
	CMP AX, 02h
	MOV DX, OFFSET fileNotFound
	CMP AX, 08h
	MOV DX, OFFSET notEnoughMemory
	CMP AX, 0Ah
	MOV DX, OFFSET invEnv
	CMP AX, 0Bh
	MOV DX, OFFSET invFormat
	JMP exit
	
next:

    LOOP cycle
	MOV DX, OFFSET success

exit:

	MOV AH,  09h
	INT 21h
	
	MOV AH, 01h
	INT 21h
	
    INT 20h								; INT 20h because stack has been moved

getExecNumber PROC 

	PUSH CX
	PUSH AX

getExecNumberLoop:

	XOR CX, CX
	MOV CL, BYTE PTR [DI]
	CMP CL, '0'
	JL getExecNumberEnd
	CMP CL, '9'
	JG getExecNumberEnd
	SUB CL, 30h
	MOV AL, execNum
	MUL execNumBase
	ADD AX, CX
	MOV execNum, AL
	INC DI
	JMP getExecNumberLoop
	
getExecNumberEnd:

	POP AX
	POP CX
	
	RET
	
ENDP

incNumber PROC
	
	PUSH AX

	INC [currentIterationDisplay+10]
	CMP [currentIterationDisplay+10], '9'
	JLE enpProc
	MOV [currentIterationDisplay+10], '0'
	INC [currentIterationDisplay+9]
	CMP [currentIterationDisplay+9], '9'
	JLE enpProc
	MOV [currentIterationDisplay+9], '0'
	INC [currentIterationDisplay+8]
	
	
enpProc:	
	
	POP AX
	
	RET
	
ENDP

printNumber PROC

    PUSH AX 
	PUSH DX
	

    MOV AH, 09h                                 
    MOV DX, OFFSET currentIterationDisplay
    INT 21h

	POP DX 
	POP AX
	
	RET
	
ENDP

 
	noParametersPassed DB "you need to pass the number of executions to cmd!(1 - 255)",  0Dh,  0AH,  '$'
	fileNotFound DB "file could not be found", 0Dh, 0Ah, '$'
	accessDenied DB "access to file denied", 0Dh, 0Ah, '$'
	notEnoughMemory DB "not enough memory is available for execution", 0Dh, 0Ah, '$'
	invEnv DB "invalid environment", 0Dh, 0Ah, '$'
	invFormat DB "invalid format", 0Dh, 0Ah, '$'
	success DB "success!", 0Dh, 0Ah, '$'
	
	currentIterationDisplay DB "Process 000:",  0Dh,  0AH,  '$'
	
	EPB DW 0000                    ;current env
		DW offset commandline, 0        ;command line address
		DW 005Ch, 0, 006Ch, 0             ;FCB addresses
		
	commandline DB 125             ;command line length
				DB " /?"                       
				
	execNumBase DB 10
	executable DB "c:\asm\helloCom.com",  0
	execNum DB 0
	program_length EQU $-start     ; длина программы

end start