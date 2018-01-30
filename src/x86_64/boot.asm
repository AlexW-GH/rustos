global start


section .text
bits 32
start:
    mov esp, stack_top ; stack pointer

    call check_multiboot
    call check_cpuid
    call check_long_mode
    ;print OK to VGA-textbuffer, 0x2f = White Letter / Green Background, 0x4b = 'K', 0x4f = 'O'
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

check_multiboot:
    ; magic number according to multiboot specification that is written to eax by the bootloader
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "1" ; Store error code 1 in al
    jmp error

; #see: https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushf
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "2"
    jmp error

; #see: https://wiki.osdev.org/Setting_Up_Long_Mode#x86_or_x86-64
check_long_mode:
    ; check if extended function is available
    mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .no_long_mode       ; It is less, there is no long mode.

    ; check if long mode is available
    mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz .no_long_mode        ; They aren't, there is no long mode.
    ret
.no_long_mode:
    mov al, "3"
    jmp error

; Prints `ERR: ` and the related error code to the VGA-textbuffer, halts the program
error:
    ; 0x4f = White Letter / Red Background
    ; 0x45 = 'E'
    ; 0x52 = 'R'
    ; 0x3a = ':'
    ; 0x20 = ' '
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20

    ; The error code, overrides the second space in the last statement
    mov byte  [0xb800a], al
    hlt

section .bss ; Basic Service Set
stack_bottom:
    resb 64 ; reserve 64 Byte
stack_top:




