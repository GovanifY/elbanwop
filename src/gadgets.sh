#!/bin/bash

# quick and dirty script used to populate gadgets.h

BINARY=./vuln
RS=`which ropstone.py`

if [ "$RS" == "" ] ; then
	echo "ropstone is needed to locate gadgets"
	echo "grab it from https://github.com/blasty/ropstone"
fi

GADGETS=(
	"POP_EAX:: pop eax ; ret"
	"POP_EBX:: pop ebx ; ret"
	"POP_ECX_EBX:: pop ecx ; pop ebx ; ret"
	"POP_EDX:: pop edx ; ret"
	"POP_EDI:: pop edi ; ret"
	"POP_ESI:: pop esi ; ret"
	"POP_ECX:: pop ecx ; ret"
	"POP_EBX_ESI_EDI:: pop ebx ; pop esi ; pop edi ; ret"
	"MOV_EBX_EAX:: mov ebx, eax ; ret"
	"MOV_ECX_EAX:: mov ecx, eax ; ret"
	"MOV_EDX_EAX:: mov edx, eax ; ret"
	"MOV_EAX_ESP:: mov eax, esp ; ret"
	"XCHG_EAX_ESP:: xchg eax, esp ; ret"
	"SUB_EAX_ESI_POP_ESI_POP_EDI:: sub eax, esi ; pop esi ; pop edi ; ret"
	"ADD_EAX_EDI_POP_EDI:: add eax, edi ; pop edi ; ret"
	"SYSCALL:: int 0x80 ; ret"
	"MOV_PTR_EDX_EAX:: mov [edx], eax ; ret"
	"MOV_PTR_EDX_AX:: mov [edx], ax ; ret"
	"MOV_PTR_EDX_AL:: mov [edx], al ; ret"
	"MOV_EAX_PTR_EAX_PLUS4:: mov eax, [eax+4] ; ret"
	"COND_EQ:: cmp eax, ebx ; jnz next ; ret ; next: jmp ecx"
	"COND_NE:: cmp eax, ebx ; jz next ; ret ; next: jmp ecx"
	"INC_EAX:: inc eax; ret"
	"ADD_ESP_28:: add esp, 28 ; ret"
	"SKIP_ESP:: add esp, esi ; ret"
	"AND_EAX_ECX:: and eax, ecx ; ret"
	"READ8:: mov al, [eax] ; and eax, 0xff ; ret"
	"READ16:: mov ax, [eax] ; and eax, 0xffff ; ret"
	"MOV_EDI_EAX:: mov edi, eax ; ret"
	"MOV_EDX_EAX:: mov edx, eax ; ret"
	"MOV_EAX_PTR_EAX:: mov eax, [eax] ; ret"
	"MUL_EDI:: mul edi ; ret"
	"SUB_EAX_EDI:: sub eax, edi ; ret"
	"XOR_EAX_EDI:: xor eax, edi ; ret"
	"MOV_EBX_EDI:: mov ebx, edi ; ret"
	"SHL_EAX_CL:: shl eax, cl ; ret"
	"SHR_EAX_CL:: shr eax, cl ; ret"
)

FUNCTIONS=(
	"PUTS: _IO_puts"
	"MEMCPY: memcpy"
	"MEMSET: memset"
)

IFS="
"

echo "#ifndef __GADGETS_H__" > gadgets.h
echo "#define __GADGETS_H__" >> gadgets.h

# .data
DATA_ADDR=0x`objdump -D "${BINARY}" | grep "__data_start" | awk '{ print $1 }'`
echo "#define SCRATCH ${DATA_ADDR}" >> gadgets.h

# functions
for f in ${FUNCTIONS[@]}; do
	NAME=`echo "${f}" | awk -F ': ' '{ print $1 }'`
	SYM=`echo "${f}" | awk -F ': ' '{ print $2 }'`

	ADDR=`objdump -D "${BINARY}" | grep "<${SYM}>:" | awk '{ print $1 }'`

	echo "#define F_${NAME} 0x${ADDR}" >> gadgets.h
done

# gadgets
for g in ${GADGETS[@]}; do
		NAME=`echo "${g}" | awk -F ':: ' '{ print $1 }'`
		CODE=`echo "${g}" | awk -F ':: ' '{ print $2 }'`

		ADDR=`python ${RS} --single -S .text "${BINARY}" "${CODE}" | grep ' +' | awk '{ print $2 }'`

		if [ "${ADDR}" == "" ] ; then
			echo "GADGET $NAME NOT FOUND"
			exit 1
		fi

		echo "#define G_${NAME} 0x${ADDR}" >> gadgets.h
done

echo "#endif" >> gadgets.h
