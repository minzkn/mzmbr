/* 
 Copyright (c) 2004 JaeHyuk Cho <mailto:minzkn@minzkn.com>
 All right reserved.
*/

/* 
 x86 machine's startup entry 
*/

.extern main

.code16
.org 0x0000
L_Entry:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es

	xorw %ax, %ax
	xorb %dl, %dl
	int $0x13
	
	xorw %ax, %ax
	movb $0x80, %dl
	int $0x13
	
	xorw %ax, %ax
	movb $0x81, %dl
	int $0x13

	xorl %eax, %eax
	movw %ds, %ax
	shll $4, %eax
	addl $L_GDT, %eax
	movl %eax, (L_GDTR + 2)

	xorl %eax, %eax
	movw %cs, %ax
	shll $4, %eax
	addl $L_Code32, %eax
	movl %eax, (L_JumpAdjust32)
	
	jmp 0f
0:
	cli	
	lidt L_IDTR      /* fword ptr */
	lgdt L_GDTR      /* fword ptr */
	movl %cr0, %eax
	orb $0x01, %al
	movl %eax, %cr0
	jmp 0f           /* Clear instruction cache */
0:

	.byte 0x66       /* 32bit prefix */
	.byte 0xea       /* SEG16:OFF32 jump */
L_JumpAdjust32:
	.long 0x00000000 /* OFFSET32 */
	.word 0x0008     /* CODE32 */

.align 16
L_GDT: 
	/* GDT 0x0000 (Null) */ 
	.word 0x0000
	.word 0x0000
	.word 0x0000
	.word 0x0000
	/* GDT 0x0008 (Code 32) */
	.word 0xffff
	.word 0x0000
	.word 0x9a00
	.word 0x00cf
	/* GDT 0x0010 (Data 32) */
	.word 0xffff
	.word 0x0000
	.word 0x9200
	.word 0x00cf
L_EndGDT:
L_GDTR: /* GDT register (Limit:WORD, Offset:DWORD) */
	.word L_EndGDT - L_GDT - 1
	.word 0x0000
	.word 0x0000
	.word 0x0000 /* Not used (Alignment) */
L_IDTR: /* IDT register (Limit:WORD, Offset:DWORD */
	.word 0x0000
	.word 0x0000
	.word 0x0000
	.word 0x0000 /* Not used (Alignment) */

.align 4
.code32
L_Code32:
	movw $0x0010, %ax
	movw %ax, %ds
	movw %ax, %es
	movw %ax, %ss
	movl $0x10000, %esp

	/* Page remap */

	call main

	jmp .

.align 16

.globl L_Entry

.end

/* End of source */
