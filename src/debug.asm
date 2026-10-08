global dbprint
global dberr

section .data
    ; ANSI colors
    blue db 27, "[34m" ; 27 escape char, 34m blue
    blue_len equ $ - blue
    red db 27, "[31m" ; 31m red
    red_len equ $ - red
    reset db 27, "[0m"
    reset_len equ $ - reset

section .text
print:
    mov rax, 1
    syscall
    ret

dbprint: ; rdi *buf, rsi strlen
    push rdi
    push rsi
    mov rsi, blue
    mov rdi, 1
    mov rdx, blue_len
    call print

    pop rsi
    pop rdi
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    call print

    mov rsi, reset
    mov rdi, 1
    mov rdx, reset_len
    call print
    ret

dberr: ; rdi *buf, rsi strlen
    push rdi
    push rsi
    mov rsi, red
    mov rdi, 1
    mov rdx, red_len
    call print

    pop rsi,
    pop rdi
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    call print

    mov rsi, reset
    mov rdi, 1
    mov rdx, reset_len
    call print
    ret
