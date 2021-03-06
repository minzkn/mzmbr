/*
 Source name : mbr-mz.s
 Platform    : Intel 80x86
 Binary size : Sector size (512)
 Date        : 2002-03-26 TUE
 License     : GPL (GNU Public License)

 Copyright (C) MINZKN.COM
 All rights reserved.

 Maintainers
   JaeHyuk Cho <mailto:minzkn@minzkn.com>
*/

DEF_SIZE_Sector            = 0x200
DEF_SIZE_Paragraph         = 0x10
DEF_SIZE_TemporaryStack    = DEF_SIZE_Sector

DEF_SEGMENT_BeginBoot      = 0x07c0
DEF_SEGMENT_CopyBoot       = 0x0050
DEF_SEGMENT_OSLoader       = 0x0080

.code16                                            # use16
.global mzboot

# Startup entry
.org 0x0000
mzboot:                                            # DEF_SEGMENT_BeginBoot:0
#if 1L
	# "MZ", MS-DOS header
	.byte 0x4d
	.byte 0x5a
#endif

	cli                                        # Clear interrrupt flag

	movw %cs, %ax                              # Source segment
	movw %ax, %ds 
	
	callw L_DetectIndexPointer                 # Detect source index pointer register
L_DetectIndexPointer:
	popw %si
	subw $(L_DetectIndexPointer - mzboot), %si
	
	movw $DEF_SEGMENT_CopyBoot, %ax            # Destination segment
	movw %ax, %es

	xorw %di, %di                              # Target index pointer register

	cld                                        # Clear direction flag

	movw $(DEF_SIZE_Sector / 2), %cx           # Copy sector
	repz
	movsw
 
	ljmp $DEF_SEGMENT_CopyBoot, $L_RealStartUp # Long jump to real-entry
L_RealStartUp:

	movw %ax, %ds                              # Initialize segment and stack-position
	movw %ax, %ss
	movw $(DEF_SIZE_Sector + DEF_SIZE_TemporaryStack), %sp

        # Complete ready boot
	# sti

	callw L_DiskReset                          # Reset disk parameter	
	jnc L_ResetOK

	# Error +++++++++ Unknown disk
	jmp L_Error_UnknownDisk

L_ResetOK:
	movw $0x0004, %cx                          # Seek count 4 (Partition count)
	movw $L_PartitionTable, %si
L_SeekBoot:
	cmpb $0x80, (%si)
	je L_SeekOK
	addw $DEF_SIZE_Paragraph, %si
	loop L_SeekBoot

	# Error ++++++++ Invalid partition
	jmp L_Error_InvalidPartition

L_SeekOK:
	movw $DEF_SEGMENT_OSLoader, %ax
	movw %ax, %es 
	movw $0x0201, %ax
	xorw %bx, %bx
	movw 0x02(%si), %cx
	movw 0x00(%si), %dx
	int $0x13
	jnc L_LoadOK

	# Error ++++++++ Destroy disk
	jmp L_Error_DestroyDisk

L_LoadOK: 

L_GoBoot:
	ljmp $DEF_SEGMENT_OSLoader, $0

L_ShutDown:                                        # No way~ loop and loop and loop and ...
	jmp L_ShutDown 

	
# Function call ===================================

L_ReCallBIOS:                                      # BIOS Setup 
	int $0x18
	jmp L_ShutDown

L_DiskReset:                                       # Drive motor off (Reset)
	xorw %ax, %ax
	movb $0x80, %dl
	int $0x13
	ret

L_Puts:                                            # Print message (SI)
	lodsb
	or %al, %al
	jz L_Puts_Return
	movb $0x0e, %ah
	movw $0x0700, %bx
	int $0x10
	jmp L_Puts
L_Puts_Return:
	ret

L_PressAnyKey:
	xorw %ax, %ax
	int $0x16
	ret

# Error ===========================================

L_Error_UnknownDisk:
	movw $L_String_UnknownDisk, %si
	call L_Puts
	call L_PressAnyKey
	call L_ReCallBIOS
	jmp L_ShutDown
L_Error_InvalidPartition:
	movw $L_String_InvalidPartition, %si
	call L_Puts
	call L_PressAnyKey
	call L_ReCallBIOS
	jmp L_ShutDown
L_Error_DestroyDisk:
	movw $L_String_DestroyDisk, %si
	call L_Puts
	call L_PressAnyKey
	call L_ReCallBIOS
	jmp L_ShutDown

# String ==========================================

L_String_UnknownDisk:
	.byte 0x0d, 0x0a
	.ascii "Unknown disk"
	.byte 0x0d, 0x0a, 0x00
L_String_InvalidPartition:
	.byte 0x0d, 0x0a
	.ascii "Invalid partition"
	.byte 0x0d, 0x0a, 0x00
L_String_DestroyDisk:
	.byte 0x0d, 0x0a
	.ascii "Destroy disk"
	.byte 0x0d, 0x0a, 0x00

# Partition table =================================

.org 0x01be
L_PartitionTable:
L_Partition0:         .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                      .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
L_Partition1:         .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                      .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
L_Partition2:         .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                      .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
L_Partition3:         .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
                      .byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
L_InitialSector:      .word 0xaa55                 # Check word

End_of_boot:

# End of source 
