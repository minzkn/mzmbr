; ---------------------------- [ MINKN's IDE PIO mode ] -----------------------------------

DEF_IDE_PORT_Data  = 0000h
DEF_IDE_PORT_Error = 0001h ; read
DEF_IDE_PORT_NSector = 0002h
DEF_IDE_PORT_Sector = 0003h
DEF_IDE_PORT_LCylinder = 0004h
DEF_IDE_PORT_HCylinder = 0005h
DEF_IDE_PORT_Current = 0006h
DEF_IDE_PORT_Status = 0007h ; read
DEF_IDE_PORT_Feature = DEF_IDE_PORT_Error ; write
DEF_IDE_PORT_Command = DEF_IDE_PORT_Status ; write
DEF_IDE_PORT_CMD   = 03F6h
;
DEF_IDE_PORT_CMD_SRST = 04h
;
DEF_IDE_ERR_AMNF   = 01h
DEF_IDE_ERR_TK0NF  = 02h
DEF_IDE_ERR_ABRT   = 04h
DEF_IDE_ERR_MCR    = 08h
DEF_IDE_ERR_IDNF   = 10h
DEF_IDE_ERR_MC     = 20h
DEF_IDE_ERR_UNC    = 40h
DEF_IDE_ERR_BBK    = 80h
;
DEF_IDE_STAT_ERR   = 01h
DEF_IDE_STAT_IDX   = 02h
DEF_IDE_STAT_CORR  = 04h
DEF_IDE_STAT_DRQ   = 08h
DEF_IDE_STAT_DSC   = 10h
DEF_IDE_STAT_DF    = 20h
DEF_IDE_STAT_DRDY  = 40h
DEF_IDE_STAT_BSY   = 80h

IDE_GetBasePort    PROC NEAR ; DX near pascal IDE_GetBasePort(unsigned int s_fixed, unsigned int s_index)
                   PUSH BP
                   MOV BP, SP
                   PUSH BX
                   MOV BX, WORD PTR [BP + 06h]             ; s_fixed
                   SHL BX, 01h
                   MOV DX, WORD PTR MZ_CODE:IDE_BasePort[BX]
                   ADD DX, WORD PTR [BP + 04h]             ; s_index
                   POP BX
                   POP BP
                   RETN 2 + 2
IDE_GetBasePort    ENDP

IDE_WhileBusy      PROC NEAR ; CX near pascal IDE_WhileBusy(unsigned int s_fixed)
                   PUSH BP
                   MOV BP, SP
                   PUSH AX
                   PUSH DX
                   PUSH WORD PTR [BP + 04h]                ; s_fixed
                   PUSH DEF_IDE_PORT_Status
                   CALL NEAR PTR MZ_CODE:IDE_GetBasePort
                   MOV CX, 0FFFFH ; Timeout loop count
L_IDE_WhileBusy_00 LABEL SHORT
                   IN AL, DX
                   AND AL, (DEF_IDE_STAT_BSY OR DEF_IDE_STAT_DRDY OR DEF_IDE_STAT_DF OR DEF_IDE_STAT_DSC OR DEF_IDE_STAT_ERR)
                   CMP AL, DEF_IDE_STAT_DRDY OR DEF_IDE_STAT_DSC
                   LOOPNE SHORT L_IDE_WhileBusy_00
                   POP DX                   
                   POP AX
                   POP BP
                   RETN 2
IDE_WhileBusy      ENDP

IDE_WriteByte      PROC NEAR ; CX near pascal IDE_WriteByte(unsigned int s_fixed, unsigned int s_port, unsigned int s_byte)
                   PUSH BP
                   MOV BP, SP
                   PUSH WORD PTR [BP + 08h]                ; s_fixed
                   CALL NEAR PTR MZ_CODE:IDE_WhileBusy
                   JCXZ SHORT L_IDE_WriteByte_00
                   PUSH AX
                   PUSH DX
                   MOV DX, WORD PTR [BP + 06h]             ; s_port
                   MOV AL, BYTE PTR [BP + 04h]             ; s_byte
                   OUT DX, AL
                   POP DX
                   POP AX
L_IDE_WriteByte_00 LABEL SHORT
                   POP BP
                   RETN 2 + 2 + 2
IDE_WriteByte      ENDP

IDE_ReadByte       PROC NEAR ; CX, AX near pascal IDE_ReadByte(unsigned int s_fixed, unsigned int s_port)
                   PUSH BP
                   MOV BP, SP
                   XOR AX, AX
                   PUSH WORD PTR [BP + 06h]                ; s_fixed
                   CALL NEAR PTR MZ_CODE:IDE_WhileBusy
                   JCXZ SHORT L_IDE_ReadByte_00
                   PUSH DX
                   MOV DX, WORD PTR [BP + 04h]             ; s_port
                   IN AL, DX
                   POP DX
L_IDE_ReadByte_00  LABEL SHORT
                   POP BP
                   RETN 2 + 2
IDE_ReadByte       ENDP

IDE_GetSize        PROC NEAR ; EAX pascal IDE_GetSize(unsigned int s_fixed, unsigned int s_device)
                   PUSH BP
		   MOV BP, SP
                   JMP SHORT L_IDE_GetSize_00
IDE_GetSize        ENDP

IDE_GetMaxSize     PROC NEAR ; EAX pascal IDE_GetMaxSize(unsigned int s_fixed, unsigned int s_device)
                   ; unsigned int s_fixed        : 06h
                   ; unsigned int s_device       : 04h
                   PUSH BP
		   MOV BP, SP

		   ; Set LBA mode & select device & head=0
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Current ; 6 
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AX, WORD PTR [BP + 04h] ; s_device 
		   SHL AX, 04h
		   OR AL, 80H OR 20H OR 40H ; Select LBA mode
                   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_GetMaxSize_00
		  
                   ; Read native address max mode
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Status  ; 7
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, 0F8h ; Read native max address (F9h?) 
                   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_GetMaxSize_00

L_IDE_GetSize_00   LABEL SHORT
		   
                   ; Read sector number
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Sector  ; 3
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_GetMaxSize_00
		   MOV BYTE PTR MZ_CODE:HDD_SectorNumber, AL
                   
		   ; Read cylinder number low
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_LCylinder ; 4
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_GetMaxSize_00
		   MOV BYTE PTR MZ_CODE:HDD_CylinderNumber[0], AL
		   
		   ; Read cylinder number high
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_HCylinder ; 5 
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_GetMaxSize_00
		   MOV BYTE PTR MZ_CODE:HDD_CylinderNumber[1], AL

		   ; Read head number
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Current ; 6 
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_GetMaxSize_00
		   AND AX, 000FH ; Only low 4 bit !!!
		   MOV BYTE PTR MZ_CODE:HDD_HeadNumber, AL

                   ; When error
		   JMP SHORT L_IDE_GetMaxSize_01
L_IDE_GetMaxSize_00 LABEL SHORT
                   XOR EAX, EAX
		   JMP SHORT L_IDE_GetMaxSize_02
L_IDE_GetMaxSize_01 LABEL SHORT
		   
		   ; Status check 
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Status ; 7 
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 06h] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_GetMaxSize_00

                   ; Calc max
		   XOR EAX, EAX
		   MOV AL, BYTE PTR MZ_CODE:HDD_HeadNumber
		   SHL EAX, 10H
		   MOV AX, WORD PTR MZ_CODE:HDD_CylinderNumber
		   SHL EAX, 08h
		   MOV AL, BYTE PTR MZ_CODE:HDD_SectorNumber
		   INC EAX

L_IDE_GetMaxSize_02 LABEL SHORT

		   POP BP
		   RETN 2 + 2
IDE_GetMaxSize     ENDP

IDE_SetLimit       PROC NEAR ; AX pascal IDE_SetLimit(unsigned int s_fixed, unsigned int s_device, unsigned long s_limitsize, unsigned int s_switch)
                   ; unsigned int s_fixed        : 0Ch
                   ; unsigned int s_device       : 0Ah
                   ; unsigned int s_limitsize    : 06h
		   ; unsigned int s_switch       : 04h
                   PUSH BP
		   MOV BP, SP

                   ; Set data
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Data  ; 0
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   XOR AL, AL
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

		   ; Set feature
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Feature  ; 1
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   XOR AL, AL
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00
                   
		   ; Set nSector (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_NSector ; 2
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, BYTE PTR [BP + 04h] ; s_switch
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

                   DEC DWORD PTR [BP + 06h] ; s_limitsize -= 1

		   ; Set nSector (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_NSector ; 3
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, BYTE PTR [BP + 06h] ; s_limitsize(sectors)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

		   ; Set cylinder low (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_LCylinder ; 4
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, BYTE PTR [BP + 06h + 01h] ; s_limitsize(cylinder low)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00
		  
		   ; Short pass point
		   JMP L_IDE_SetLimit_01
L_IDE_SetLimit_00  LABEL SHORT                   
                   XOR AX, AX ; Return false
		   JMP NEAR PTR L_IDE_SetLimit_02
L_IDE_SetLimit_01  LABEL SHORT                   
               
		   ; Set cylinder high (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_HCylinder ; 5
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, BYTE PTR [BP + 06h + 02h] ; s_limitsize(cylinder high)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

		   ; Set head (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Current ; 6
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, BYTE PTR [BP + 0AH] ; s_device
		   SHL AL, 04h
		   OR AL, BYTE PTR [BP + 06h + 03h] ; s_limitsize(head)
                   OR AL, 80H OR 20H OR 40H
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

		   ; Set command (on feature mode)
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Command ; 7
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   MOV AL, 0F9h ; Set max command
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX ; s_port
		   PUSH AX
		   CALL NEAR PTR MZ_CODE:IDE_WriteByte
                   JCXZ SHORT L_IDE_SetLimit_00

                   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR [BP + 0Ah] ; s_device
		   CALL NEAR PTR MZ_CODE:IDE_GetSize ; Re get size

		   ; Finish feature mode 
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH WORD PTR DEF_IDE_PORT_Feature ; 1 
		   CALL NEAR PTR MZ_CODE:IDE_GetBasePort ; Return DX
		   PUSH WORD PTR [BP + 0Ch] ; s_fixed
		   PUSH DX
                   CALL NEAR PTR MZ_CODE:IDE_ReadByte
                   JCXZ SHORT L_IDE_SetLimit_00
		   
		   MOV AX, 01H ; Return true

L_IDE_SetLimit_02  LABEL NEAR                   
		   POP BP
		   RETN 2 + 2 + 2
IDE_SetLimit       ENDP
; -----------------------------------------------------------------

; End of header
