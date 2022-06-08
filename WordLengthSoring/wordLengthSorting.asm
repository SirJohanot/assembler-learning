.model small
.stack 100h
.data
     string DB 200, 200 dup ('$')  
     query_line DB "Input the string to be sorted", 10,13,"$" 
     finish_line DB 10,13,"Sorted string:", 10, 13, "$"

.code   
JMP start  
    
	print_str MACRO out_str
		MOV AH, 09h
		LEA DX, out_str
		INT 21h
	ENDM
	
     reverse PROC        ;si - begin, di - end of substring
          PUSH SI        ;save all values used in this procedure to stack
          PUSH DI
          PUSH AX
          PUSH BX

          CLD              ;DF = 0 to increment address with SI and DI instead of decrementing on deaddressing
          cycle:
               MOV AL, [SI];swapping symbols
               MOV BL, [DI]
               MOV [SI], BL
               MOV [DI], AL 

               DEC DI      ;moving borders towards each other
               INC SI
               CMP SI, DI 
          JL cycle         ;repeat cymbol swapping if borders are yet to meet   

          POP BX           ;rollback changes to register values
          POP AX
          POP DI
          POP SI
          RET
     reverse ENDP   
     
start:
     MOV AX, @data         ;write data segment to DS and ES
     MOV DS, AX 
     MOV ES, AX     
         
	 print_str query_line  ;print query to stdout
	
     MOV AH, 0ah           ;read inputted string to buffer
     LEA DX,string
     INT 21h  
                         
     LEA SI,string         ;address of the byte representing max length to SI
     LEA DI,string+2       ;address of the start of string to DI
     
	 XOR CX, CX            ;set CX byte to 0
     MOV CL, string+1      ;byte representing the length of the inputted string to CL
	 INC CL                ;increment CL by 1 (because carriage return is not included in the length)
	 
	 MOV DI, CX            ;calculated string length to DI
	 ADD DI, 2             ;increment string length by 2
	 MOV [string+DI], '$'  ;add $ to the end of the string(previously incremented by 2 to skip max_len byte and actual_len byte)
     PUSH CX               ;save index of the end of the string to stack
cycle_reset_to_start:            
     POP CX                ;overriding current cx with index of the end of the string stored in the stack 
     PUSH CX               ;pushing back the end index of string
     
     LEA SI,string+2       ;address of start of string - to SI
     PUSH SI               ;saving address of start of string to stack
     
     LEA DI,string+2       ;address of start of string - to DI
     
     MOV AL, ' '           ;we will look for spaces in the string in the future
     
     XOR BX,BX             ;set BX to 0
words_cycle:   
     MOV SI, DI            ;copy DI(index of start of current word) to SI
     REPNE SCASB           ;increment DI until space is found (space is stored in AL)
     DEC DI                ;move position from start of next word to space
                           
     PUSH DI               ;position of the end of the word to stack
                           
     SUB DI, SI            ;counting current word len (index of end - index of start)
     MOV DX, DI            ;copying calculated length to DX
                           
     POP DI                ;getting index of word end from stack           
                           
     CMP DX, BX            ;compare len of previous word and current(prev. word length is stored in BX)                      
     JL short swap_condition   ;if previous word is bigger than current -> swap
     
     MOV BX, SI            ;saving start of current word to BX
     POP SI                ;popping start of string to SI
     MOV SI, BX            ;start of current word to SI
     MOV BX, DX            ;current word length to BX
     PUSH SI               ;saving start of current word     
     INC DI                ;move index of word end to next space
     JCXZ short complete       ;if cx == 0 -> jump to end(full loop over the full string provides such condition)
     INC CX                ;increment CX
LOOP words_cycle           ;loop until CX!=0, decrements CX
                           
swap_condition:            ;swap neighbouring words by reversing them one by one and then reversing both at the same time()
     DEC DI                ;change position from space to symbol
     CALL reverse          ;reverse the word to the right
     SUB SI, 2             ;move position to end of the left word
     MOV AX, SI            ;save position to AX
     POP SI                ;pop start of left word(pushed in words loop)
     PUSH DI               ;save the end of the right word
     MOV DI, AX            ;end of left word pos to DI 
     CALL reverse          ;reverse the word to the left
     POP DI                ;load the end of the right word
     CALL reverse          ;reverse of both words
     JMP short cycle_reset_to_start     ;restart loop

complete:   
     print_str finish_line ;print statement to stdout
     print_str string+2    ;print resulting string to stdout
     MOV AH, 4Ch
     INT 21h               ;end EXE program

     END start