.model small
.stack 100h
.data 
    gameOverFlag db 0

    obstacle equ 08FEh
	barrier dw obstacle, obstacle, obstacle, obstacle, obstacle
	
	delayTime dw 0A2C3h
               
    carPosition dw 3278
    carSize equ 3
	
    displayNumberTemplate dw 0700h
    
    leftBorder db 20
    rightBorder db 20
    
    deleteStr dw 00DBh, 00DBh, 00DBh		;empty characters
    
    scoreMsg dw 0753h, 0763h, 076Fh, 0772h, 0765h, 073Ah		;"Score" in bright-grey
    score dw 0
	
    exitMsg dw 0750h, 0772h,0765h,0773h,0773h,0720h,0745h,0753h,0743h,0720h,0774h, 076Fh, 0720h, 0765h, 0778h, 0769h, 0774h
    exitMessageSize db 17 
	
    gameOverMessage dw 0747h, 0761h, 076Dh, 0765h,0720h, 074Fh, 0776h, 0765h, 0772h
	gameOverSize db 9
	
    barrierCountdown db 10
	
.code
    
moveScreen PROC		;moves screen up

    MOV AH, 07h		;INT 10h AH 07h - scroll down window
    MOV AL, 1		;by 1 line
    XOR BH, BH
    XOR CX, CX		;upper row and left column numbers: 0
    MOV DH, 24		;lower row number:24
    MOV DL, 79		;right column number:79
    INT 10h
    RET    
	
moveScreen ENDP

nextFrameDelay PROC

    MOV AH, 86h		;INT 15h AH 86h - wait for CX:DX microseconds
	XOR CX, CX
    MOV DX, delayTime 
    INT 15h
	
	SUB delayTime, 10	;bump a the difficulty a little by decreasing delay
	RET
	
nextFrameDelay ENDP

deleteCar PROC

    MOV DI, carPosition
    MOV SI, OFFSET deleteStr
    MOV CX, carSize
    REP MOVSW     	;replace the current position of the car in vid memory with empty chars
	
deleteCar ENDP  
  
steerCheck PROC		;check user input to determine where to steer the car

    MOV AH, 01h		;get keyboard buffer state (scancode to AL)
    INT 16h
    MOV DL, AL
	
	XOR AX, AX
    MOV AH, 0Ch		;flush buffer
    INT 21h
	MOV AL, DL
	
    CMP AL, 'a'
    JE aPress
	
    CMP AL, 'd'
    JE dPress
	
    JMP steerCheckContinue 
	
aPress:
    SUB carPosition, 2
    JMP steerCheckContinue
	
dPress:
    ADD carPosition, 2
    JMP steerCheckContinue 
	
steerCheckContinue:   

    RET
	
steerCheck ENDP    

randomGenerator PROC	;generates a random value in DL using system clock (0-9)

    PUSH AX
    PUSH BX
    PUSH CX
	
    XOR BX, BX
    MOV AH, 2Ch 
    INT 21h			;get system time (CH - hours, CL - minutes, DH - seconds, DL - 1/100 of a second)
	MOV BL, DL
	
    MOV AH, 00h		
    INT 1Ah			;get tick counter value
	MOV AX, DX		;DX - lesser 2 bytes of that value
	
    MUL BX			;multiply that by 1/100's of a second and put the result in (DX AX)
    MOV AL, DL		;3rd byte of the result to AL, which leaves AX with the 2nd and 3rd bytes of the original result
    XOR DX, DX
	MOV BX, 10
    DIV BX   		;divide 0000 AX by 10 and put the mod in DX, which will be 0-9
	
    POP CX
    POP BX
    POP AX
	
    RET    
	
randomGenerator ENDP    

showBorder PROC		;uses randomness to bend the road to the right or to the left

    PUSH AX
	
    XOR DX, DX
    XOR DI, DI  
	
    CALL randomGenerator
    CMP DL, 3
    JBE left
	
    CMP DL, 6
    JA right

showBorderContinue:
    MOV DI, 0
    MOV CL, leftBorder
	
showBorderLoop:
    ADD DI, 2
    LOOP showBorderLoop	;loop until DI reaches new left border position
	
    MOV ES:[DI], obstacle  	;display obstacle 
	
    ADD DI, 80				;add the gap between left and right borders
    MOV ES:[DI], obstacle	;display right obstacle
	
    POP AX
	
    RET
	
left:
    CMP leftBorder, 1
    JE showBorderContinue
	
    DEC leftBorder
    INC rightBorder
    JMP showBorderContinue
	
right:
    CMP rightBorder, 1
    JE showBorderContinue
	
    INC leftBorder
    DEC rightBorder
    JMP showBorderContinue

showBorder ENDP

crashCheck PROC		;uses vid memory to chack if a crash of the car with the obstacle happened

    MOV SI, carPosition
    SUB SI, 160			;move index 1 row down
    MOV CX, carSize
	
crashCheckLoop:    
    MOV AX, ES:[SI]
    CMP AX, obstacle   
    JE crashConfirmed
	
    ADD SI, 2
    LOOP crashCheckLoop
    RET
	
crashConfirmed:
    MOV gameOverFlag, 1    
    RET    
	
crashCheck ENDP

showCar PROC  
   
    MOV DI, carPosition
    MOV ES:[DI],     08FEh
    MOV ES:[DI] + 2, 07FFEh
    MOV ES:[DI] + 4, 08FEh
	
    RET    
	
showCar ENDP    

showScore PROC 			;increments and displays player score

    INC score
    MOV DI, 24*160+70
    MOV SI, OFFSET scoreMsg
    MOV CX, 6
    REP MOVSW
    MOV AX, score
    MOV CX, 5
    MOV DI, 24*160+20+70
	
showScoreLoop:
    MOV BX, 10
    XOR DX, DX
    DIV BX    
    ADD DL, '0'
    ADD displayNumberTemplate, DX        
    MOV SI, OFFSET displayNumberTemplate
    MOVSW
    MOV displayNumberTemplate, 0700h
    SUB DI, 4
    LOOP showScoreLoop   
    RET
	
showScore ENDP 

createBarrier PROC		;uses random to spawn a barrier

    CALL randomGenerator
    XOR BX, BX
    XOR AX, AX
    MOV AL, DL    
    MOV BX, 8 
    MUL BX
    MOV DL, leftBorder  
    MOV DI, DX
    ADD DI, DX
    ADD DI, AX
    MOV SI, OFFSET barrier
    MOV CX, 5
    REP MOVSW
    
createBarrierEnd:
    RET
    
createBarrier ENDP

gameOverRoutine PROC 
    
    MOV AH, 06h
    XOR AL, AL
    XOR BH, BH
    XOR CX, CX
    MOV DH, 25
    MOV DL, 80
    INT 10h

    INC score
    MOV DI, 12*160+70
    MOV SI, OFFSET scoreMsg
    MOV CX, 6
    REP MOVSW
    MOV AX, score
    MOV CX, 5
    MOV DI, 12*160+20+70
    
    showScoreLoop1:
    MOV BX, 10
    XOR DX, DX
    DIV BX    
    ADD DL, '0'
    ADD displayNumberTemplate, DX        
    MOV SI, OFFSET displayNumberTemplate
    MOVSW
    MOV displayNumberTemplate, 0700h
    SUB DI, 4
    LOOP showScoreLoop1
     
    MOV DI, 13*160+64
    MOV SI, OFFSET exitMsg
    MOV CL, exitMessageSize
    REP MOVSW
    
    MOV DI, 11*160+72
    MOV SI, OFFSET gameOverMessage
    MOV CL, gameOverSize
    REP MOVSW  
	
close:
    MOV AH, 00
    INT 16h   
    CMP AL, 1BH
    JNE close   
    MOV AX, 0003h
    INT 10h 
    
    MOV AH, 4Ch
    INT 21h
    RET
	
gameOverRoutine ENDP    

begin:
    MOV AX, @data
    MOV DS, AX
	;XOR AX, AX
    ;MOV AL, 03h
    ;INT 10h 
    MOV AX, 0B800h		;video memory absolute address left half
    MOV ES, AX			;goes to ES
    
    XOR BX, BX
    XOR CX, CX
    MOV CL, 21
    fenceLoop0:
        MOV ES:[BX], obstacle
        ADD BX, 2
    LOOP fenceLoop0
    
    ADD BX, 39 * 2
    MOV CX, 80 - 39
    SUB CL, 21
    fenceLoop1:
        MOV ES:[BX], obstacle
        ADD BX, 2
    LOOP fenceLoop1
    CALL moveScreen
    
myLoop:

    CALL nextFrameDelay
    CALL deleteCar            
    CALL steerCheck
    CALL showBorder
    CALL crashCheck
    CMP gameOverFlag, 1
    JE gameOver
    CALL moveScreen
    CALL showCar
    CALL showScore 
	
    DEC barrierCountdown
    CMP barrierCountdown, 0
    JNE myLoop
	
    MOV barrierCountdown, 10
    CALL createBarrier		;create a barrier every 10 iterations
    JMP myLoop 
    
gameOver:
    CALL gameOverRoutine
        
end begin