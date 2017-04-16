.global cmp_stub
.global skip_esp
.global and_stub
.global pop_ecx
.global read8
.global read16
.global read32
.global movcnt

cmp_eq_stub:
	cmp %ebx, %eax
	jnz eq_next

	ret

	eq_next:
		jmp *%ecx

cmp_ne_stub:
	cmp %ebx, %eax
	jz ne_next

	ret

	ne_next:
		jmp *%ecx

skip_esp:
	add %esi, %esp
	ret

and_stub:
	and %ecx, %eax
	ret

pop_ecx:
	pop %ecx
	ret

read8:
	movb (%eax), %al
	and $0xff, %eax
	ret

read16:
	movw (%eax), %ax
	and $0xffff, %eax
	ret

read32:
	mov (%eax), %eax
	ret


movcnt:
	mov %eax, %edi
	ret

movaddr:
	mov %eax, %edx
	ret

writeaddr16:
	movw %ax, (%edx)
	ret

writeaddr8:
	movb %al, (%edx)
	ret

mulcnt:
	mul %edi
	ret

subcnt:
	sub %edi, %eax
	ret

xorcnt:
	xor %edi, %eax
	ret

movcntedi:
	mov %edi, %ebx
	ret

shiftleft:
	shl %cl, %eax
	ret

shiftright:
	shr %cl, %eax
	ret
