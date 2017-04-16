start:
	mov r11, #0xc0de
	lsl r11, #16

	mov r0, @welcome_str
	call print

	mov r9, #0

	tweakloop:
		mov r0, @prompt0
		call print

		mov r0, @stdin_buf
		add r0, r11
		mov r1, #16
		call read_stdin

		mov r0, @stdin_buf
		ldrb r0, [r0]
		call hex2int

		mov r8, @keydata
		add r8, r0

		mov r0, @prompt1
		call print

		mov r0, @stdin_buf
		add r0, r11
		mov r1, #16
		call read_stdin

		mov r0, @stdin_buf
		ldrb r0, [r0]
		call hex2int

		mov r3, #0
		ldrb r2, [r8,r3]
		sub r2, r0
		strb r2, [r8,r3]

		add r9, #1
		cmp r9, #8
	bne tweakloop

final:
	mov r0, @try_str
	call print

	mov r0, @keydata
	mov r1, #16
	call addsum

	add r0, #0xf73b
	cmp r0, #0xffff

	bne fail

	mov r0, @encdata
	mov r1, @keydata
	mov r2, @encdata_end
	sub r2, r0
	call tea_decrypt_blob

	mov r0, @encdata
	call print

	exit

fail:
	mov r0, @fail_str
	call print


	exit

# in  : r0 = char*
print:
	push lr

	mov r4, r0

	call strlen
	mov r2, r0

	mov r1, r4
	add r1, r11

	mov r0, #1
	sc #0x04

	pop lr	
ret

# r0=buf, r1=maxlen
read_stdin:
	mov r2, r1
	mov r1, r0
	mov r0, #0
	sc #0x03
ret

# in  : r0 = char*
# out : r0 = string length
strlen:
	mov r1, #0

	strlen_loop:
		ldrb r2, [r0,r1]
		cmp r2, #0
		beq strlen_done
		add r1, #1
	jmp strlen_loop

	strlen_done:
		mov r0, r1
ret

# r0=*data, r1=*key, r2=len
tea_decrypt_blob:
	push lr

	mov r4, r0
	mov r5, r1
	mov r6, r2
	mov r7, #0

	tea_decrypt_blob_loop:
		mov r0, r4
		mov r1, r5
		call tea_decrypt

		add r4, #8

		sub r6, #8
		cmp r6, #0
	bne tea_decrypt_blob_loop

	pop lr
ret

# r0=*v, r1=*k
tea_decrypt:
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push lr

	# v0
	ldr r4, [r0,#0]
	# v1
	ldr r5, [r0,#4]
	# sum
	mov r6, #0x5ba3
	lsl r6, #16
	add r6, #0x22e0
	# i
	mov r7, #0
	# delta
	mov r3, #0xbadd
	lsl r3, #16
	add r3, #0x1917
	
	tea_decrypt_loop:
		# v1 -= (v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3)
		mov r2, r4
		lsl r2, #4
		ldr lr, [r1,#8]
		add r2, lr
		mov lr, r4
		add lr, r6
		xor r2, lr
		push r2
		mov lr, r4
		lsr lr, #5
		ldr r2, [r1,#12]
		add lr, r2
		pop r2
		xor r2, lr
		sub r5, r2

		# v0 -= (v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1)
		mov r2, r5
		lsl r2, #4
		ldr lr, [r1,#0]
		add r2, lr
		mov lr, r5
		add lr, r6
		xor r2, lr
		push r2
		mov lr, r5
		lsr lr, #5
		ldr r2, [r1,#4]
		add lr, r2
		pop r2
		xor r2, lr
		sub r4, r2
		
		# sum -= delta
		sub r6, r3

		add r7, #1
		cmp r7, #32
	bne tea_decrypt_loop

	str r4, [r0,#0]
	str r5, [r0,#4]

	pop lr
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
ret

# r0=ptr*, r1=len
addsum:
	mov r3, #0

	addsum_loop:
		ldrb r2, [r0]
		add r3, r2

		add r0, #1
		sub r1, #1
		cmp r1, #0
	bne addsum_loop

	mov r0, r3
ret


# r0=char
hex2int:
	mov r1, #0
	mov r2, @tab1
	h2int_loop:
		mov r3, #0
		ldrb r3, [r2,r3]
		cmp r0, r3
		beq h2int_done

		add r2, #1
		add r1, #1
		cmp r1, #16
	bne h2int_loop

	sub r1, #1

h2int_done:
	mov r0, r1

ret

tab1:
	.string "0123456789abcdef"

test_str:
	.string "lolhax\n"

welcome_str:
	.incbin "./inc/welcome.txt"

.byte 0

prompt0:
	.string "INGREDIENT (0-f)  > "

prompt1:
	.string "TWEAK VALUE (0-4) > "

try_str:
	.string "OK LETS TRY THIS RECIPE..\n"

fail_str:
	.string "UGH.. THAT TASTES HORRIBLE :(\n"

keydata:
	.incbin "./data/key.bin.botched"

encdata:
	.incbin "./data/flag.bin.enc"
encdata_end:

.byte 0

stdin_buf:
	.long 0
	.long 0
	.long 0
	.long 0
