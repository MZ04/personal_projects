bits 16 	; tells that we are working in 16-bit real mode

; Boot sector: sector of a persistent data storage device which contains machine code
;              to be loaded into the RAM and then executed by a computer system's build-in firmware

; POST (Power-On Self-Test): BIOS's way of ensuring that the essential hw components are functional

; Booting: 1.Processor looks at physical address 0xFFFFFFF0 for the BIOS code
;          2.BIOS POSTs and searches for acceptable boot media (searches for a bootable device)
;          3.If bootable, the BIOS loads the first 512 bytes of the drive into memory address 0x007C00
;          4.Tranfers program control to this address

; Acceptable boot device: Its boot sector (first 512 bytes of the disk) are readable
;                         Ends in the exact bytes 0x55AA, which is the boot signature

; The memory is divided into segments, which are divided into paragraphs

; ----------------------------------------
; STACK SETUP

; ax = general register
; 0x7C0 = start of the segment
; ds = segment register
;      like a pointer to a segment
;      holds the data segment that your program accesses
mov ax, 0x7C0 ;we use ax as a intermediate since we can't load a value directly into the segment register
mov ds, ax

; ss = holds the stack segment that your program uses
; (0x7C0 = 31744) + 512 bytes = (32256 = 0x7E00)
mov ax, 0x7E0 ;we always use sx as an intermediate
mov ss, ax

; Since the stack pointer decreases, we establish a stack maximum size (8k) and add to the stack segment
; sp = offset that identifies the beginning of the stack
mov sp, 0x2000
; --------------------------------------

call clearscreen

push 0x0000
call movecursor
add sp, 2

push msg
call print
add sp, 2

cli
hlt	; cli + hlt tell to the OS not to respond to any interrupt

; -------------------------------------
; SUBROUTINE DEFINITION

; Subroutine to clear the screen
; The beginning and the end of the subroutine constitutes the standard calling convention between caller and callee

clearscreen:
	push bp
	mov bp, sp
	pusha           ; push the previously saved data of the general registers in the stack

	mov ah, 0x07	; tells BIOS to scroll down window
	mov al, 0x00	; clear entire window
	mov bh, 0x07	; black bacground behind light-gray text
	mov cx, 0x00	; specifies top left of screen as (0,0)
	mov dh, 0x18	; 18h = 24 rows of chars
	mov dl, 0x4f    ; 4fh = 79 cols of chars
	int 0x10	; calls video interrupt

	popa	 	; pop every word from the stack into the general-purpose register
                        ; used to retrieve the data stored at the beginning
	mov sp, bp
	pop bp
	ret

; Subroutine for moving the cursor to an arbitrary (row, col) position on the screen
; We must set DX to a two byte valye -> 1st = desired row, 2nd = desired column
; bh refers to the fact that BIOS allows you to draw to off-screen pages (double buffering)
movecursor:
	push bp
	mov bp, sp
	pusha

	mov dx, [bp+4]	; get the argument from the stack. |bp| = 2, |arg| = 2
			; moves the argument we passed into the dx register
	mov ah, 0x02	; set cursor position
	mov bh, 0x00	; page 0 - doesn't matter, we're not using double-buffering
	int 0x10

	popa
	mov sp, bp
	pop bp
	ret

print:
	push bp
	mov bp, sp
	pusha

	mov si, [bp+4]	; grab the pointer to the data
	mov bh, 0x00	; page number, 0 again
	mov bl, 0x00	; foreground color, irrelevant - in text mode
	mov ah, 0x0E	; print character to TTY

.char:
	mov al, [si]	; get the current char from our pointer position
	add si, 1	; keep incrementing si until we see a null char
	or al, 0
	je .return	; end if the string is done
	int 0x10	; print the character if we're not done
	jmp .char	; keep looking

.return:
	popa
	mov sp, bp
	pop bp
	ret

msg:    db "Hello World!", 0 ; simply defines a symbolic name that represents the memory containing the message "Hello World!"
                             ; 0 = null terminator

times 510 - ($ - $$) db 0
dw 0xAA55
; -----------------------------
