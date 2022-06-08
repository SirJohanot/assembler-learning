.model tiny
.code
	org 80h
	cmd_length DB ?
	cmd_line DB ?
	org 100h
start:
	
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
		MOV SI, DI
		MOV BYTE PTR [SI], 0
		;LEA DX, cmd_line+1
		;XOR AX, AX
		;MOV AH, 09h
		;INT 21h
		;RET
		
file:

        MOV AH, 3Dh ;open file       
        MOV AL, 02h ;read write permisSIons 
        LEA DX, cmd_line+1 
        INT 21h
			
        JNC noExit
		CMP AX, 02h
		LEA DX, fileNotFound
		CMP AX, 03h
		LEA DX, pathNotFound
		CMP AX, 04h
		LEA DX, tooManyOpenFiles
		CMP AX, 05h
		LEA DX, accessDenied
		CMP AX, 0Ch
		LEA DX, invalidAccess
		JMP exit
		
noExit:
        MOV fileHandle, AX	
		
        MOV AX, 4200h  ; AH=42h LSEEK   AL=0 start of file   
        XOR CX, CX 
        XOR DX, DX        	;offset to 0 (CX:DX == 0)
        MOV BX, fileHandle   
        INT 21h
       
readSymbolsLoop:

		MOV AX, 4201h  ; AH=42h LSEEK   AL=1 current position   
        XOR CX, CX 
        XOR DX, DX        	;offset to 0
        MOV BX, fileHandle   
        INT 21h

        MOV AH, 3Fh      ;read to buffer
        LEA DX, bufferString		;where to read
		MOV CX, 100		;number of bytes to read
        INT 21h
		CMP AX, CX			;AX - how many files were read
		JGE symbolsLeft
		MOV readExitFlag, 01h
		
symbolsLeft:

		MOV CX, AX
		XOR AX, AX
       
		;MOV AH, 09h
		;LEA DX, bufferString
		;INT 21h
		;RET
       
		CMP CX, 0
		JE end1
        LEA DI, bufferString
		XOR AX, AX
		XOR BX, BX

clearingLoop:

		;MOV DL, [DI]
		;MOV AH, 02h
		;INT 21h
		
		MOV BL, BYTE PTR [DI]
        CMP BL, 0Ah
		JNE setInfLineFlag
		CMP infLineFlag, 01h
		JNE incrementNonInfLineCount
		MOV infLineFlag, 0
		
loopEnd:

		INC DI
		LOOP clearingLoop
		CMP readExitFlag, 1
		JNE readSymbolsLoop
		JMP end1
		
incrementNonInfLineCount:

		LEA DX, incrNonInf
		MOV AH, 09h
		INT 21h

		INC nonInfLinesCount
		
		;MOV AH, 2
		;XOR DX, DX
		;MOV DL, '1'
		;INT 21h
		
		MOV infLineFlag, 0
		JMP loopEnd
        
setInfLineFlag:


		CMP BL, 0Dh
		JE loopEnd
		MOV infLineFlag, 01h
		JMP loopEnd
		
end1: 

		MOV AH, 3Eh			;close file
		MOV BX, fileHandle
        INT 21h
        
		MOV AH, 3Dh      	;open it again   
        MOV AL, 02h        
        LEA DX, cmd_line+1 
        INT 21h
		
        JNC noCarry
		CMP AX, 02h
		LEA DX, fileNotFound
		CMP AX, 03h
		LEA DX, pathNotFound
		CMP AX, 04h
		LEA DX, tooManyOpenFiles
		CMP AX, 05h
		LEA DX, accessDenied
		CMP AX, 0Ch
		LEA DX, invalidAccess
		JMP exit

noCarry:
        MOV fileHandle, AX     
		
        MOV AX, 4200h     
        XOR CX, CX         
        XOR DX, DX         
        MOV BX, fileHandle    
        INT 21h

		;MOV AH, 40h
        ;XOR CX, CX
        ;MOV BX, fileHandle
        ;INT 21h
		
		;MOV AX, 4200h     
        ;XOR CX, CX         
        ;XOR DX, DX         
        ;MOV BX, fileHandle    
        ;INT 21h
		
		CMP nonInfLinesCount, 0
		JE closeFile
		
         
nonInfLinesWriting:

		LEA DX, writingNewLine
		MOV AH, 09h
		INT 21h
		
		MOV AH, 40h		;write to file (AX returns how many were written)
        MOV CX, 02h		;2 bytes
        LEA DX, newLine	;location of those bytes
        MOV BX, fileHandle
        INT 21h
		
		DEC nonInfLinesCount
		CMP nonInfLinesCount, 0
		JNE nonInfLinesWriting
               
closeFile:

        MOV AH, 3Eh        
        INT 21h
		
        MOV AH, 09h
        LEA DX, pressAnyKey
        INT 21h
    
        MOV AH, 01h
        INT 21h
		LEA DX, success
exit:
		MOV AH, 09h
		INT 21h
		
		RET
		
	pressAnyKey DB "press any key...", 0Dh, 0Ah, '$' 
	fileNotFound DB "file could not be found", 0Dh, 0Ah, '$'
	pathNotFound DB "path could not be found", 0Dh, 0Ah, '$'
	tooManyOpenFiles DB "too many open files", 0Dh, 0Ah, '$'
	accessDenied DB "access denied", 0Dh, 0Ah, '$'
	invalidAccess DB "invalid access mode", 0Dh, 0Ah, '$'
	noFile DB "no file name passed in cmd", 0Dh, 0Ah, '$'
	success DB "success!", 0Dh, 0Ah, '$'
	writingNewLine DB "writing newline", 0Dh, 0Ah, '$'
	incrNonInf DB "incrementing non-inf line count", 0Dh, 0Ah, '$'
    bufferString DB 100 DUP(?)  
    fileHandle DW ?
	newLine DB 0Dh, 0Ah
	nonInfLinesCount DW 0
	readExitFlag DB 0
	infLineFlag DB 0

end start