;
; S-OS EMUZ80
;   Target: EMUZ80 + MEZ80RAM
;   Assembler: The Macro Assembler AS
;
; Modified by Satoshi Okue https://twitter.com/S_Okue
; Version 0.1 2023/4/25
;
; Z80DASM 1.2.0
; COMMAND LINE: Z80DASM -L -G 0X1300 -O S-OS.ASM SWORD2000.OBJ

	CPU Z80

;CR:		EQU	0DH
;LF:		EQU	0AH
;BS:		EQU	08H
;DEL:		EQU	7FH

CTRL_C:		EQU	03H
BEEP:		EQU	07H

KBUF_LEN:	EQU	81

UARTD:		EQU	00H		; Data Register
UARTC:		EQU	01H		; Control / Status Register

	ORG 1B00H

;------------------------
COLD:
	LD SP,(_STKAD)
	XOR A
	LD (_LPSW),A
	LD (_DVSW),A
	LD		(PRCONT),A
	CALL MPRNT
	DB	0DH,"<<<<< S-OS  EMUZ80 >>>>>"
	DB	0DH,0
	LD HL,(_USR)
	JP (HL)
VER:
	LD HL,01120H	; MZ-2000/2200 VER 2.0
	RET
;------------------------
PRINTS:
	PUSH	AF
	LD		A,' '
	CALL	PRINT
	POP		AF
	RET

LTNL:
	PUSH	AF
	LD		A,0DH
	CALL	PRINT
	POP		AF
	RET

NL:
	PUSH	AF
	LD		A,(PRCONT)
	OR		A
	CALL	NZ,LTNL
	POP		AF
	RET

PRINT:
	PUSH	AF
	CALL	CON_OUT
	CP		CR
	JR		NZ,PRINT1
	LD		A,LF
	CALL	CON_OUT
	XOR		A
	LD		(PRCONT),A
	POP		AF
	RET
	;
PRINT1:
	POP		AF
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD		D,A
	LD		A,(PRCONT)
	LD		B,0
	LD		C,A
	LD		HL,LINEBUF
	ADD		HL,BC
	LD		B,A
	LD		A,D
	LD		(HL),A
	LD		A,B
	INC		A
	LD		(PRCONT),A
	POP		HL
	POP		DE
	POP		BC
	POP		AF
	RET

MSX:
	PUSH AF
	PUSH DE
MSG1:
	LD A,(DE)
	INC DE
L135CH:
	OR A
	JR Z,MSX2
	CALL PRINT
	JR MSG1

MSG:
	PUSH AF
	PUSH DE
MSX1:
	LD A,(DE)
	INC DE
	CP 0DH
	JR Z,MSX2
	CALL PRINT
	JR MSX1
MSX2:
	POP DE
	POP AF
	RET

MPRNT:
	EX (SP),HL
	PUSH AF
MPRNT1:
	LD A,(HL)
	INC HL
	OR A
	JR Z,MPRNT9
	CALL PRINT
	JR MPRNT1
MPRNT9:
	POP AF
	EX (SP),HL
	RET

TAB:
	LD A,(PRCONT)
	SUB B
	CCF
	RET C
TAB1:
	CALL PRINTS
	INC A
	JR NZ,TAB1
	RET
;------------------------
LPRNT:
;	CP 0DH
;	JR NZ,L1396H
;	LD A,0AH
;L1396H:
;	PUSH BC
;	LD C,00H
;	LD B,A
;	CALL RDA
;	JR C,LPRNT1
;	LD A,B
;	OUT (0FFH),A
;	LD A,80H
;	OUT (0FEH),A
;	INC C
;	CALL RDA
;	JR C,LPRNT1
;	XOR A
;	OUT (0FEH),A
;LPRNT1:
;	LD A,B
;	POP BC
	RET

;RDA:
;	PUSH AF
;	PUSH BC
;	PUSH DE
;	LD DE,0
;	LD B,020H
;RDA1:
;	IN A,(0FEH)
;	AND 0DH
;	CP C
;	JR Z,RDA9
;	DEC DE
;	LD A,D
;	OR E
;	JR NZ,RDA1
;	DJNZ RDA1
;	XOR A
;	LD (_LPSW),A
;	POP DE
;	POP BC
;	POP AF
;	SCF
;	RET
;RDA9:
;	POP DE
;	POP BC
;	POP AF
;	OR A
;	RET

LPTON:
;	PUSH AF
;	LD A,01H
;	LD (_LPSW),A
;	POP AF
	RET

LPTOF:
;	PUSH AF
;	XOR A
;	LD (_LPSW),A
;	POP AF
	RET
;------------------------
GETL:
	PUSH	DE
	PUSH	HL
	CALL	GET_L
	LD		HL,LINEBUF
GETL1:
	LD		A,(HL)
	LD		(DE),A
	INC		HL
	INC		DE
	OR		A
	JR		NZ,GETL1
	;
	POP		HL
	POP		DE
	RET

GETKY:
	IN		A,(UARTC)
	AND		01H
	LD		A,0
	RET		Z
GETKY1:
	IN		A,(UARTD)
	CP		03H
	RET		NZ
	;
	LD		A,1BH
	RET

BRKEY:
	CALL	GETKY
	CP		1BH
	RET		NZ
BRKY1:
	CALL	GETKY
	CP		1BH
	JR		Z,BRKY1
	XOR		A
	RET

INKEY:
	CALL GETKY
	OR A
	JR Z,INKEY
	RET

PAUSE:
	CALL 	GETKY
	CP 		1BH
	JR		Z,PAUSE1
	CP		" "
	JR		NZ,PAUSE2
PA1:
	CALL	INKEY
	CP		1BH
	JR		NZ,PAUSE2
PAUSE1:
	EX (SP),HL
	LD A,(HL)
	INC HL
	LD H,(HL)
	LD L,A
	EX (SP),HL
	RET
PAUSE2:
	EX (SP),HL
	INC HL
	INC HL
	EX (SP),HL
	RET

BELL:
	PUSH	AF
BELL1:
	IN	A,(UARTC)
	AND	02H
	JR	Z,BELL1
	LD A,07H		; BEEP
	OUT	(UARTD),A
	POP	AF
	RET

;------------------------
PRTHL:
	LD A,H
	CALL PRTHX
	LD A,L
PRTHX:
	PUSH AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL PRTHX1
	POP AF
PRTHX1:
	CALL ASC
	JP PRINT

ASC:
	AND 0FH
	OR 30H
	CP 3AH
	RET C
	ADD A,07H
	RET

HEX:
	SUB "0"
	RET C
	CP 0AH
	JR C,HEX1
	CP 011H
	RET C
	SUB 07H
	CP 10H
HEX1:
	CCF
	RET

AHEX:
	PUSH BC
	LD A,(DE)
	INC DE
	CALL HEX
	JR C,AHEX1
	RRCA
	RRCA
	RRCA
	RRCA
	LD C,A
	LD A,(DE)
	INC DE
	CALL HEX
	JR C,AHEX1
	OR C
AHEX1:
	POP BC
	RET

HLHEX:
	CALL AHEX
	LD H,A
	CALL NC,AHEX
	LD L,A
	RET

;------------------------
CON_OUT:
	PUSH	AF
CON_OUT1:
	IN		A,(UARTC)
	AND		02H
	JR		Z,CON_OUT1
	POP		AF
	OUT		(UARTD),A
	RET

CR_LF:
	LD		A,CR
	CALL	CON_OUT
	LD		A,LF
	JP		CON_OUT

GET_L:
	PUSH	BC
	PUSH	HL
	LD		A,(PRCONT)
	LD		B,0
	LD		C,A
	LD		HL,LINEBUF
	ADD		HL,BC
GET_L1:
	CALL	INKEY
	CP		CTRL_C
	JR		Z,GL_BRK
	CP		CR
	JR		Z,GL_END
	CP		LF
	JR		Z,GL_END
	CP		BS
	JR		Z,GL_BS
	CP		DEL
	JR		Z,GL_BS
	LD		B,A
	LD		A,C
	CP		KBUF_LEN-1		; Buffer length
	JR		NC,GET_L1
	INC		C
	LD		A,B
	CALL	CON_OUT
	LD		(HL),A
	INC		HL
	JR		GET_L1
	;
GL_BS:
	LD		A,C
	AND		A
	JR		Z,GET_L1
	DEC		C
	DEC		HL
	LD		A,08H
	CALL	CON_OUT
	LD		A," "
	CALL	CON_OUT
	LD		A,08H
	CALL	CON_OUT
	JR		GET_L1
	;
GL_END:
	CALL	CR_LF
	LD		(HL),00H
	XOR		A
	LD		(PRCONT),A
	POP		HL
	POP		BC
	RET
	;
GL_BRK:
	LD		HL,LINEBUF
	LD		A,1BH
	LD		(HL),A
	INC		HL
	XOR		A
	LD		(HL),A
	LD		(PRCONT),A
	POP		HL
	POP		BC
	RET

;------------------------
WRISB:
;	PUSH HL
;	LD HL,(_SIZE)
;	LD (1152H),HL		; SIZE
;	LD HL,(_DTADR)
;	LD (1154H),HL		; DTADR
;	LD HL,(_EXADR)
;	LD (1156H),HL		; EXADR
;	POP HL
;	CALL TPACH
;	OR A
;	CALL Z,MZ24
;	CALL 0251H			; WRI
;	JR MZ20

TWRDSB:
;	PUSH HL
;	LD HL,(_DTADR)
;	LD (1154H),HL		; DTADR
;	POP HL
;	CALL TPACH
;	OR A
;	CALL Z,MZ24
;	CALL 0282H			; WRD
;	JR MZ20

RDISB:
;	CALL TPACH
;	OR A
;	CALL Z,MZ24
;	CALL 028EH			; RDI
;	PUSH HL
;	LD HL,(1152H)
;	LD (_SIZE),HL
;	LD HL,(1154H)
;	LD (_DTADR),HL
;	LD HL,(1156H)
;	LD (_EXADR),HL
;	POP HL
;	JR MZ20

TRDDSB:
;	PUSH HL
;	LD HL,(_SIZE)
;	LD (1152H),HL
;	LD HL,(_DTADR)
;	LD (1154H),HL
;	POP HL
;	CALL TPACH
;	OR A
;	CALL Z,MZ24
;	CALL 002B2H			; RDD

MZ20:			; MZ2000
;	PUSH HL
;	LD HL,0524H
;	LD (HL),02AH
;	LD HL,0530H
;	LD (HL),025H
;	LD HL,053FH
;	LD (HL),05AH
;	LD HL,054BH
;	LD (HL),055H
;	LD HL,0557H
;	LD (HL),041H
;	POP HL
;	RET

MZ24:
;	PUSH HL
;	LD HL,0524H
;	LD (HL),023H
;	LD HL,0530H
;	LD (HL),01EH
;	LD HL,053FH
;	LD (HL),04BH
;	LD HL,054BH
;	LD (HL),046H
;	LD HL,0557H
;	LD (HL),036H
;	POP HL
	RET
;------------------------
PEEK:
	XOR A
;	CALL DINT
;	PUSH HL
;	PUSH BC
;	LD BC,0C000H
;	ADD HL,BC
;	LD A,(HL)
;	JR POKE1

POKE:
;	CALL DINT
;	PUSH HL
;	PUSH BC
;	LD BC,0C000H
;	ADD HL,BC
;	LD (HL),A
;POKE1:
;	POP BC
;	POP HL
POKE2:
;	PUSH AF
;	IN A,(0E8H)
;	RES 7,A
;	SET 6,A
;	OUT (0E8H),A
;	POP AF
;	EI
;	RET

POKE_:
;	CALL DINT
;	PUSH BC
;	EX DE,HL
;	LD BC,0C000H
;	ADD HL,BC
;	EX DE,HL
;	POP BC
;	LDIR
;	JR POKE2

PEEK_:
;	CALL DINT
;	PUSH BC
;	EX DE,HL
;	LD BC,0C000H
;	ADD HL,BC
;	POP BC
;	LDIR
;	JR POKE2

	RET

;DINT:
;	DI
;	PUSH AF
;	LD A,1
;	OUT (0F7H),A
;	IN A,(0E8H)
;	SET 7,A
;	RES 6,A
;	JR DINT1
;------------------------
MXCNV:
	PUSH HL
	PUSH BC
	LD C,A
	LD B,0
	LD HL,MXTBL
	ADD HL,BC
	LD A,(HL)
MXCNV1:
	POP BC
	POP HL
	RET

XMCNV:
	PUSH HL
	PUSH BC
	LD C,A
	LD B,0
	LD HL,XMTBL
	ADD HL,BC
	LD A,(HL)
	JR MXCNV1

;DINT1:
;	OUT (0E8H),A
;	POP AF
;	RET
;
;	DS	2

MXTBL:
	DB	 00H, 01H, 02H, 03H, 04H, 05H, 06H, 07H, 08H, 09H, 0AH, 0BH, 0CH, 0DH, 0EH, 0FH	;00
	DB	 10H, 11H, 12H, 13H, 14H, 15H, 16H, 17H, 18H, 19H, 1AH, 1BH, 1CH, 1DH, 1EH, 1FH	;10
	DB	 20H, 21H, 22H, 23H, 24H, 25H, 26H, 27H, 28H, 29H, 2AH, 2BH, 2CH, 2DH, 2EH, 2FH	;20
	DB	 30H, 31H, 32H, 33H, 34H, 35H, 36H, 37H, 38H, 39H, 3AH, 3BH, 3CH, 3DH, 3EH, 3FH	;30
	DB	 40H, 41H, 42H, 43H, 44H, 45H, 46H, 47H, 48H, 49H, 4AH, 4BH, 4CH, 4DH, 4EH, 4FH	;40
	DB	 50H, 51H, 52H, 53H, 54H, 55H, 56H, 57H, 58H, 59H, 5AH, 5BH, 9FH, 5DH, 5EH, 5FH	;50
	DB	 60H, 61H, 62H, 63H, 64H, 65H, 66H, 67H, 68H, 69H, 6AH, 6BH, 6CH, 6DH, 6EH, 6FH	;60
	DB	 70H, 71H, 72H, 73H, 74H, 75H, 76H, 77H, 78H, 79H, 7AH, 87H, 7CH,0F0H, 7EH, 7FH	;70
	DB	 80H, 81H, 82H, 83H, 84H, 85H, 86H, 7BH, 88H, 89H, 8AH, 8BH, 8CH, 8DH, 8EH, 8FH	;80
	DB	 90H, 91H, 92H, 93H, 94H, 95H, 96H, 97H, 98H, 99H, 9AH, 9BH, 9CH, 9DH, 9EH, 5CH	;90
	DB	0A0H,0A1H,0A2H,0A3H,0A4H,0A5H,0A6H,0A7H,0A8H,0A9H,0AAH,0ABH,0ACH,0ADH,0AEH,0AFH	;A0
	DB	0B0H,0B1H,0B2H,0B3H,0B4H,0B5H,0B6H,0B7H,0B8H,0B9H,0BAH,0BBH,0BCH,0BDH,0BEH,0BFH	;B0
	DB	0C0H,0C1H,0C2H,0C3H,0C4H,0C5H,0C6H,0C7H,0C8H,0C9H,0CAH,0CBH,0CCH,0CDH,0CEH,0CFH	;C0
	DB	0D0H,0D1H,0D2H,0D3H,0D4H,0D5H,0D6H,0D7H,0D8H,0D9H,0DAH,0DBH,0DCH,0DDH,0DEH,0DFH	;D0
	DB	0E0H,0E1H,0E2H,0E3H,0E4H,0E5H,0E6H,0E7H,0E8H,0E9H,0EAH,0EBH,0ECH,0EDH,0EEH,0EFH	;E0
	DB	 7DH,0F1H,0F2H,0F3H,0F4H,0F5H,0F6H,0F7H,0F8H,0F9H,0FAH,0FBH,0FCH,0FDH,0FEH,0FFH	;F0

XMTBL:
	DB	 00H, 01H, 02H, 03H, 04H, 05H, 06H, 07H, 08H, 09H, 0AH, 0BH, 0CH, 0DH, 0EH, 0FH	;00
	DB	 10H, 11H, 12H, 13H, 14H, 15H, 16H, 17H, 18H, 19H, 1AH, 1BH, 1CH, 1DH, 1EH, 1FH	;10
	DB	 20H, 21H, 22H, 23H, 24H, 25H, 26H, 27H, 28H, 29H, 2AH, 2BH, 2CH, 2DH, 2EH, 2FH	;20
	DB	 30H, 31H, 32H, 33H, 34H, 35H, 36H, 37H, 38H, 39H, 3AH, 3BH, 3CH, 3DH, 3EH, 3FH	;30
	DB	 40H, 41H, 42H, 43H, 44H, 45H, 46H, 47H, 48H, 49H, 4AH, 4BH, 4CH, 4DH, 4EH, 4FH	;40
	DB	 50H, 51H, 52H, 53H, 54H, 55H, 56H, 57H, 58H, 59H, 5AH, 5BH, 9FH, 5DH, 5EH, 5FH	;50
	DB	 60H, 61H, 62H, 63H, 64H, 65H, 66H, 67H, 68H, 69H, 6AH, 6BH, 6CH, 6DH, 6EH, 6FH	;60
	DB	 70H, 71H, 72H, 73H, 74H, 75H, 76H, 77H, 78H, 79H, 7AH, 87H, 7CH,0F0H, 7EH, 7FH	;70
	DB	 80H, 81H, 82H, 83H, 84H, 85H, 86H, 7BH, 88H, 89H, 8AH, 8BH, 8CH, 8DH, 8EH, 8FH	;80
	DB	 90H, 91H, 92H, 93H, 94H, 95H, 96H, 97H, 98H, 99H, 9AH, 9BH, 9CH, 9DH, 9EH, 5CH	;90
	DB	0A0H,0A1H,0A2H,0A3H,0A4H,0A5H,0A6H,0A7H,0A8H,0A9H,0AAH,0ABH,0ACH,0ADH,0AEH,0AFH	;A0
	DB	0B0H,0B1H,0B2H,0B3H,0B4H,0B5H,0B6H,0B7H,0B8H,0B9H,0BAH,0BBH,0BCH,0BDH,0BEH,0BFH	;B0
	DB	0C0H,0C1H,0C2H,0C3H,0C4H,0C5H,0C6H,0C7H,0C8H,0C9H,0CAH,0CBH,0CCH,0CDH,0CEH,0CFH	;C0
	DB	0D0H,0D1H,0D2H,0D3H,0D4H,0D5H,0D6H,0D7H,0D8H,0D9H,0DAH,0DBH,0DCH,0DDH,0DEH,0DFH	;D0
	DB	0E0H,0E1H,0E2H,0E3H,0E4H,0E5H,0E6H,0E7H,0E8H,0E9H,0EAH,0EBH,0ECH,0EDH,0EEH,0EFH	;E0
	DB	 7DH,0F1H,0F2H,0F3H,0F4H,0F5H,0F6H,0F7H,0F8H,0F9H,0FAH,0FBH,0FCH,0FDH,0FEH,0FFH	;F0

;------------------------
;** FILE - FILE DISCRIPTER SET

FILE:
;	CALL FNAME
;	PUSH DE
;	LD HL,NAMEBF
;	LD DE,_IBFAD	; IBUF
;	LD BC,18
;	LDIR
;	POP DE
;	CALL SPCUT
;	OR A
	RET

;FNAME:
;	LD HL,NAMEBF
;	LD (HL),A
;	INC HL
;	LD (__FTYPE),A
;	CALL GETDEV
;	CALL __DEVCHK
;	RET C
;	LD (_DSK),A
;FILE2:
;	LD B,13
;	CALL FILE3
;	LD A,(DE)
;	JR NZ,L17D1H
;	LD A," "
;	DEC DE
;L17D1H:
;	CP "."
;	JR NZ,L17D8H
;	LD A," "
;	DEC DE
;L17D8H:
;	LD (HL),A
;	INC DE
;	INC HL
;	DJNZ FILE2+2
;	LD A,(DE)
;	CP "."
;	JR NZ,FILE21
;	INC DE
;FILE21:
;	LD B,3
;	CALL FILE3
;	LD A,(DE)
;	JR NZ,L17EEH
;	LD A," "
;	DEC DE
;L17EEH:
;	LD (HL),A
;	INC DE
;	INC HL
;	DJNZ FILE21+2
;	LD (HL)," "
;
;	LD A,(_DSK)
;	CALL __TPCHK
;	RET NZ
;
;	LD HL,NAMEBF+17
;	LD B,17
;MZ0DF:
;	LD A,(HL)
;	CP 021H
;	RET NC
;	LD A,00DH
;	LD (HL),A
;	DEC HL
;	DJNZ MZ0DF
;	RET
;
;FILE3:
;	PUSH DE
;	CALL SPCUT
;	LD A,(DE)
;	POP DE
;	CP ":"
;	RET Z
;	CP " "
;	JR NC,L181AH
;	CP A
;L181AH:
;	RET

;GETDEV:
;	CALL SPCUT
;	INC DE
;	LD A,(DE)
;	DEC DE
;	CP ":"
;	JR Z,L1829H
;	CALL _RDVSW
;	RET
;	;
;L1829H:
;	LD A,(DE)
;	INC DE
;	INC DE
;	CP "a"
;	RET C
;	CP "z"+1
;	RET NC
;	SUB " "
;	RET

FPRNT:
;	LD DE,1141H		; NAME
;	LD B,13
;	LD A,(DE)
;	CP " "
;	JR NC,L1842H
;	LD A," "
;	DEC DE
;L1842H:
;	CP "."
;	JR NZ,L1848H
;	LD A," "
;L1848H:
;	CALL PRINT
;	INC DE
;	DJNZ FPRNT+5
;
;FILPR1:
;	LD A,"."
;	CALL PRINT
;	LD B,3
;FILPR2:
;	LD A,(DE)
;	CP " "
;	JR NC,L185DH
;	LD A," "
;	DEC DE
;L185DH:
;	CALL PRINT
;	INC DE
;	DJNZ FILPR2
;	CALL PAUSE
;	DW	PAU11
;PAU11:
	RET

FSAME:
	XOR		A
;	AND 087H
;	LD B,A
;	LD HL,_IBFAD	; IBUF
;	LD A,(HL)
;	AND 087H
;	CP B
;	JP NZ,FSKIP
;	;
;	LD A,(__DFDV)
;	PUSH AF
;	LD A,(_DSK)
;	LD (__DFDV),A
;	CALL FNAME
;	POP AF
;	LD (__DFDV),A
;	LD DE,_IBFAD	; IBUF
;	LD HL,NAMEBF
;	LD B,16
;	CALL TCOMP
;	RET Z
;	;
;FSKIP:
;	LD A,8
;	OR A
	RET

CUTLP:
	INC DE
SPCUT:
	LD A,(DE)
	CP " "
	JR Z,CUTLP
	RET

;------------------------

;TROPN:
;	LD A,(_DSK)
;	CP "Q"
;	JR NZ,TROPN1
;	LD A,11
;	SCF
;	RET
;
;TROPN1:
;	LD A,(SKPFG)
;	OR A
;	JR Z,L18B2H
;	CALL APSS
;L18B2H:
;	XOR A
;	LD (SKPFG),A
;	CALL RDI
;	JR NC,TROPN2
;	RET
;TROPN2:
;	LD HL,NAMEBF
;	LD DE,_IBFAD	; IBUF
;	LD B,16
;	LD A,(DE)
;	AND 07H
;	CP (HL)
;	JR NZ,SKIP_
;	CALL TCOMP
;	JR NZ,SKIP_
;	RET
;
;TCOMP:
;	INC DE
;	INC HL
;	LD A,(HL)
;	CP 21H
;	JR NC,TCOMP1
;	XOR A
;	RET
;TCOMP1:
;	LD A,(HL)
;	CP "."
;	JR NZ,L18E0H
;	LD A," "
;L18E0H:
;	LD C,A
;	LD A,(DE)
;	CP "."
;	JR NZ,L18E8H
;	LD A," "
;L18E8H:
;	CP C
;	RET NZ
;	CP 0DH
;	RET Z
;	INC HL
;	INC DE
;	DJNZ TCOMP1
;	XOR A
;	RET
;
;SKIP_:
;	LD HL,NAMEBF
;	INC HL
;	LD A,(HL)
;	CP " "
;	RET Z
;	CP 0DH
;	RET Z
;	LD A,1
;	LD (SKPFG),A
;	RET
;	;
;SKPFG:	DEFB	0
;
;APSS:
;	DI
;	CALL 04B1H		; SERSP
;	CALL 04CEH		; MSTOP
;	EI
;	LD A,8
;	OR A
;	RET
;
;TDIR:
;	CALL RDI
;	RET C
;	LD HL,_IBFAD	; IBUF
;	LD A,(HL)
;	CALL __P_FNAM
;	CALL NL
;	CALL APSS
;	JR TDIR

;FLGET:
;	PUSH BC
;	PUSH HL
;	LD HL,(11D1H)	; DSPXY
;	CALL 0C2CH		; PNT1
;	LD (0003H),HL	; FLPOS
;	CALL 0C3EH		; DSPR
;	LD (DPCHR),A
;	LD A,(11D0H)	; KMODE
;	OR A
;	JP Z,XCH4
;FLGET1:
;	LD A,(CSCHR)
;	CALL PRNT
;	CALL KEYIN
;	OR A
;	JR NZ,SKEY_
;	LD A,(DPCHR)
;	CALL PRNT
;	CALL KEYIN
;	OR A
;	JR Z,FLGET1
;SKEY_:
;	CP 9
;	JR Z,GRAPH
;	CP 10
;	JR Z,LOCK
;	CP 12
;	JR Z,KANA
;	;
;	PUSH AF
;	LD A,(DPCHR)
;	CALL PRNT
;	POP AF
;	POP HL
;	POP BC
;	JP MXCNV
;;
;LOCK:
;	LD HL,XCH1+1
;	LD (HL),20H
;	LD HL,XCH2+1
;	LD (HL),20H
;	LD HL,XCH3+1
;	LD (HL),93H
;	JR XCH
;KANA:
;	LD HL,XCH1+1
;	LD (HL),80H
;	LD HL,XCH2+1
;	LD (HL),80H
;	LD HL,XCH3+1
;	LD (HL),86H
;	JR XCH
;GRAPH:
;	LD HL,XCH1+1
;	LD (HL),40H
;	LD HL,XCH2+1
;	LD (HL),40H
;	LD HL,XCH3+1
;	LD (HL),87H
;XCH:
;	LD A,(11D0H)	; KMODE
;XCH1:
;	AND 020H
;	JR NZ,XCH4
;XCH2:
;	LD A,20H
;	LD (11D0H),A	; KMODE
;XCH3:
;	LD A,93H
;	LD (CSCHR),A
;	JP FLGET1
;XCH4:
;	XOR A
;	LD (11D0H),A	; KMODE
;	LD A,01FH
;	LD (CSCHR),A
;	JP FLGET1
;;
;CSCHR:	DB	0
;DPCHR:	DB	0

;PRNT:
;	LD HL,(0003H)	; FLPOS
;	JP 0C50H		; DSPW
;
;KEYIN:
;	LD A,(RPFLG)
;	OR A
;	JR Z,KEYIN1
;	LD C,1
;	LD HL,KEY
;	JR KEYIN2
;KEYIN1:
;	LD C,16
;	CALL RKEY
;	LD HL,KEY
;	LD (HL),A
;KEYIN2:
;	LD B,50
;KEYIN3:
;	CALL RKEY
;	CP (HL)
;	JR Z,KEYIN4
;	LD HL,RPFLG
;	LD (HL),0
;	RET
;KEYIN4:
;	DJNZ KEYIN3
;	DEC C
;	JR NZ,KEYIN2
;	OR A
;	RET Z
;	LD HL,RPFLG
;	LD (HL),1
;	RET
;	;
;RKEY:
;	CALL KEYCLR
;	CALL 0832H		; GETKY
;	RET
;
;KEYCLR:
;	PUSH BC
;	PUSH DE
;	PUSH HL
;	XOR A
;	CALL 0901H		; NOKKY
;	POP HL
;	POP DE
;	POP BC
;	RET
;
;RPFLG:	DB	0
;KEY:	DB	0

;------------------------
BOOT:
	JP		0000H
;	IN A,(0E2H)
;	RES 3,A
;	OUT (0E2H),A

;------------------------
INP:
;	PUSH BC
;	LD B,0
;	IN A,(C)
;	POP BC
	RET

OUT:
;	PUSH BC
;	LD B,0
;	OUT (C),A
;	POP BC
	RET

SCRN:
	LD		A," "
;	PUSH HL
;	CALL LOCHK
;	JR NC,SCRN1
;	POP HL
	RET
;SCRN1:
;	CALL 0C2CH		; PNT1
;	CALL 0C3EH		; DSPR
;	CP	" "
;	JR NC,L1AD5H
;	LD A," "
;L1AD5H:
;	POP HL
;	RET

CSR:
	LD		HL,0
;	LD HL,(11D1H)	; DSPXY
	RET

LOC:
;	CALL LOCHK
;	RET C
;	LD (11D1H),HL	; DSPXY
	RET

;LOCHK:
;	PUSH BC
;	LD B,A
;	LD A,(_WIDTH)
;	DEC A
;	CP L
;	JR C,LCERR
;	LD A,B
;	POP BC
;	RET
;LCERR:
;	LD A,14
;	POP BC
;	RET

WIDCH:
;	CP 40+1
;	JR NC,WIDCH1
;	CALL 0CEEH		; WID40
;	LD A,40
;	JR WIDCH2
;WIDCH1:
;	CALL 0C7CH		; WID80
;	LD A,80
;WIDCH2:
;	LD (_WIDTH),A
	RET

;NAMEBF:
;	DS	18

;------------------------
;PRPACH:
;	CP 0DH
;	JP NZ,08C6H		; PRINT
;	PUSH AF
;	LD A,(11D0H)	; KMODE
;	PUSH AF
;	CALL 0A2EH		; LETNL
;	POP AF
;	LD (11D0H),A	; KMODE
;	POP AF
;	RET

;WRI:
;	CALL WRISB
;	JR SETER
;
;TWRD:
;	CALL TWRDSB
;	JR SETER
;
;RDI:
;	CALL RDISB
;	JR SETER
;
;TRDD:
;	CALL TRDDSB
;SETER:
;	RET NC
;	LD A,1
;	RET
;
;TPACH:
;	LD A,(_DSK)
;	CP "Q"
;	JR NZ,TPACH1
;	LD A,11
;	POP HL
;	POP HL
;	SCF
;	RET
;TPACH1:
;	CP "T"
;	RET NZ
;	XOR A
;	RET

;------------------------
	ORG	1F5BH

_MXLIN:	DB	25
_WIDTH:	DB	80
_DSK:	DB	"A"
_FATPS:	DW	000EH
_DIRPS:	DW	0010H
_FATBF:	DW	2E00H
_DTBUF:	DW	2F00H
_MXTRK:	DB	50H
_DIRNO:	DS	1
_WKSIZ:	DW	0		; 4000H
_MEMAX:	DW	0FFFFH	; MEMAX
_STKAD:	DW	2E00H	; STACK
_EXADR:	DW	0
_DTADR:	DW	0
_SIZE:	DW	0
_IBFAD:	DW	0		; IBUF
_KBFAD	DW	_KBUF	; KBUF
_XYADR	DW	DSPXY
_PRCNT	DW	PRCONT
_LPSW:	DB	0
_DVSW:	DB	0
_USR:	DW	HOT		; Application
_GETPC:
	POP	HL
	JP (HL)

	ORG	1F8EH
_MON:	JP 0000H	; Universal monitor
_PEEK_:	JP PEEK_
_PEEK:	JP PEEK
_POKE_:	JP POKE_
_POKE:	JP POKE
_FPRNT:	JP FPRNT
_FSAME:	JP FSAME
_FILE:	JP FILE
_RDD:	JP RDD
_FCB:	JP GETFCB	; #RDI
_WRD:	JP WRD
_WOPEN:	JP WOPEN	; #WRI
_HLHEX:	JP HLHEX
_2HEX:	JP AHEX
_HEX	JP HEX
_ASC	JP ASC
_PRTHL:	JP PRTHL
_PRTHX:	JP PRTHX
_BELL:	JP BELL
_PAUSE:	JP PAUSE
_INKEY:	JP INKEY
_BRKEY:	JP BRKEY
_GETKY:	JP GETKY
_GETL:	JP GETL
_LPTOF:	JP LPTOF
_LPTON:	JP LPTON
_LPRNT:	JP LPRNT
_TAB:	JP TAB
_MPRNT:	JP MPRNT
_MSX:	JP MSX
_MSG:	JP MSG
_NL:	JP NL
_LTNL:	JP LTNL
_PRNTS:	JP PRINTS
_PRINT:	JP PRINT
_VER:	JP VER
_HOT:	JP HOT
_COLD	JP COLD
;
_DRDSB:	JP DSKRED
_DWTSB:	JP DSKWRT
_DIR:	JP DIR
_ROPEN:	JP ROPEN
_SET:	JP SET
_RESET:	JP RESET
_NAME:	JP NAME
_KILL:	JP KILL
_CSR:	JP CSR
_SCRN:	JP SCRN
_LOC:	JP LOC
_FLGET:	JP INKEY	; FLGET
_RDVSW:	JP RDVSW
_SDVSW:	JP SDVSW
_INP:	JP INP
_OUT:	JP OUT
_WIDCH:	JP WIDCH
_ERROR:	JP ERROR
_BOOT:	JP BOOT


DSPXY		DW	0
PRCONT:		DB	0
LINEBUF:	DS	KBUF_LEN
_KBUF:		DS	KBUF_LEN

;----------------------------------------
; Extended S-OS / Disk Operationg System
;----------------------------------------

	ORG	2100H

HOT:
	LD SP,(_STKAD)
	CALL _LPTOF
	LD A,"#"
	CALL _PRINT
	LD DE,(_KBFAD)
	CALL _GETL
	CALL MCOM
	CALL C,_ERROR
	JR HOT

MCOM:
	LD A,(DE)
	CP "#"
	JR Z,L2122H
L2120H:
	OR A
	RET
L2122H:
	INC DE
	LD A,(DE)
	INC DE
	OR A
	RET Z
	CP "!"
	JP Z,MON	; _BOOT
	CP "J"
	JP Z,JUMP
;	CP "L"
;	JP Z,LOAD
;	CP "K"
;	JP Z,MKILL
;	CP "N"
;	JP Z,MNAME
	CP "M"
	JP Z,MON
;	CP "W"
;	JP Z,MWIDTH
;	CP "S"
;	JR Z,CMDSB1
;	CP "D"
;	JR Z,CMDSB2
	;
	CP "B"
	JR Z,LOAD_BASIC
	CP "L"
	JR Z,LOAD_LISP
	CP "F"
	JR Z,LOAD_FORTH
	CP "P"
	JR Z,LOAD_PROLOG
	CP "S"
	JR Z,LOAD_STACK
	;
	CP "H"
	JR Z,MON_HELP
	CP "S"
	JR Z,MON_HELP
	;
	LD A,13
	SCF
	RET
;;
;CMDSB1:
;	LD A,(DE)
;	CALL TOUPER
;	INC DE
;	CP "T"
;	JP Z,MSET
;	DEC DE
;	JP SAVE
;;
;CMDSB2:
;	LD A,(DE)
;	CALL TOUPER
;	INC DE
;	CP "V"
;	JP Z,DEVST
;	DEC DE
;	JP MDIR

JUMP:
	CALL SPCUT_D
	CALL _HLHEX
	LD A,13
	RET C
	EX DE,HL
	LD HL,HOT
	EX (SP),HL
	EX DE,HL
	JP (HL)

MON:
	JP _MON

LOAD_BASIC:
	OUT		(10H),A
	RET

LOAD_LISP:
	OUT		(11H),A
	RET

LOAD_FORTH:
	OUT		(12H),A
	RET

LOAD_PROLOG:
	OUT		(13H),A
	RET

LOAD_STACK:
	OUT		(14H),A
	RET

MON_HELP:
	CALL MPRNT
	DB	0DH,"< S-OS EMUZ80 HELP >"
	DB	0DH,"M - Universal Monitor"
	DB	0DH,"J[ADDRESS]"
	DB	0DH
	DB	0DH,"B - LOAD FuzzyBASIC"
	DB	0DH,"F - LOAD magiFORTH"
	DB	0DH,"L - LOAD Lisp-85"
	DB	0DH,"P - LOAD Prolog-85"
	DB	0DH,"S - LOAD STACK"
	DB	0DH,0
	RET

;MDIR:
;	CALL SPCUT_D
;	CALL GETDEV_D
;	LD (_DSK),A
;	CALL _DIR
;	RET
;
;SAVE:
;	CALL SPCUT_D
;	LD A,1
;	CALL _FILE
;	LD A,(DE)
;	CP ":"
;	JR NZ,SNERR
;	INC DE
;	CALL _HLHEX
;	JR C,SNERR
;	LD (_DTADR),HL
;	LD (_EXADR),HL
;	INC DE
;	CALL _HLHEX
;	JR C,SNERR
;	PUSH DE
;	LD DE,(_DTADR)
;	OR A
;	SBC HL,DE
;	POP DE
;	JR C,SNERR
;	INC HL
;	LD (_SIZE),HL
;	INC DE
;	CALL _HLHEX
;	JR C,SAVE1
;	LD (_EXADR),HL
;SAVE1:
;	CALL _WOPEN
;	RET C
;	CALL _WRD
;	RET C
;	CALL _NL
;	LD DE,OK
;	CALL _MSG
;	JP _NL
;SNERR:
;	LD A,13
;	SCF
;	RET
;
;LOAD:
;	LD A,1
;	CALL _FILE
;	LD A,(DE)
;	OR A
;	LD (LDWORK+2),A
;	JR Z,LOAD1
;	INC DE
;	CALL _HLHEX
;	JR C,SNERR
;	LD (LDWORK),HL
;;
;LOAD1:
;	CALL _ROPEN
;	RET C
;	CALL NZ,SK_PRT
;	JR NZ,LOAD1
;	CALL _MPRNT
;	DB	"Loading ",0
;	CALL _FPRNT
;	CALL _NL
;	LD A,(LDWORK+2)
;	OR A
;	JR Z,LOAD3
;	LD HL,(LDWORK)
;	LD (_DTADR),HL
;LOAD3:
;	JP _RDD
;
;LDWORK:	DS	3
;
;SK_PRT:
;	PUSH AF
;	CALL _MPRNT
;	DB	"Found   ",0
;	CALL _FPRNT
;	CALL _NL
;	POP AF
;	RET
;
;MKILL:
;	CALL SPCUT_D
;	CALL _FILE
;	RET C
;	CALL _KILL
;	RET
;
;MSET:
;	CALL SPCUT_D
;	CALL _FILE
;	INC DE
;	CALL SPCUT_D
;	LD A,(DE)
;	CP "P"
;	JP Z,_SET
;	CP "R"
;	JP Z,_RESET
;	LD A,13
;	SCF
;	RET
;
;DEVST:
;	CALL SPCUT_D
;	LD A,(DE)
;	CALL TOUPER
;	CALL __DEVCHK
;	JR NC,DEVST1
;	LD A,03H
;	RET
;DEVST1:
;	LD (_DSK),A
;	JP _SDVSW
;
;MNAME:
;	CALL SPCUT_D
;	CALL _FILE
;	LD A,(DE)
;	INC DE
;	CP 3AH
;	JP Z,_NAME
;	LD A,0DH
;	SCF
;	RET
;
;MWIDTH:
;	LD A,(_WIDTH)
;	CP 80
;	JR NZ,L228EH
;	LD A,40
;	JP _WIDCH
;L228EH:
;	LD A,80
;	JP _WIDCH

	INC DE
SPCUT_D:
	LD A,(DE)
	CP " "
	JR Z,SPCUT_D-1
	RET

;GETDEV_D:
;	CALL SPCUT_D
;	INC DE
;	LD A,(DE)
;	DEC DE
;	CP 3AH
;	JR Z,L22A7H
;	JP RDVSW
;L22A7H:
;	LD A,(DE)
;	INC DE
;	INC DE

TOUPER:
	CP "a"
	RET C
	CP "z"+1
	RET NC
	AND 0DFH	; 1101 1111B
	RET

;--------------------------
; DISK I/O SYS ENTRY
;--------------------------

;--------------------------
; ERROR NUMBER
;
;  1. Device I/O error
;  2. Device offline
;  3. Bad file descripter
;  4. Write protected
;  5. Bad record
;  6. Bad file mode
;  7. Bad allocation table
;  8. File not found
;  9. Device full
; 10. File already exists
; 11. Reserved feature
; 12. File not open
; 13. Syntax Error
; 14. Irregal data Error
;--------------------------
;  DOS MODULE
;--------------------------

; WOPEN - Open write file

WOPEN:
;	CALL CLOSE
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C
;	JP Z,__WRI
;	CALL DSKCHK
;	JR NC,WOPEN1
;	RET				; Reserved feature
;;
;WOPEN1:
;	CALL FATRED
;	RET C			; Read error
;	CALL FCBSCH
;	JR NZ,WOPEN2	; New file
;;
;	LD A,(HL)
;	CALL WPCHK
;	RET C			; Write protected
;	CALL FMCHK
;	RET C			; Bad file mode
;	;
;	PUSH HL
;	LD BC,001EH
;	ADD HL,BC
;	LD A,(HL)		; Start record No. get
;	POP HL
;	CALL ERAFAT
;	RET C			; Bad allocation table
;	JR WOPEN3
;	;
;WOPEN2:
;	CALL FRESCH
;	LD A,9			; Device full
;	RET C
;	;
;WOPEN3:
;	LD (DEBUF),DE
;	LD (HLBUF),HL
;	CALL __PARCS
;	CALL OPEN
	XOR A
	RET

;-------------------------------
; ROPEN - Opne read file

ROPEN:
;	CALL CLOSE
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C			; Bad file descripter
;	JP Z,__TROPN	; TAPE
;	CALL DSKCHK
;	JR NC,ROPEN1
;	RET				; Reserved feature
;	;
;ROPEN1:
;	CALL FCBSCH
;	RET C
;	LD A,8			; File not found
;	SCF
;	RET NZ
;	PUSH HL
;	LD DE,(_IBFAD)
;	LD BC,32
;	LDIR
;	POP HL
;	LD A,(HL)
;	CALL FMCHK
;	RET C			; Bad file mode
;	;
;ROPEN2:
;	CALL __PARSC
;	CALL OPEN
	XOR A
	RET

;-------------------------------
; WRD - Write Data

WRD:
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C
;	JP Z,__TWRD
;	LD A,(__OPNFG)
;	OR A
;	JR NZ,WRD1
;	SCF
;	LD A,12			; File not open
;	RET
;	;
;WRD1:
;	CALL CLOSE
;	LD A,(_DSK)
;	CALL DSKCHK
;	RET C			; Reserved feature
;	;
;	CALL DSAVE		; DISK
	RET

;-------------------------------
; RDD - Read Data

RDD:
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C
;	JP Z,__TRDD
;	XOR A
;	LD (_DIRNO),A
;	LD (RETOPI),A
;	LD A,(__OPNFG)
;	OR A
;	JR NZ,RDD1
;	SCF
;	LD A,12			; File not open
;	RET
;	;
;RDD1:
;	CALL CLOSE
;	LD A,(_DSK)
;	CALL DSKCHK
;	RET C			; Reserved Feature
;	;
;	CALL FATRED
;	RET C
;	CALL DLOAD		; DISK
	RET

;-------------------------------
; GETFCB -

GETFCB:
;	CALL CLOSE
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C
;	JR NZ,GETFC1	;  *-*-
;	CALL TRDSW		;  *-*-
;	LD (_DSK),A		;  *-*-
;	JP __RDI		;  *-*-
;GETFC1:
;	CALL _GETKY
;	CP 1BH
;	JP Z,DEND
;	CP 0DH
;	JR NZ,GETFC2
;	LD A,(RETOPI)
;	OR A
;	JR NZ,DECPOI
;GETFC2:
;	LD A,(_DIRNO)
;	LD C,A
;	LD B,3
;SFL41:
;	SRL A
;	DJNZ SFL41
;	LD HL,(_DIRPS)
;	LD D,0
;	LD E,A
;	ADD HL,DE
;	EX DE,HL
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;	JR C,ERRRET
;	LD A,C
;	AND 07H
;	LD B,5
;SFL51:
;	ADD A,A
;	DJNZ SFL51
;	LD HL,(_DTBUF)
;	ADD A,L
;	LD L,A
;	JR NC,L23CFH
;	INC H
;L23CFH:
;	LD A,(HL)
;	OR A
;	JR Z,NEXT1
;	CP 0FFH
;	JR Z,DEND
;	LD DE,(_IBFAD)
;	LD BC,0020H
;	LDIR
;	CALL INCPOI
;	JP ROPEN2
;
;NEXT1:
;	CALL INCPOI
;	JR NC,GETFC1
;	RET				; File not found *-*-*-
;
;INCPOI:
;	LD HL,_DIRNO
;	INC (HL)
;	LD A,(HL)
;	LD HL,_MXTRK
;	CP (HL)
;	JR Z,DEND
;	LD (RETOPI),A
;	OR A
;	RET
;ERRRET:
;	PUSH AF
;	CALL DEND
;	POP AF
;	RET
;
;DECPOI:
;	LD HL,_DIRNO
;	LD A,(HL)
;	OR A
;	JR Z,L240AH
;	DEC (HL)
;L240AH:
;	XOR A
;	JR DEND1
;DEND:
;	XOR A
;	LD (_DIRNO),A
;DEND1:
;	LD (RETOPI),A
;	LD A,8
;	SCF
	RET


;RETOPI:	DB	0

;-------------------------------
; DIR - Directory display

DIR:
;	LD A,(_DSK)
;	CALL DEVCHK
;	RET C			; Bad File Descripter
;	JP Z,__TDIR
;	CALL DSKCHK
;	RET C			; Reserved Feature
;	;
;	CALL FATRED
;	RET C			; Disk error
;	LD A,"$"
;	CALL _PRINT
;	CALL FRECLU
;	CALL _PRTHX
;	LD DE,CSTMES
;	CALL _MSX
;	LD B,16
;	LD DE,(_DIRPS)	; Direstory start
;DIRL:
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;	RET C			; Disk error
;	CALL DIRPRT
;	RET Z
;	INC DE
;	DJNZ DIRL
;	XOR A
;	RET
;;
;DIRPRT:
;	PUSH BC
;	PUSH DE
;	LD B,8
;DIRPL:
;	LD A,(HL)
;	OR A
;	JR Z,DIRN
;	CP 0FFH
;	JR Z,DIRPE
;	CALL P_FNAM
;	CALL _LTNL
;	CALL _PAUSE
;	DW	DIRPE
;DIRN
;	LD DE,0020H
;	ADD HL,DE
;	DJNZ DIRPL
;	DB	3EH			; Skip next operation
;DIRPE:
;	XOR A
;	POP DE
;	POP BC
;	OR A
	RET

;-------------------------------
; KILL - Delete disk file

KILL:
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	;
;	CALL FATRED
;	RET C			; Disk error
;	CALL FCBSCH
;	RET C			; Disk error
;	LD A,8			; File not found
;	SCF
;	RET NZ
;	LD A,(HL)
;	CALL WPCHK
;	RET C			; Write protected
;	;
;	LD (HL),0
;	PUSH HL
;	LD BC,001EH
;	ADD HL,BC
;	LD A,(HL)
;	POP HL
;	CALL ERAFAT
;	RET C			; Bad allocation table
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKWRT
;	CALL NC,FATWRT
	RET
;-------------------------------
; NAME - Rename disk file

NAME:
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	;
;	PUSH DE
;	CALL FCBSCH
;	LD (DEBUF),DE
;	LD (HLBUF),HL
;	POP DE
;	RET C			; Disk error
;	LD A,8			; File not found
;	SCF
;	RET NZ
;	LD A,(HL)
;	CALL WPCHK
;	RET C			; Write protected
;	;
;	LD A,(_DSK)
;	PUSH AF
;	CALL _FILE		; New filename set
;	POP AF
;	LD (_DSK),A
;	CALL FCBSCH
;	RET C			; Disk error
;	LD A,10			; File already exists
;	SCF
;	RET Z
;	LD DE,(DEBUF)
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;	RET C
;	LD HL,(_IBFAD)
;	INC HL
;	LD DE,(HLBUF)
;	INC DE
;	LD BC,17
;	LDIR
;	LD DE,(DEBUF)
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKWRT
	RET

;-------------------------------
; SET - Set write protect

SET:
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	;
;	CALL FCBSCH
;	RET C			; Disk error
;	LD A,8			; File not found
;	SCF
;	RET NZ
;	;
;	SET 6,(HL)
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKWRT
	RET

;-------------------------------
; RESET - Reset write protect

RESET:
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	;
;	CALL FCBSCH
;	RET C			; Disk error
;	LD A,8			; File not found
;	SCF
;	RET NZ
;	;
;	RES 6,(HL)
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKWRT
	RET

;-------------------------------
; SECRD - Sector read

DSKRED:
;	EX AF,AF'
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	SUB "A"
;	LD (UNITNO),A
;	EX AF,AF'
;	CALL DREAD
	RET

;-------------------------------
; SECWR - Sector write

DSKWRT:
;	EX AF,AF'
;	LD A,(_DSK)
;	CALL ALCHK
;	RET C
;	CALL DSKCHK
;	RET C
;	SUB "A"
;	LD (UNITNO),A
;	EX AF,AF'
;	CALL DWRITE
	RET

;---------------
; SUB ROUTINES
;---------------

; OPEN FLAG SET/RESET

;OPEN:
;	PUSH AF
;	LD A,1
;	JR CLOSE1
;	;
;CLOSE:
;	PUSH AF
;	XOR A
;CLOSE1:
;	LD (__OPNFG),A
;	POP AF
;	RET

;; FILE WRITE PROTECT CHECK
;
;WPCHK:
;	OR A
;	BIT 6,A
;	RET Z
;	LD A,4			; Write protected
;	SCF
;	RET
;
;; FILE MODE CHECK
;
;FMCHK:
;	PUSH HL
;	AND 087H		; 1000 0111B
;	LD HL,__FTYPE
;	CP (HL)
;	POP HL
;	RET Z
;	LD A,6			; Bad file mode
;	SCF
;	RET
;
;; DOSK DRIVE NAME CHECK
;
;DSKCHK:
;	CP "A"
;	JR C,DSKCH1
;	CP "D"+1
;	CCF
;	RET NC
;DSKCH1:
;	LD A,11			; Reserved fasture
;	RET

; All Device Check

;ALCHK:
;	CALL DEVCHK
;	RET C			; Bad file descripter
;	CALL TPCHK
;	JR NZ,L25A9H
;	LD A,3
;	SCF
;	RET
;L25A9H:
;	CALL DSKCHK
;	RET

RDVSW:
	XOR		A
;	LD A,(__DFDV)
;	CALL TPCHK
;	RET NZ
;
;TRDSW:
;	LD A,(_DVSW)
;	OR A
;	JR NZ,L25BCH
;	LD A,"T"
;L25BCH:
;	CP 1
;	JR NZ,L25C2H
;	LD A,"S"
;L25C2H:
;	CP 3
;	JR NZ,L25C8H
;	LD A,"Q"
;L25C8H:
	RET

SDVSW:
;	PUSH AF
;	LD (__DFDV),A
;	CP "T"
;	JR NZ,L25D2H
;	XOR A
;L25D2H:
;	CP "S"
;	JR NZ,L25D8H
;	LD A,1
;L25D8H:
;	CP "Q"
;	JR NZ,L25DEH
;	LD A,3
;L25DEH:
;	LD (_DVSW),A
;	POP AF
	RET

; LOAD FROM DISK
;
;DLOAD:
;	LD HL,(_IBFAD)
;	LD BC,001EH
;	ADD HL,BC
;	LD A,(HL)		; Record No.
;	LD (NXCLST),A
;	LD BC,(_SIZE)
;	LD HL,(_DTADR)
;DLOAD1:
;	PUSH HL
;	LD A,(NXCLST)
;	LD HL,(_FATBF)
;	LD E,A
;	LD D,0
;	ADD HL,DE
;	LD A,(HL)
;	LD (NXCLST),A
;	EX DE,HL
;	ADD HL,HL
;	ADD HL,HL
;	ADD HL,HL
;	ADD HL,HL
;	EX DE,HL
;	POP HL
;	OR A
;	JR Z,DLOAD2
;	CP 80H
;	JR NC,DLOAD3
;	LD A,10H
;	CALL DSKRED
;	RET C			; Disk error
;	LD DE,1000H
;	ADD HL,DE
;	PUSH HL
;	LD L,C
;	LD H,B
;	OR A
;	SBC HL,DE
;	LD C,L
;	LD B,H
;	POP HL
;	JR NC,DLOAD1
;DLOAD2:
;	LD A,7			; Bad allocation table
;	SCF
;	RET
;	;
;DLOAD3:
;	SUB 7FH
;	CP 10H+1
;	JR NC,DLOAD2
;	DEC A
;	DEC BC
;	CP B
;	JR NZ,DLOAD2
;	LD B,0
;	INC BC
;	OR A
;	JR Z,DLOAD4
;	PUSH AF
;	CALL DSKRED
;	JR C,DLOAD5
;	POP AF
;DLOAD4:
;	PUSH DE
;	LD E,0
;	LD D,A
;	ADD HL,DE
;	EX (SP),HL
;	LD E,A
;	LD D,0
;	ADD HL,DE
;	EX DE,HL
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;DLOAD5:
;	POP DE
;	RET C			; Disk error
;	LDIR
;	XOR A
;	RET

; SAVE TO DISK

;DSAVE:
;	LD DE,(DEBUF)
;	LD HL,(HLBUF)
;	LD BC,(_SIZE)
;	PUSH BC
;	DEC BC
;	SRL B
;	SRL B
;	SRL B
;	SRL B
;	INC B
;	CALL FRECLU
;	CP B
;	POP BC
;	LD A,9			; Device full
;	RET C
;	LD HL,(_IBFAD)
;	PUSH HL
;	PUSH DE
;	PUSH BC
;	LD DE,00018H
;	ADD HL,DE
;	LD E,L
;	LD D,H
;	INC DE
;	LD (HL),0
;	LD BC,00007H
;	LDIR
;	POP BC
;	POP DE
;	POP HL
;	LD A,01EH
;	ADD A,L
;	LD L,A
;	JR NC,L2698H
;	INC H
;L2698H:
;	CALL FCGET
;	LD (HL),A		; Record No.
;	LD HL,(_DTADR)
;	;
;DSAVE1:
;	PUSH HL
;	LD HL,(_FATBF)
;	LD E,A
;	LD D,0
;	ADD HL,DE
;	EX DE,HL
;	ADD HL,HL
;	ADD HL,HL
;	ADD HL,HL
;	ADD HL,HL
;	EX DE,HL
;	DEC BC
;	LD A,B
;	INC BC
;	CP 010H
;	JR C,DSAVE3
;	LD (HL),080H
;	CALL FCGET
;	LD (HL),A
;	POP HL
;	PUSH AF
;	LD A,010H
;	CALL DSKWRT
;	JR C,DSAVE2		; Disk error
;	LD DE,01000H
;	ADD HL,DE
;	PUSH HL
;	LD L,C
;	LD H,B
;	OR A
;	SBC HL,DE
;	LD C,L
;	LD B,H
;	POP HL
;	POP AF
;	JR DSAVE1
;	;
;DSAVE2:
;	POP HL
;	RET
;	;
;DSAVE3:
;	INC A
;	PUSH AF
;	ADD A,07FH
;	LD (HL),A
;	POP AF
;	POP HL
;	CALL DSKWRT
;	RET C			; Disk error
;	CALL FATWRT
;	RET C			; Disk error
;	LD HL,(_IBFAD)
;	LD DE,(HLBUF)
;	LD BC,0020H
;	LDIR
;	LD HL,(_DTBUF)
;	LD DE,(DEBUF)
;	LD A,1
;	CALL DSKWRT		; Directory write
;	RET C			; Disk error
;	XOR A
;	RET

; FAT READ FROM BUFFER

;FATRED:
;	PUSH DE
;	PUSH HL
;	LD DE,(_FATPS)
;	LD HL,(_FATBF)
;	LD A,1
;	CALL DSKRED
;	POP HL
;	POP DE
;	RET

; FAT WRITE FROM BUFFER

;FATWRT:
;	PUSH DE
;	PUSH HL
;	LD DE,(_FATPS)
;	LD HL,(_FATBF)
;	LD A,1
;	CALL DSKWRT
;	POP HL
;	POP DE
;	RET

; FREE CLUSTER GET

;FRECLU:
;	PUSH BC
;	PUSH HL
;	LD B,080H
;	LD C,0
;	LD HL,(_FATBF)
;FRECL1:
;	LD A,(HL)
;	OR A
;	JR NZ,FRECL2
;	INC C
;FRECL2:
;	INC HL
;	DJNZ FRECL1
;	LD A,C
;	POP HL
;	POP BC
;	RET

; FREE CLUSTER POSITION GET

;FCGET:
;	PUSH BC
;	PUSH HL
;	LD B,080H
;	LD HL,(_FATBF)
;FCGET2:
;	LD A,(HL)
;	OR A
;	JR Z,FCGET3
;	INC HL
;	DJNZ FCGET2
;	SCF
;	JR FCGET4
;FCGET3:
;	LD A,080H
;	SUB B
;	OR A
;FCGET4:
;	POP HL
;	POP BC
;	RET

; FAT ERASE

;ERAFAT:
;	PUSH DE
;	PUSH HL
;	LD DE,(_FATBF)
;ERAFA1:
;	LD L,A
;	LD H,0
;	ADD HL,DE
;	LD A,(HL)
;	LD (HL),0
;	CP 080H
;	JR C,ERAFA1
;	POP HL
;	POP DE
;	CP 090H
;	JR NC,ERAFA2
;	XOR A
;	RET
;	;
;ERAFA2:
;	LD A,7		; Bad allocation table
;	SCF
;	RET

; FCB SEARCH

;FCBSCH:
;	PUSH BC
;	LD C,16			; Directory length
;	LD DE,(_DIRPS)	; Directory start
;FCBSC1:
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;	JR C,FCBSC6
;	LD B,8
;FCBSC2:
;	LD A,(HL)
;	CP 0FFH
;	JR Z,FCBSC4
;	OR A
;	JR Z,FCBSC3
;	PUSH DE
;	LD DE,(_IBFAD)
;	CALL FCOMP
;	POP DE
;	JR Z,FCBSC5
;FCBSC3:
;	PUSH DE
;	LD DE,32
;	ADD HL,DE
;	POP DE
;	DJNZ FCBSC2
;	INC DE
;	DEC C
;	JR NZ,FCBSC1
;FCBSC4:
;	DB	3EH
;FCBSC5:
;	XOR A
;	OR A
;FCBSC6:
;	POP BC
;	RET

; FREE FCB SEARCH

;FRESCH:
;	PUSH BC
;	LD C,16			; Directory length
;	LD DE,(_DIRPS)	; Directory start
;FRESC1:
;	LD HL,(_DTBUF)
;	LD A,1
;	CALL DSKRED
;	JR C,FRESC3
;	LD B,8
;FRESC2:
;	LD A,(HL)
;	OR A
;	JR Z,FRESC4
;	CP 0FFH
;	JR Z,FRESC4
;	PUSH DE
;	LD DE,32
;	ADD HL,DE
;	POP DE
;	DJNZ FRESC2
;	INC DE
;	DEC C
;	JR NZ,FRESC1
;FRESC3:
;	DB	3EH
;FRESC4:
;	XOR A
;	POP BC
;	RET
;
;FCOMP:
;	PUSH BC
;	PUSH DE
;	PUSH HL
;	LD B,16		; Directory length
;FCOMP1:
;	INC DE
;	INC HL
;	LD A,(DE)
;	CP (HL)
;	JR NZ,FCOMP2
;	DJNZ FCOMP1
;FCOMP2:
;	POP HL
;	POP DE
;	POP BC
;	RET

;---------------------
; INTERNAL WORK AREA
;---------------------

;NXCLST:	DS	1
;DEBUF:	DS	2
;HLBUF:	DS	2

;P_FNAM:
;	PUSH BC
;	PUSH DE
;	PUSH HL
;	LD DE,(_IBFAD)
;	LD BC,0020H
;	LDIR
;	CALL ATRPRT
;	LD A,(_DSK)
;	CALL _PRINT
;	LD A,":"
;	CALL _PRINT
;	CALL _FPRNT
;	CALL __PARSC
;	LD BC,(_SIZE)
;	LD HL,(_DTADR)
;	LD DE,(_EXADR)
;	CALL PHEX
;	ADD HL,BC
;	DEC HL
;	CALL PHEX
;	EX DE,HL
;	CALL PHEX
;	POP HL
;	POP DE
;	POP BC
;	RET
;	;
;PHEX:
;	LD A,03AH
;	CALL _PRINT
;	CALL _PRTHL
;	RET

; FILE ATTRIBUTE PRINT

;ATRPRT:
;	PUSH AF
;	LD DE,ATRMES
;	BIT 7,A
;	JR Z,ATRP1
;	LD A,8
;	DB	11H		; Skip next operation
;ATRP1:
;	AND	7
;	LD L,A
;	LD H,0
;	ADD HL,HL
;	ADD HL,HL
;	LD DE,ATRMES
;	ADD HL,DE
;	EX DE,HL
;	CALL _MSX
;	POP AF
;	BIT 6,A
;	LD A,"*"
;	JR NZ,ATRP2
;	LD A," "
;ATRP2:
;	CALL _PRINT
;	CALL _PRNTS
;	RET
;
;DEVCHK:
;	CALL TPCHK
;	RET Z
;	CP "A"
;	JR C,DEVCH1
;	CP "L"+1
;	CCF
;	JR C,DEVCH1
;	OR A
;	RET
;DEVCH1:
;	LD A,3		; Bad file descripter
;	RET
;
;TPCHK:
;	CP "T"
;	RET Z
;	CP "S"
;	RET Z
;	CP "Q"
;	RET

ERROR:
	DEC A
	CP 14
	JR C,ERROR1
	INC A
	LD DE,ER15
	PUSH AF
	CALL _MSG
	LD A,"$"
	CALL _PRINT
	POP AF
	CALL _PRTHX
	JR ERROR2
ERROR1:
	LD HL,MESTBL
	ADD A,A
	LD E,A
	LD D,0
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	CALL _MSG
ERROR2:
	CALL _BELL
	CALL _NL
	RET

;-------------------
; MESSAGE DATA AREA
;-------------------

;CSTMES:
;	DB	" Clusters Free",0DH,0
;ATRMES:
;	DB	"Nul",0	; 0
;	DB	"Bin",0	; 1
;	DB	"Bas",0	; 2
;	DB	"???",0	; 3
;	DB	"Asc",0	; 4
;	DB	"???",0	; 5
;	DB	"???",0	; 6
;	DB	"???",0	; 7
;	DB	"Dir",0	; <= 80H
;
;;-------------------------------
;; INTERNAL JUMP TABLE and WORK
;;-------------------------------
;	ORG	2900H
;
;__RDI:		JP RDI
;__TROPN:	JP TROPN
;__WRI:		JP WRI
;__TWRD:		JP TWRD
;__TRDD:		JP TRDD
;__TDIR:		JP TDIR
;__P_FNAM:	JP P_FNAM
;__DEVCHK:	JP DEVCHK
;__TPCHK:	JP TPCHK
;	DS	3
;
;__OPNFG:		DS	1
;__FTYPE:	DS	1
;__DFDV:		DB	"A"
;			DS	9
;;
;__PARSC:
;	PUSH HL
;	LD HL,(01152H)	; SIZE
;	LD (_SIZE),HL
;	LD HL,(01154H)	; DTADR
;	LD (_DTADR),HL
;	LD HL,(01156H)	; EXADR
;	LD (_EXADR),HL
;	POP HL
;	RET
;
;__PARCS:
;	PUSH HL
;	LD HL,(_SIZE)
;	LD (01152H),HL
;	LD HL,(_EXADR)
;	LD (01156H),HL
;	LD HL,(_DTADR)
;	LD (01154H),HL
;	POP HL
;	RET

;---------------------
; Error Message Table
;---------------------

;	ORG	2A00H

MESTBL:
	DW	ER1,ER2,ER3,ER4,ER5
	DW	ER6,ER7,ER8,ER9,ER10
	DW	ER11,ER12,ER13,ER14

ER1:	DB	"Device I/O Error",0DH
ER2:	DB	"Device Offline",0DH
ER3:	DB	"Bad File Descripter",0DH
ER4:	DB	"Write Protected",0DH
ER5:	DB	"Bad record",0DH
ER6:	DB	"Bad File Mode",0DH
ER7:	DB	"Bad Allocation Table",0DH
ER8:	DB	"File not Found",0DH
ER9:	DB	"Device Full",0DH
ER10:	DB	"File Already Exists",0DH
ER11:	DB	"Reserved Feature",0DH
ER12:	DB	"File not Open",0DH
ER13:	DB	"Syntax "
ER15:	DB	"Error ",0DH
ER14:	DB	"Bad Data",0DH
OK:		DB	"Complete !",0DH


;-------------------------------
;
; Disk I/O  Sub Routine for MZ
;
;-------------------------------

;	ORG	2B00H
;
;CR_D	EQU	0D8H
;TR_D	EQU	0D9H
;SR_D	EQU	0DAH
;DR_D	EQU	0DBH
;DM_D	EQU	0DCH
;HS_D	EQU	0DDH
;
;DREAD:	JP DRD
;DWRITE:	JP DWRT
;UNITNO:	DB	0
;
;; READ
;;
;DRD:
;	CALL SET_D
;	LD A,094H
;	LD (SQRW+2),A
;	LD BC,0DBDBH
;	LD DE,02F77H
;	JR RWSET
;
;; WRITE
;;
;DWRT:
;	CALL SET_D
;	LD A,0B4H
;	LD (SQRW+2),A
;	LD BC,07E2FH
;	LD DE,0D3DBH
;
;RWSET:
;	LD HL,SQRW2
;	LD (HL),B
;	INC HL
;	LD (HL),C
;	INC HL
;	LD (HL),D
;	INC HL
;	LD (HL),E
;
;; Adjust Record No.
;;
;RADJ:
;	LD DE,(TRCK)
;	LD A,(CNTR)
;	LD L,A
;	LD H,0
;	ADD HL,DE
;	LD BC,4FFH+1
;	OR A
;	SBC HL,BC
;	JP NC,BADRC
;	LD A,E
;	AND 00FH
;	INC A
;	LD (SCTR),A
;	LD B,004H
;RADJ1:
;	SRL D
;	RR E
;	DJNZ RADJ1
;	LD A,E
;	LD (TRCK),A
;	JR MT
;
;TRCK:	DB	0
;SCTR:	DB	0
;
;;  MOTOR ON
;;
;MT:
;	LD B,5
;	LD A,(UNITNO)
;	OR 084H
;	OUT (DM_D),A
;	LD DE,6700
;MT1:
;	DEC DE
;	LD A,E
;	OR D
;	JR NZ,MT1
;	LD DE,0
;MT2:
;	DEC DE
;	IN A,(CR_D)
;	RLCA
;	JR C,START_D
;	LD A,E
;	OR D
;	JR NZ,MT2
;	DJNZ MT2
;	JP DVOL
;
;;  START
;;
;START_D:
;	LD A,11
;	LD (RTRY),A
;STAT_D:
;	LD A,(RTRY)
;	DEC A
;	JR NZ,STRT1_D
;	JP RDYCHK
;	;
;STRT1_D:
;	LD (RTRY),A
;	;
;	LD A,0D8H		; Force Interrupt
;	CALL CMD1
;	JP C,ERROR_D
;	CALL WRP_CHK
;	LD HL,(TRCK)
;	LD (NTRCK),HL
;	EXX
;	LD A,(CNTR)
;	LD D,A
;	LD HL,(STADR)
;	EXX
;
;;  TRACK SEQUE
;;
;TRKSQ:
;	LD A,0C4H		; Read Address
;	CALL CMD
;	LD B,6
;TRKSQ1:
;	IN A,(CR_D)
;	RRCA
;	JR C,STAT_D
;	RRCA
;	JR C,TRKSQ1
;	IN A,(DR_D)
;	DJNZ TRKSQ1
;	LD A,0D8H
;	CALL CMD1
;	JP C,ERROR_D
;	IN A,(SR_D)
;	OUT (TR_D),A
;	CPL
;	LD D,A
;	LD A,(NTRCK)
;	SRL A
;	CP D
;	JR Z,HEADS
;	CPL
;	OUT (DR_D),A
;	LD A,012H		; Seek Command
;	CALL CMD1
;	JP C,ERROR_D
;	JR TRKSQ
;
;HEADS:
;	LD A,(NTRCK)
;	SRL A
;	CPL
;	OUT (TR_D),A
;	JR C,$+4
;	XOR A
;	DB	01H
;HEADS1:
;	LD A,1
;	LD E,A
;	XOR 1
;	CPL
;	OUT (HS_D),A
;	LD A,(NSECT)
;	CPL
;	OUT (SR_D),A
;
;; Sequential Read and Write
;;
;SQRW:
;	EXX
;	LD A,094H		; Seq Read
;	CALL CMD
;SQRW1:
;	LD B,0
;	IN A,(CR_D)
;	RRCA
;	JR C,SQRW5
;	RRCA
;	JR C,SQRW1+2
;SQRW2:
;	IN A,(DR_D)		; LD A,(HL)
;	CPL
;	LD (HL),A		; OUT (DR_D),A
;	INC HL
;	DJNZ SQRW1+2
;	LD A,(NSECT)
;	INC A
;	LD (NSECT),A
;	CP 17
;	JR Z,SQRW3
;	DEC D
;	JR NZ,SQRW1
;	JR SQRW4
;SQRW3:
;	DEC D
;	LD A,001H
;	LD (NSECT),A
;SQRW4:
;	LD A,0D8H
;	CALL CMD1
;SQRW5:
;	IN A,(CR_D)
;	CPL
;	OR A
;	JP NZ,STAT_D
;SQRW6:
;	LD A,(NTRCK)
;	INC A
;	LD (NTRCK),A
;	LD A,D
;	OR A
;	JP Z,END_D
;	EXX
;	LD A,E
;	OR A
;	JP NZ,TRKSQ
;	JP HEADS
;
;;  Program End
;;
;END_D:
;	DEC A
;	LD (CNTR),A
;DKOUT:
;	PUSH AF
;	XOR A
;	OUT (DM_D),A
;	POP AF
;	EXX
;	POP HL
;	POP DE
;	POP BC
;	EXX
;	POP BC
;	POP DE
;	POP HL
;	RET
;
;;  Errors
;;
;ERROR_D:
;	IN A,(CR_D)
;	BIT 7,A
;	JR Z,DVOL
;
;DEVIO:
;	LD A,1
;	SCF
;	JR DKOUT
;
;DVOL:
;	LD A,2
;	SCF
;	JR DKOUT
;
;BADRC:
;	LD A,5
;	SCF
;	JR DKOUT
;
;WRP_CHK:
;	BIT 5,A
;	RET Z
;	LD A,(SQRW+2)
;	CP 0B4H
;	RET NZ
;	LD A,4
;	POP HL
;	SCF
;	JR DKOUT
;
;RDYCHK:
;	IN A,(CR_D)
;	BIT 7,A
;	JP Z,MT
;	JP DEVIO
;
;; Subroutines
;;
;CMD:
;	PUSH HL
;	LD HL,BUSY
;	LD (HL),030H
;	CALL CMD1
;	LD (HL),038H
;	POP HL
;	JP C,CMDER
;	RET
;CMDER:
;	EX (SP),HL
;	POP HL
;	JP ERROR_D
;CMD1:
;	CPL
;	OUT (CR_D),A
;	;
;	PUSH BC
;	PUSH HL
;	LD B,010H
;CMD2:
;	LD HL,0
;	DEC HL
;	LD A,L
;	OR H
;	JR Z,CMD3
;	IN A,(CR_D)
;	CPL
;	RRCA
;BUSY:
;	JR C,CMD2+3
;	POP HL
;	POP BC
;	OR A
;	RET
;CMD3:
;	DJNZ CMD2
;	POP HL
;	POP BC
;	SCF
;	RET
;
;SET_D:
;	LD (CNTR),A
;	LD (STADR),HL
;	LD (TRCK),DE
;	EX (SP),HL
;	PUSH DE
;	PUSH BC
;	EXX
;	PUSH BC
;	PUSH DE
;	PUSH HL
;	EXX
;	JP (HL)
;
;CNTR:	DB	0
;STADR:	DW	0
;NTRCK:	DB	0
;NSECT:	DB	0
;RTRY:	DB	0
;ERSTAT:	DB	0
