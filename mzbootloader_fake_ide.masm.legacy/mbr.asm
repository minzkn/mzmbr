COMMENT #
 Copyright (c) JaeHyuk Cho <mailto:minzkn@minzkn.com>
 All right reserved.

 [ChangeLog]
 - 2004.3.24 : Project start
#

.286
.RADIX 000AH

DEF_ORG_ENTRY      = 0000H

DEF_CODE_FAR_JUMP  = 0EAH

DEF_CODE_MAGIC     = 2745D

DEF_SEG_STACK      = 0050H
DEF_SEG_COPY       = 0070H
DEF_SEG_OS1        = 0090H
DEF_SEG_OS2        = 00B0H
DEF_SEG_LOADER     = 00D0H
 DEF_SECTNO_LOADER = 51D
 DEF_SECTNO_OS1    = 60D
 DEF_SECTNO_OS2    = 61D
 DEF_NSECT_LOADER  = 2D

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
                   CLI
		   MOV SP, DEF_SEG_STACK
		   MOV SS, SP
		   MOV SP, DEF_SIZE_SECTOR
		   ; STI
                  
                   MOV AX, CS
		   MOV DS, AX
		  
		   CALL NEAR PTR MZ_CODE:L_GetIndexPointer
L_GetIndexPointer  LABEL NEAR		   
                   POP SI
		   SUB SI, OFFSET MZ_CODE:L_GetIndexPointer - OFFSET MZ_CODE:L_Entry

                   ; Pass to loader - BOOT SEG:OFF
                   PUSH CS
		   PUSH SI

                   MOV AX, DEF_SEG_COPY
		   MOV ES, AX
		   XOR DI, DI
		   MOV CX, DEF_SIZE_SECTOR
		   CLD
		   REPZ MOVSB
                
		   DB DEF_CODE_FAR_JUMP 
		   DW OFFSET MZ_CODE:L_StartUp, DEF_SEG_COPY
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

; -----------------------------------------------------------------
L_StartUp          LABEL FAR		   
		   MOV AX, CS
		   MOV DS, AX
		 
		   MOV SI, OFFSET MZ_CODE:L_Message_01
		   CALL NEAR PTR MZ_CODE:L_Puts

L_ResetDisk        LABEL SHORT
		   MOV SI, OFFSET MZ_CODE:L_Message_02
		   CALL NEAR PTR MZ_CODE:L_Puts
                   XOR AX, AX
		   INT DEF_INT_DISK 
		   JNC SHORT L_OK_Reset
                   JMP NEAR PTR L_Drop
L_OK_Reset         LABEL SHORT
              
	           ; OS1 load
                   MOV AX, DEF_SEG_OS1
		   MOV ES, AX
		   XOR BX, BX
                   MOV AX, DEF_FC_READ
		   MOV CX, DEF_SECTNO_OS1
		   MOV DX, DEF_ATTR_HDD
		   INT DEF_INT_DISK
		   JNC SHORT L_OK_OS1
                   JMP NEAR PTR L_Drop
L_OK_OS1           LABEL SHORT
	           ; OS2 load
                   MOV AX, DEF_SEG_OS2
		   MOV ES, AX
		   XOR BX, BX
                   MOV AX, DEF_FC_READ
		   MOV CX, DEF_SECTNO_OS2
		   MOV DX, DEF_ATTR_HDD
		   INT DEF_INT_DISK
		   JNC SHORT L_OK_OS2
                   JMP NEAR PTR L_Drop
L_OK_OS2           LABEL SHORT

		   ; Partition sync
                   CMP BYTE PTR MZ_CODE:L_How, 01H ; OS1 sync ?
		   JNZ SHORT L_NextSync_00

                   MOV SI, OFFSET MZ_CODE:L_Partition 
		   MOV AX, DEF_SEG_OS1
		   MOV ES, AX
		   MOV DI, SI
		   MOV CX, DEF_SIZE_SECTOR
		   CLD
		   REPZ MOVSB
                   XOR BX, BX
		   MOV AX, 0301H
		   MOV CX, 0001H
		   MOV DX, 0080H
		   INT DEF_INT_DISK
		   JNC SHORT L_OK_SyncOS1
                   JMP NEAR PTR L_Drop
L_OK_SyncOS1       LABEL SHORT

                   JMP SHORT L_SyncDone
L_NextSync_00      LABEL SHORT		   
                   CMP BYTE PTR MZ_CODE:L_How, 02H ; OS2 sync ?
		   JNZ SHORT L_NextSync_01
                   
;		   MOV SI, OFFSET MZ_CODE:L_Partition 
;		   MOV AX, DEF_SEG_OS2
;		   MOV ES, AX
;		   MOV DI, SI
;		   MOV CX, DEF_SIZE_SECTOR
;		   CLD
;		   REPZ MOVSB
;                  XOR BX, BX
;		   MOV AX, 0301H
;		   MOV CX, 0001H
;		   MOV DX, 0080H
;		   INT DEF_INT_DISK
;		   JNC SHORT L_OK_SyncOS2
;                   JMP NEAR PTR L_Drop
;L_OK_SyncOS2       LABEL SHORT

                   JMP SHORT L_SyncDone
L_NextSync_01      LABEL SHORT
L_SyncDone         LABEL SHORT

                   MOV AX, DEF_SEG_LOADER
		   MOV ES, AX
		   XOR BX, BX
		   MOV CX, DEF_SECTNO_LOADER
		   MOV DX, DEF_NSECT_LOADER
L_InstallLoader    LABEL SHORT
                   PUSH BX
		   PUSH CX
                   PUSH DX
                   MOV AX, DEF_FC_READ
		   MOV DX, DEF_ATTR_HDD
		   INT DEF_INT_DISK
		   JC SHORT L_Drop
		   MOV SI, OFFSET MZ_CODE:L_Message_03
		   CALL NEAR PTR MZ_CODE:L_Puts
                   POP DX
		   POP CX
		   POP BX
		   ADD BX, DEF_SIZE_SECTOR
		   INC CX
		   SUB DX, 0001H
		   JNZ L_InstallLoader
		 
		   MOV SI, OFFSET MZ_CODE:L_Message_04
		   CALL NEAR PTR MZ_CODE:L_Puts
                 
                   MOV AX, DEF_SEG_LOADER
		   MOV ES, AX

		   CMP WORD PTR ES:[0000H], DEF_CODE_MAGIC ; Magic code
		   JNZ L_InvalidLoader
		   
		   MOV SI, OFFSET MZ_CODE:L_Message_05
		   CALL NEAR PTR MZ_CODE:L_Puts
		   
                   MOV AX, DEF_SEG_LOADER
		   MOV DS, AX
		 
		   DB DEF_CODE_FAR_JUMP 
		   DW 0002H + 0004H, DEF_SEG_LOADER ; 총 6바이트 오프셋을 건너뛰어 점프
		 
; -----------------------------------------------------------------
L_InvalidLoader    LABEL SHORT
		   MOV SI, OFFSET MZ_CODE:L_Error_01
		   CALL NEAR PTR MZ_CODE:L_Puts
                   INT DEF_INT_DROP
		   JMP SHORT $ ; Halt

L_Drop:
		   MOV SI, OFFSET MZ_CODE:L_Error_02
		   CALL NEAR PTR MZ_CODE:L_Puts
                   INT DEF_INT_DROP
		   JMP SHORT $ ; Halt
; -----------------------------------------------------------------
L_Message_01       DB "Welcome to XXXX", 0AH, 0DH, 00H
L_Message_02       DB "Reset disk", 0AH, 0DH, 00H
L_Message_03       DB ".", 00H
L_Message_04       DB 0AH, 0DH, 00H
L_Message_05       DB "Pass to loader", 0AH, 0DH, 00H
L_Error_01         DB "Invalid magic code !", 0AH, 0DH, 00H
L_Error_02         DB "Read error !", 0AH, 0DH, 00H
; -----------------------------------------------------------------
                   ORG 01BDH
L_How              DB 00H ; 00H=Not defined, 01H=OS1, 02H=OS2		  
; -----------------------------------------------------------------
                   ORG 01BEH
L_Partition:
L_TABLE_1:         DB 16 DUP (0)
L_TABLE_2:         DB 16 DUP (0)
L_TABLE_3:         DB 16 DUP (0)
L_TABLE_4:         DB 16 DUP (0)
; -----------------------------------------------------------------
L_InitialSector:   DB 055H, 0AAH

L_EndOfSector:
MZ_CODE            ENDS
                   END L_Entry

; End of source
