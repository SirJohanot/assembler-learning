.model small
.stack 200h
.data 
    entrInBsStr DB "enter initial base (2-16):", 0Dh, 0Ah, '$'
    entrInNumStr DB 0Dh, 0Ah, "enter initial number:", 0Dh, 0Ah, '$'
    entrNewBsStr DB 0Dh, 0Ah, "enter new base (2-16):", 0Dh, 0Ah, '$'
    trnslStr DB 0Dh, 0Ah, "new number:", 0Dh, 0Ah, '$'
    overStr DB 0Dh, 0Ah, "overflow!", 0Dh, 0Ah, '$'
    illStr DB 0Dh, 0Ah, "unsupported characters!", 0Dh, 0Ah, '$'
    wrongBsStr DB 0Dh, 0Ah, "unsupported base!", 0Dh, 0Ah, '$'
    wrongNumStr DB 0Dh, 0Ah, "the inputted number does not suit the base!", 0Dh, 0Ah, '$'
    errStr DB "program terminated", 0Dh, 0Ah, '$'
    emptyStr DB 0Dh, 0Ah, "nothing has been entered", 0Dh, 0Ah, '$' 
	simBssStr DB 0Dh, 0Ah, "bases are equal", 0Dh, 0Ah, " no need for translation", 0Dh, 0Ah, '$'            
	tmp DB 200,?,200 DUP('$')
	inNum DW 0h
	inBase DW 0h
	finBase DW 0h
	finNum DW 0h
	isNegative DW 0h
	sign DW 0h
	tmpVal DW 0h
.code
;;;;;;;;;;;;;;;;;; 
display macro string
    LEA DX, string
    MOV AH, 09h
    INT 21h
endm 
;;;;;;;;;;;;;;;;;
input macro string
    LEA DX, string
    MOV AH, 0Ah
    INT 21h
endm
;;;;;;;;;;;;;;;;;;;;;;;;;
main:
    MOV AX, @data
    MOV DS, AX  

	;initial base;
	
    display entrInBsStr
    
    input tmp
    XOR AX, AX     
    MOV AL,tmp[1]	;inputted string size to AL
    CMP AL,0
    JNE notEmpty1     	;inputted string is empty
    JMP empty
	
notEmpty1:
	
    MOV CX, AX
    MOV BX, 10
    LEA DI, tmp+2	;address of beginning of string to DI
    CALL stringToNum
    JNO noOverflow1
	JMP overflow
	
noOverflow1:
	
    CMP DX, 0FFFFh 
    JNE noIllChar1
	JMP illChar

noIllChar1:
	
    CMP DX, 0EEEEh
    JNE noIllNum1
	JMP illNum

noIllNum1:
	
    CMP DX, 1h
    JNE noIllBase1
	JMP illBase
	
noIllBase1:	
	
	CALL checkBase 
    CMP DX, 0h
    JNE noIllBase2
	JMP illBase
	
noIllBase2:	
	
	MOV inBase, AX
	
	;;;;;;;;;;;;;;;;;;;;;;
    
	;initial number;
	
    display entrInNumStr
    
    input tmp
    XOR AX, AX     
    MOV AL,tmp[1]	;inputted string size to AL
    CMP AL,0        
    JNE notEmpty2     	;inputted string is empty
    JMP empty
	
notEmpty2:
    
	MOV CX, AX
    MOV BX, inBase
    LEA DI, tmp+2
    CALL stringToNum
    JNO noOverflow2
	JMP overflow
	
noOverflow2:

    CMP DX, 0FFFFh 
    JNE noIllChar2
	JMP illChar

noIllChar2:
	
    CMP DX, 0EEEEh 
    JNE noIllNum2
	JMP illNum

noIllNum2:
	
    MOV inNum, AX
    CMP DX, 1h
    JNE signConfirmed
    INC isNegative
	
	;;;;;;;;;;;;;;;;;;;;;;;;
    
signConfirmed:

	;new base;
	
    display entrNewBsStr
    
    input tmp
    XOR AX, AX     
    MOV AL,tmp[1]	;inputted string size to AL
    CMP AL,0        
    JNE notEmpty3        ;inputted string is empty
	JMP empty
	
notEmpty3:
    
	MOV CX, AX
	MOV BX, 10
    LEA DI, tmp+2
    CALL stringToNum
    JO overflow
    CMP DX, 0FFFFh 
    JE illChar
    CMP DX, 0EEEEh
    JE illNum 
    CMP DX, 1h
    JE illBase
    MOV finBase, AX  ;<<<<
    CALL checkBase 
    CMP DX, 0h
    JE illBase
	
	;;;;;;;;;;;;;;;;;;;;;;;;
    
	;same bases check;
	
    MOV AX, inBase
    CMP AX, finBase
    JE simBases		;new and initial bases are the same
    
	;;;;;;;;;;;;;;;;;;;;
	
    MOV AX, inNum
    MOV BX, finBase
    LEA DI, tmp+2    
    CALL translate     
    
    display trnslStr
    MOV AX, isNegative
    CALL printInRevOrder
    
    JMP end
illChar:
    display illStr
    JMP error
illBase:
    display wrongBsStr
    JMP error
illNum:
    display wrongNumStr
    JMP error
overflow:
    display overStr
    JMP error
simBases:
    display simBssStr
    JMP end 
empty:
    display emptyStr
    JMP end    
error:
    display errStr     
end:
    MOV AX, 4c00h
    INT 21h
    
;;;;;;;;;;;;;;;;
stringToNum PROC NEAR	;CX=string length, BX=base, DI=start of string
;puts sign in DX (0h=+, 01h=-) and the number in AX
    XOR DX, DX
    MOV sign, DX 	;clear
    MOV tmpVal, DX  ;clear
;sign check
    MOV DL, [DI]
    MOV AX, DX
    CMP AX, '+'
    JE signSkip
    CMP AX, '-'
    JNE start
    INC sign
signSkip:			;skip the + sign while translating
    INC DI
    DEC CX
start:    
    XOR AX, AX
    XOR DX, DX
next:
    MUL BX    
    JO finish1    
    
    MOV DL, [DI] 
    MOV tmpVal, AX
    MOV AX, DX 
    
lowCheck:    
    CMP AL, 'f'
    JA  charLocated
    CMP AL, 'a'
    JB highCheck
    SUB DL, 57h
    JMP checksPassed
    
highCheck:
    CMP AL, 'F'
    JA  charLocated
    CMP AL, 'A'
    JB numCheck
    SUB DL, 37h
    JMP checksPassed
     
numCheck:
    CMP AL, '9'
    JA  charLocated
    CMP AL, '0'
    JB 	charLocated
    SUB DL, 30h 
 
checksPassed:
    CMP bl, DL
    JBE wrongBase
            
possOvflwCheck:
    MOV AX, tmpVal
    CMP AX, 0FFF1h
    JBE noOverflow
    ADD AX, DX
    CMP AX, 3h
    JA noOverflow 
    MOV AX, tmpVal
    MUL BX
    JO finish1
    
noOverflow:    
    MOV AX, tmpVal
    ADD AX, DX
    JO finish1 
    INC DI
	DEC CX
	CMP CX, 0
	JE loopEnd
    JMP next
     
loopEnd:
    MOV DX, sign
    JMP finish1
wrongBase:
    MOV DX, 0EEEEh
    JMP finish1
charLocated:
    MOV DX, 0FFFFh
finish1:
    RET
stringToNum ENDP
;;;;;;;;;;;;;;;;   
checkBase PROC NEAR		;checks whether the base in AX is valid (2<=base<=16). DX=1 if valid, DX=0 if not
    CMP AX, 2
    JL wrong2		;base is less than 2
    CMP AX, 16
    JA wrong2		;base is more than 16
    MOV DX, 01h
    JMP finish2
wrong2:
    XOR DX, DX	;DX=0
finish2:
    RET
checkBase ENDP 
;;;;;;;;;;;;;;;;
translate PROC NEAR		;translates number with in AX to base in BX. the result's starting number is put in DI
    XOR CX, CX
    DEC DI
again:
    INC DI        
    XOR DX, DX
    DIV BX
    MOV [DI], DL	;mod to DS:DI 
    INC CX			;used in the displaying loop(printInRevOrder)
    CMP AX, 0
    JA again		;repeat until the initial number is zero
    
    RET
translate ENDP
;;;;;;;;;;;;;;;;
printInRevOrder PROC NEAR ;prints a number with end in DI and +/- in AX
    CMP AX, 0h
    JE nexta
    MOV DX, '-'
    INC DI
    INC CX
    JMP printCharacter
nexta:
    MOV DL, [DI]
    ADD DX, 30h
    CMP DX, 39h
    JLE printCharacter
    ADD DX,7
printCharacter:
    MOV AH, 2
    INT 21h
     
    DEC DI
    LOOP nexta  
    
    RET
printInRevOrder ENDP
;;;;;;;;;;;;;;;;;;;;;;
end main