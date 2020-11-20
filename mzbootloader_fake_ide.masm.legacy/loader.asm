COMMENT #
 Copyright (c) JaeHyuk Cho <mailto:minzkn@minzkn.com>
 All right reserved.

 [ChangeLog]
 - 2004.3.24 : Project start
#

.386
.RADIX 000AH

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; 여기를 주목하세요.
; 여기에 제한용량을 기입하여야 합니다. 또는 이 바이너리의 오프셋 2에서 4바이트에 해당합니다.
DEF_LIMITSECTORS   = 00000000H 
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DEF_ORG_ENTRY      = 0000H

DEF_CODE_FAR_JUMP  = 0EAH

DEF_CODE_MAGIC     = 2745D

; Master boot record
DEF_SECTOR_OS1        = 60D 
DEF_SECTOR_OS2        = 61D

DEF_SEG_COPY       = 0070H
DEF_SEG_OS1        = 0090H
DEF_SEG_OS2        = 00B0H

DEF_INT_VIDEO      = 10H
 DEF_FC_TTY        = 0EH
 DEF_ATTR_TTY      = 0700H
 
DEF_INT_DISK       = 13H
 DEF_FC_READ       = 0201H
 DEF_ATTR_HDD      = 0080H
 DEF_SIZE_SECTOR   = 512D

DEF_INT_DROP       = 18H

                   ASSUME CS:MZ_CODE, DS:MZ_CODE, ES:NOTHING, SS:NOTHING
MZ_CODE            SEGMENT PARA PUBLIC USE16 'CLASS_CODE'
; -----------------------------------------------------------------
                   ORG DEF_ORG_ENTRY
; -----------------------------------------------------------------
L_Entry: 
                   DW DEF_CODE_MAGIC ; Magic code
L_LimitSize        DD DEF_LIMITSECTORS

                   JMP NEAR PTR L_StartUp
; -----------------------------------------------------------------
L_Puts             LABEL NEAR
                   CLD
L_Puts_00          LABEL SHORT
                   LODSB
		   OR AL, AL
		   JZ SHORT L_Puts_01
		   MOV AH, DEF_FC_TTY 
		   MOV BX, DEF_ATTR_TTY 
		   INT DEF_INT_VIDEO 
		   JMP SHORT L_Puts_00
L_Puts_01          LABEL SHORT
                   RETN
		   
L_PutNum           LABEL NEAR
                   MOV BX, 16D
                   XOR CX, CX
L_PRINT_BIN_0:
                   XOR DX, DX
                   DIV BX
                   CMP DX, 10D
                   JL SHORT L_PRINT_BIN_LESS_0
                   SUB DX, 10D
                   ADD DX, 'A' 
                   JMP SHORT L_PRINT_BIN_LESS_1
L_PRINT_BIN_LESS_0 LABEL SHORT
                   ADD DX, '0'
L_PRINT_BIN_LESS_1 LABEL SHORT
                   PUSH DX
                   INC CX
                   OR AX, AX 
                   JNZ SHORT L_PRINT_BIN_0
L_PRINT_BIN_1      LABEL SHORT
                   POP AX
		   MOV AH, DEF_FC_TTY 
		   MOV BX, DEF_ATTR_TTY 
		   INT DEF_INT_VIDEO 
                   LOOP L_PRINT_BIN_1
                   RETN
; ---------------------------- [ MINKN's IDE PIO mode ] -----------------------------------
COMMENT #
 - Description
   s_fixed : Promary=0, Secondary=1
   s_device: Master=0, Slave=1
 - FUNCTION 
   EAX pascal IDE_GetMaxSize(unsigned int s_fixed, unsigned int s_device)
   return EAX : 0=false, 0<true (LimitSize)
 - FUNCTION
   AX pascal IDE_SetLimit(unsigned int s_fixed, unsigned int s_device, unsigned long s_limitsize, unsigned int s_switch)
   return AX : 0=false, 1=true
#
include ide.inc
; -----------------------------------------------------------------
L_StartUp          LABEL NEAR		   
		   MOV AX, CS
		   MOV DS, AX
	
                   MOV SI, OFFSET MZ_CODE:L_Message_01
		   CALL NEAR PTR MZ_CODE:L_Puts

; L_InputKeyboard    LABEL SHORT ; Debug
                   XOR AX, AX
		   INT 16H

;                   [ Key code debug ]
;                   PUSH AX
;                   CALL NEAR PTR MZ_CODE:L_PutNum
;                   MOV SI, OFFSET MZ_CODE:L_DebugEnter
;		    CALL NEAR PTR MZ_CODE:L_Puts
;		    POP AX

		   CMP AX, 3D00H ; F3 key code
		   JZ SHORT L_Selected_00
                   ; OS 1 
 
                   ; limit code - 이 부분이 OS1 으로 진입할때 제한을 거는 부분입니다.
		   MOV EAX, DWORD PTR MZ_CODE:L_LimitSize
		   PUSH AX ; Push limitsize low word
		   SHR EAX, 10H
		   PUSH AX ; Push limitsize high word
		   XOR AX, AX ; s_fixed
		   PUSH AX
		   XOR AX, AX ; s_device
		   PUSH AX
		   POP DX ; Pop limitsize high word
		   POP AX ; Pop limitsize low word
		   PUSH DX ; Push limitsize high word
		   PUSH AX ; Push limitsize low word
		   MOV AX, 0001H
		   PUSH AX ; s_switch = 1
		   CALL NEAR PTR MZ_CODE:IDE_SetLimit 
		   
                   MOV SI, OFFSET MZ_CODE:L_SelectOS_01
		   CALL NEAR PTR MZ_CODE:L_Puts

                   POP BX
		   POP ES
		   PUSH ES
		   PUSH BX
		   MOV AX, 0201H
		   MOV CX, DEF_SECTOR_OS1
		   MOV DX, 0080H
		   INT DEF_INT_DISK

                   MOV AX, DEF_SEG_COPY
		   MOV ES, AX
		   MOV AX, DEF_SEG_OS1
		   MOV DS, AX
		   MOV SI, 01BEH
		   MOV DI, SI
		   MOV CX, 16D * 4D
		   CLD
		   REPZ MOVSB
		   MOV BYTE PTR ES:[01BDH], 01H ; How is OS1

                   JMP SHORT L_Selected_01
L_Selected_00      LABEL SHORT
                   ; OS 2 

                   ; unlimit size code - 이 부분이 OS2로 진입할때 제한을 푸는 부분입니다.
		   XOR AX, AX ; s_fixed
		   PUSH AX
		   XOR AX, AX ; s_device
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_GetMaxSize
		   PUSH AX ; Push limitsize low word
		   SHR EAX, 10H
		   PUSH AX ; Push limitsize high word
		   XOR AX, AX ; s_fixed
		   PUSH AX
		   XOR AX, AX ; s_device
		   PUSH AX
		   POP DX ; Pop limitsize high word
		   POP AX ; Pop limitsize low word
		   PUSH DX ; Push limitsize high word
		   PUSH AX ; Push limitsize low word
		   XOR AX, AX 
		   PUSH AX ; s_switch = 0
		   CALL NEAR PTR MZ_CODE:IDE_SetLimit 
		   
                   MOV SI, OFFSET MZ_CODE:L_SelectOS_02
		   CALL NEAR PTR MZ_CODE:L_Puts
                   
		   POP BX
		   POP ES
		   PUSH ES
		   PUSH BX
		   MOV AX, 0201H
		   MOV CX, DEF_SECTOR_OS2
		   MOV DX, 0080H
		   INT DEF_INT_DISK
                   
                   MOV AX, DEF_SEG_COPY
		   MOV ES, AX
		   MOV AX, DEF_SEG_OS2
		   MOV DS, AX
		   MOV SI, 01BEH
		   MOV DI, SI
		   MOV CX, 16D * 4D
		   CLD
		   REPZ MOVSB
		   MOV BYTE PTR ES:[01BDH], 02H ; How is OS2

L_Selected_01      LABEL SHORT
                   MOV AX, CS
		   MOV DS, AX

                   ; Overwrite MBR
                   XOR BX, BX
		   MOV AX, 0301H
		   MOV CX, 0001H
		   MOV DX, 0080H
		   INT DEF_INT_DISK

                   RETF ; Jump to MBR code
;		   JMP SHORT L_InputKeyboard ; Debug

; -----------------------------------------------------------------
                   INT DEF_INT_DROP
                   JMP SHORT $ ; Halt
; -----------------------------------------------------------------
IDE_BasePort       DW 01F0H
                   DW 0170H

HDD_CylinderNumber DW 0H
HDD_SectorNumber   DB 0H		   
HDD_HeadNumber     DB 0H

L_Message_01       DB 0AH, 0DH, "Boot loader starting. . .", 0AH, 0DH
L_Message_02       DB "=[ Boot menu ]========================", 0AH, 0DH
                   DB "1. OS1 [ENTER]", 0AH, 0DH
                   DB "2. OS2 [F3]", 0AH, 0DH
                   DB "======================================", 0AH, 0DH
		   DB "Please select : "
                   DB 00H
L_SelectOS_01      DB "OS1", 0DH, 0AH, 00H		 
L_SelectOS_02      DB "OS2", 0DH, 0AH, 00H		

L_DebugEnter       DB "H", 0AH, 0DH, 00H
; -----------------------------------------------------------------
L_EndOfLoader:
MZ_CODE            ENDS
                   END L_Entry

; End of source
