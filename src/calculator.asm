global _start
extern dbprint ; rdi *buf, rsi strlen
extern dberr ; rdi *buf, rsi strlen

; X11 functions
extern XOpenDisplay
extern XDefaultScreen
extern XBlackPixel
extern XWhitePixel
extern XDefaultRootWindow
extern XCreateSimpleWindow
extern XSelectInput
extern XMapWindow
extern XFlush

ButtonPressMask equ 1 << 2
StructureNotifyMask equ 1 << 17
EventMask equ ButtonPressMask | StructureNotifyMask

section .data
    dbprintcheck db "dbprint check passed",10
    dbprintcheck_len equ $ - dbprintcheck
    dberrcheck db "dberr check passed",10,10
    dberrcheck_len equ $ - dberrcheck
    displayconnerr db "Unable to connect to display",10
    displayconnerr_len equ $ - displayconnerr
    displayconn db "Display connected", 10
    displayconn_len equ $ - displayconn
    newline db 10

section .bss
    ; X11 setup
    screen_num resb 4
    width resb 4
    height resb 4
    background resb 8
    border resb 8
    win resb 8
    dpy resb 8

    ev resb 192 ; XEvent 

section .text
print: ; rdi *buf, rsi strlen
    mov rdx, rsi
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    ret

_start:
    ; align the stack :<
    and rsp, -16
    ; -DEBUG test dbprint functionality
    mov rdi, dbprintcheck
    mov rsi, dbprintcheck_len
    call dbprint
    ; -DEBUG test dberr functionality
    mov rdi, dberrcheck
    mov rsi, dberrcheck_len
    call dberr

    ; Connect to display server
    xor rdi, rdi
    call XOpenDisplay
    mov [dpy], rax

    cmp qword [dpy], 0
    jne displayconndone

    mov rdi, displayconnerr
    mov rsi, displayconnerr_len
    call dberr
    jmp exit

    displayconndone:

    mov rdi, displayconn
    mov rsi, displayconn_len
    call dbprint

    mov rdi, [dpy]
    call XDefaultScreen
    mov [screen_num], eax

    mov rdi, [dpy]
    mov rsi, [screen_num]
    call XBlackPixel
    mov [background], rax

    mov rdi, [dpy]
    mov esi, [screen_num]
    call XWhitePixel
    mov [border], rax 

    mov [width], 40
    mov [height], 40

    mov rdi, [dpy]
    call XDefaultRootWindow
    mov rsi, rax

    mov rdi, [dpy]
    xor rdx, rdx
    xor rcx, rcx
    mov r8d, [width]
    mov r9d, [height]

    ; stack magickery for other args of XCreateSimpleWindow
    sub rsp, 32
    mov qword [rsp], 2
    mov rax, [border]
    mov [rsp+8], rax
    mov rax, [background]
    mov [rsp+16], rax
    call XCreateSimpleWindow
    ; free up stack to conserve ram and save the earth
    add rsp, 32
    mov [win], rax 

    mov rdi, [dpy]
    mov rsi, [win]
    mov edx, EventMask
    call XSelectInput

    mov rdi, [dpy]
    mov rsi, [win]
    call XMapWindow

    mov rdi, [dpy]
    call XFlush

    label:
    jmp label

    exit:
    mov eax, 60
    xor rdi, rdi
    syscall