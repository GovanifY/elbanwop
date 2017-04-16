#ifndef __MACROS_H__
#define __MACROS_H__

.macro SET_EAX value
	.long G_POP_EAX
	.long \value
.endm

.macro SET_EBX value
	.long G_POP_EBX
	.long \value
.endm

.macro SET_EDX value
	.long G_POP_EDX
	.long \value
.endm

.macro LOOP label
	.long G_MOV_EAX_ESP
	.long G_POP_ESI
	.long (. - \label - 4)
	.long G_SUB_EAX_ESI_POP_ESI_POP_EDI
	.long 0x11223344
	.long 0x55667788
	.long G_XCHG_EAX_ESP
.endm

.macro LOOP_COND label, addr, max
	READ32 \addr
	.long G_POP_ECX_EBX
	.long G_ADD_ESP_28
	.long \max

	.long G_COND_NE
	LOOP \label
.endm

.macro WRITE32 addr, val
	.long G_POP_EAX
	.long \val
	.long G_POP_EDX
	.long \addr
	.long G_MOV_PTR_EDX_EAX
.endm

.macro WRITE32_EAX addr
	.long G_POP_EDX
	.long \addr
	.long G_MOV_PTR_EDX_EAX
.endm

.macro READ32 addr
	.long G_POP_EAX
	.long \addr-4
	.long G_MOV_EAX_PTR_EAX_PLUS4
.endm

.macro SYSCALL3 sc, a0, a1, a2
	.long G_POP_ECX_EBX
	.long \a1
	.long \a0
	.long G_POP_EDX
	.long \a2
	.long G_POP_EAX
	.long \sc
	.long G_SYSCALL
.endm

.macro ADDR_EAX label
	.long G_MOV_EAX_ESP
	.long G_POP_EDI
	.long (\label - . + 4)
	.long G_ADD_EAX_EDI_POP_EDI	
	.long 0x44444444
.endm

.macro ADDR_EBX label
	ADDR_EAX \label
	.long G_MOV_EBX_EAX
.endm

.macro ADDR_ECX label
	ADDR_EAX \label
	.long G_MOV_ECX_EAX
.endm

.macro ADDR_EDX label
	ADDR_EAX \label
	.long G_MOV_EDX_EAX
.endm

.macro SYSCALL num
	SET_EAX \num
	.long G_SYSCALL
.endm

.macro PRINT_STRING label
	SET_EBX STDOUT
	ADDR_ECX \label
	SET_EDX (\label\()_end - \label - 1)
	SYSCALL NR_WRITE	
.endm

.macro ADD_EAX v
	.long G_POP_EDI
	.long \v
	.long G_ADD_EAX_EDI_POP_EDI
	.long 0x66666666
.endm

.macro READ_INPUT buf, len
	.long G_POP_ECX_EBX
	.long \buf
	.long STDIN
	.long G_POP_EDX
	.long \len
	SYSCALL NR_READ
.endm

.macro INC_VAR addr
	READ32 \addr
	.long G_INC_EAX
	.long G_POP_EDX
	.long \addr
	.long G_MOV_PTR_EDX_EAX
.endm

.macro ANDVAL value
	.long G_POP_ECX
	.long \value
	.long G_AND_EAX_ECX
.endm

.macro LEFTSHIFTVAL value
	.long G_POP_ECX
	.long \value
	.long G_SHL_EAX_CL
.endm

.macro RIGHTSHIFTVAL value
	.long G_POP_ECX
	.long \value
	.long G_SHR_EAX_CL
.endm

.macro IF_BASE name, value
	.long G_POP_EBX
	.long \value
	.long G_POP_ESI
	.long (false_\()\name - true_\()\name)
	.long G_POP_ECX
	.long G_SKIP_ESP
.endm

.macro IF_EQUAL name, value
	IF_BASE \name, \value
	.long G_COND_EQ
	true_\()\name\():
.endm

.macro IF_CNT_EQUAL name
	.long G_MOV_EBX_EDI
	.long G_POP_ESI
	.long (false_\()\name - true_\()\name)
	.long G_POP_ECX
	.long G_SKIP_ESP
	.long G_COND_EQ
	true_\()\name\():
.endm

.macro IF_NOT_EQUAL name, value
	IF_BASE \name, \value
	.long G_COND_NE
	true_\()\name\():
.endm

.macro ELSE name
	.long G_POP_ESI
	.long (end_\()\name - false_\()\name)
	.long G_SKIP_ESP
	false_\()\name\():
.endm

.macro ENDIF name
	end_\()\name\():
.endm

.macro ENDIF_SINGLE name
	ELSE \name
	ENDIF \name
.endm

.macro GOTO label
	.long G_POP_ESI
	.long (\label - 1f)
	.long G_SKIP_ESP
	1:
.endm

.macro STRING name, value
	str_\()\name:
		.string \()\value\()
	str_\()\name\()_end:
.endm

.macro FCALL3 func, a0, a1, a2
	.long \func
	.long G_POP_EBX_ESI_EDI
	0:
	.long \a0
	1:
	.long \a1
	2:
	.long \a2
.endm

.macro PATCHARGPTR n, label
	ADDR_EDX \n\()f
	ADDR_EAX \label
	.long G_MOV_PTR_EDX_EAX
.endm

.macro MOVCNT
	.long G_MOV_EDI_EAX
.endm

.macro MOVADDR
	.long G_MOV_EDX_EAX
.endm

.macro ADDCNT
	.long G_ADD_EAX_EDI_POP_EDI
	.long 0x77777777
.endm

.macro SUBCNT
	.long G_SUB_EAX_EDI
.endm

.macro XORCNT
	.long G_XOR_EAX_EDI
.endm

.macro WRITEADDR
	.long G_MOV_PTR_EDX_EAX
.endm

.macro WRITEADDR16
	.long G_MOV_PTR_EDX_AX
.endm

.macro WRITEADDR8
	.long G_MOV_PTR_EDX_AL
.endm


.macro READA
	.long G_MOV_EAX_PTR_EAX
.endm

.macro MULVAL val
	.long G_POP_EDI
	.long \val
	.long G_MUL_EDI
.endm

#endif
