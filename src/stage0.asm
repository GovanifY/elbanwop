start:
	mov r11, #0xc0de
	lsl r11, #16

	mov r0, @clown
	call print

	mov r0, @rap_string
	call typewriter

	loopje:
		mov r0, @prompt_string
		call print	
		
		mov r0, @stdin_buf
		add r0, r11
		mov r1, #16
		call read_stdin

		mov r6, @stdin_buf

		mov r1, #0

		ldrb r0, [r6,#0]
		add r1, r0
		add r1, #0x9b
		ldrb r0, [r6,#1]
		add r1, r0
		add r1, #0xce
		ldrb r0, [r6,#2]
		add r1, r0
		add r1, #0x92
		ldrb r0, [r6,#3]
		add r1, r0
		add r1, #0xce
		ldrb r0, [r6,#4]
		add r1, r0
		add r1, #0x8b
		ldrb r0, [r6,#5]
		add r1, r0
		add r1, #0x8d
		ldrb r0, [r6,#6]
		add r1, r0
		add r1, #0xce
		ldrb r0, [r6,#7]
		add r1, r0
		add r1, #0x85

		cmp r1, #0x7f8
		beq passok
		
		mov r0, @nope_str
		call print
	jmp loopje
	
	passok:
		mov r0, @yeah_str
		call print

	# unxor next stage using password
	mov r0, @stage1
	mov r1, @stage1_end
	sub r1, r0

	mov r3, @stage1
	mov r7, r1

	mov r5, @stdin_buf

	mov r6, #0
	mov r4, #0

	mov r8, #0x2000

	xorloop:
		ldrb r0, [r3,r4]
		ldrb r1, [r5,r6]
		xor r0, #0xaa
		xor r0, r1
		strb r0, [r8,r4]

		add r6, #1
		cmp r6, #8
		bne skip_reset_r6

		mov r6, #0

		skip_reset_r6:

		add r4, #1
		cmp r4, r7
	bne xorloop

	.long 0xc2002000

	exit

# r0=buf, r1=maxlen
read_stdin:
	mov r2, r1
	mov r1, r0
	mov r0, #0
	sc #0x03
ret

# r0=char*
typewriter:
	push r4
	
	mov r4, r0

	writerloop:
		ldrb r0, [r4]
		cmp r0, #0x00
		beq writerdone

		mov r0, #1
		mov r1, r4
		add r1, r11
		mov r2, #1
		sc #0x04

		mov r0, @tv
		add r0, r11
		mov r1, #0

		sc #162

		add r4, #1
	jmp writerloop

	writerdone:
		pop r4

ret

# r0=char*
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

# in  : r0 = char*
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

tv:
	.long 0
	#.long 0
	.long 0x0ffffff


prompt_string:
	.string "  ### WH0'S Y0UR F4V0RiTE CL0WN?\n  >>> "

rap_string:
	.incbin "./inc/rap.txt"

.byte 0

nope_str:
	.string "  $$$ NOPE!\n"

yeah_str:
	.string "  $$$ YEAH!\n"

clown:
	.incbin "./inc/clown.txt"

.byte 0

stdin_buf:
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0

stage1:
.incbin "stage1.bin.enc"
stage1_end:
