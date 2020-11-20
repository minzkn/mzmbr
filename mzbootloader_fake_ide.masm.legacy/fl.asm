COMMENT #
 Copyright (c) JaeHyuk Cho <mailto:minzkn@minzkn.com>
 All right reserved.

 [ChangeLog]
 - 2004.3.24 : Project start
#

.386
.RADIX 000AH

                   ASSUME CS:MZ_CODE, DS:MZ_CODE, ES:NOTHING, SS:NOTHING
MZ_CODE            SEGMENT PARA PUBLIC USE16 'CLASS_CODE'
; -----------------------------------------------------------------
                   ORG 0H
; -----------------------------------------------------------------
L_Entry: 
                   JMP NEAR PTR L_StartUp
include ide.inc
L_StartUp:
                   MOV AX, CS
		   MOV DS, AX
                   MOV ES, AX
		   
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

                   MOV AX, 4C00H
		   INT 21H
		   JMP $
; -----------------------------------------------------------------
IDE_BasePort       DW 01F0H
                   DW 0170H

HDD_CylinderNumber DW 0H
HDD_SectorNumber   DB 0H		   
HDD_HeadNumber     DB 0H

; -----------------------------------------------------------------
MZ_CODE            ENDS
                   END L_Entry

; End of source
