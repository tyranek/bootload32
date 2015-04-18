[org 0x7c00]
[bits 16]

jmp Main

check_a20:    ; checks if A20 line is already enabled, if not, do so
mov ax, 0xFFFF
mov es, ax
mov di, 0x7E0E
mov al, byte[es:di]
cmp al, 0x55
jne .return
mov al, 0x69
mov byte[es:di], al
mov bl, byte[0x7DFE]
cmp bl, 0x69
jne .return

mov ax, 0x2401
int 15h
jnc .return

call .wait
mov al, 0xD1
out 0x64, al
call .wait
mov al, 0xDF
out 0x60, al
call .wait
jmp .return   ; if we ever get to this point, no more checks, we are almost sure A20 is somehow enabled

.wait:
in al, 0x64
test al, 2
jnz .wait
ret

.return:
ret       ; returns to our main code

gdt_start:   ; Global Descriptor Table is critical for entering 32-bits mode
gdt_null:
  dw  0
  dw  0
gdt_code:
  dw  0xFFFF                  ; 4GB limit
  dw  0                       ; base
  db  0                       ; base
  db  10011010b               ; [present][privilege level][privilege level][code segment][code segment][conforming][readable][access]
  db  11001111b               ; [granularity][32 bit size bit][reserved][no use][limit][limit][limit][limit]
  db  0                       ; base
gdt_data:
  dw  0xFFFF
  dw  0
  db  0
  db  10010010b
  db  11001111b               ; [present][privilege level][privilege level][data segment][data segment][expand direction][writeable][access]
  db  0
gdt_end:

gdt_descriptor:
  dw  gdt_end - gdt_start     ; size of GDT
  dd  gdt_start               ; location of GDT's start point

load_GDT:
cli
lgdt [gdt_descriptor]         ; actual function that loads GDT
mov eax, cr0                  ; make CR0 writable - move it to eax
or eax, 1                     ; switch CR0 flag to 1 - enter 32 bits mode
mov cr0, eax                  ; move it back to CR0
ret

Main:
cli
mov ax, 07c0h
push ax
add ax, 20h
mov ss, ax
