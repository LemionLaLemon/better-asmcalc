global stringutilsitoa
global stringutilsatoi
global stringutilsstrlen

section .text
; Integer to ASCII
; @param rax 64 bit signed integer
; @param rdi buffer pointer
; @return rdi buffer pointer
; @return rax string length
stringutilsitoa: ; $RAX 64 bit signed literal input, $RDI buffer pointer, $RAX string length literal output
    mov r8, rdi      ; Save buffer pointer
    mov r9, 10       ; Divisor (64 bit)
    xor rcx, rcx     ; Digit counter

    test rax, rax
    jns .convert
    neg rax
    mov byte [r8], '-'
    inc r8

    .convert:
    .loop_div:
        xor rdx, rdx     ; Clear for div
        div r9           ; RAX = RAX / 10, RDX = remainder
        add dl, '0'      ; Convert remainder to ASCII
        push rdx         ; Push digit onto stack
        inc rcx          ; Increment counter
        test rax, rax
        jnz .loop_div

    .pop_digits:
        pop rax          ; Get digit from stack
        mov [r8], al     ; Move to buffer
        inc r8
        loop .pop_digits

        mov byte [r8], 0 ; Null terminate

        mov rax, r8      ; Get current end-of-string pointer
        sub rax, rdi     ; Subtract the original start pointer
        ret

; ASCII to Integer
; pray to all the gods we NEVER have to use atoi this function is so garbage it's unbelivable
; @param rax pointer
; @return rax 32 bit signed integer
stringutilsatoi:
    push rbx
    push r8
    push r9
    xor rcx, rcx ; rcx counter = 0
    mov edx, 1 ; rdx sign = 1
    xor r8, r8 ; result accumulator
    xor r9, r9 ; if a digit has been found
    .forEachNumber:
        mov bl, byte [rax+rcx] ; read rcx'th byte of rax
        cmp bl, 0x0 ; compare bl and null term
        je .done ; jump to done if true
        cmp bl, '-' ; compare bl and '-'
        je .negative ; jump to negative if true
        cmp bl, '+' ; compare bl and '+'
        je .skip ; jump to skip if true
        cmp bl, ' ' ; compare bl and ' '
        je .skip ; skip if true
        cmp bl, '0' ; compare bl and '0'
        jl .done ; finish if <0
        cmp bl, '9' ; compare bl and '9'
        jg .done ; finish if >9

        mov r9, 1 ; digit found

        sub bl, '0' ; ascii to int conversion
        movzx rbx, bl ; idk man
        imul r8, 10 ; multiply current result by 10
        add r8, rbx ; add new digit

    .skip:
        inc rcx ; increase counter
        jmp .forEachNumber ; jump to continue

    .negative: ;
        cmp r9, 1
        je .done
        neg edx ; makes edx negative
        inc rcx ; increase counter
        jmp .forEachNumber ; jump to continue

    .done:
        imul r8, rdx ; negative conversion
        mov eax, r8d ; shove result back in rax
        pop rbx
        pop r8
        pop r9
        ret

stringutilsstrlen: ; rdi *buf, rax return int
    xor rax, rax

    .strlenLoop:
        cmp byte [rdi + rax], 0
        je .done
        inc rax
        jmp .strlenLoop

    .done:
    ret
