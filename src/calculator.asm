default rel

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
extern XNextEvent
extern XStoreName
extern XCreateGC
extern XSetForeground
extern XSetWindowBackground
extern XFillRectangle
extern XClearWindow

; input masks
KeyPressMask equ 1 << 0
ButtonPressMask equ 1 << 2
ExposureMask equ 1 << 15
EventMask equ ButtonPressMask | ButtonPressMask | ExposureMask

section .data
    dbprintcheck db "dbprint check passed",10
    dbprintcheck_len equ $ - dbprintcheck
    dberrcheck db "dberr check passed",10,10
    dberrcheck_len equ $ - dberrcheck
    displayconnerr db "Unable to connect to display",10
    displayconnerr_len equ $ - displayconnerr
    displayconn db "Display connected", 10
    displayconn_len equ $ - displayconn
    windowtitle db "Calculator",0
    newline db 10

    struc Button
        .x: resd 1
        .y: resd 1
        .width: resd 1
        .height: resd 1
        .type: resd 1
        .id: resd 1
    endstruc

    buttons:
        ; x, y, w, h, type, id, label
        dd 5, 90, 50, 40, 0, "BK" ; backspace
        dd 60, 90, 50, 40, 0, "CE" ; clear entry
        dd 115, 90, 50, 40, 0, "C" ; clear
        dd 170, 90, 50, 40, 0, "PM" ; ±
        dd 225, 90, 50, 40, 0, "SR" ; √

        dd 5, 135, 50, 40, 1, 7
        dd 60, 135, 50, 40, 1, 8
        dd 115, 135, 50, 40, 1, 9
        dd 170, 135, 50, 40, 0, "DV" ; division
        dd 225, 135, 50, 40, 0, "MD" ; modulo

        dd 5, 180, 50, 40, 1, 4
        dd 60, 180, 50, 40, 1, 5
        dd 115, 180, 50, 40, 1, 6
        dd 170, 180, 50, 40, 0, "MT" ; multiplication
        dd 225, 180, 50, 40, 0, "RC" ; reciprocal

        dd 5, 225, 50, 40, 1, 1
        dd 60, 225, 50, 40, 1, 2
        dd 115, 225, 50, 40, 1, 3
        dd 170, 225, 50, 40, 0, "SB" ; subtraction
        dd 225, 225, 50, 85, 0, "EQ" ; equals

        dd 5, 270, 105, 40, 1, 0
        dd 115, 270, 50, 40, 1, "DC" ; decimal
        dd 170, 270, 50, 40, 0, "AD" ; addition


    buttonsTotal equ ($ - buttons) / Button_size

    buttonlabels:
        label_bk db "←", 0

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

    gc resb 8

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

    ; X setup
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
    mov esi, [screen_num]
    call XWhitePixel
    mov [border], rax 

    mov [width], dword 280
    mov [height], dword 315

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
    mov rdx, 0xD9E4F1
    call XSetWindowBackground
    mov [background], rax

    mov rdi, [dpy]
    mov rsi, [win]
    call XClearWindow

    mov rdi, [dpy]
    mov rsi, [win]
    mov edx, EventMask
    call XSelectInput

    mov rdi, [dpy]
    mov rsi, [win]
    mov rdx, windowtitle
    call XStoreName

    mov rdi, [dpy]
    mov rsi, [win]
    call XMapWindow

    ; Graphics context for FillSolid
    mov rdi, [dpy]
    mov rsi, [win]
    xor rdx, rdx
    xor rcx, rcx
    call XCreateGC
    mov [gc], rax

    %define btn_w 50
    %define btn_h 40
    %define gap 5
    ; below must add up to btn_h
    %define btn_top 24
    %define btn_bottom 27

    mainloop:
        mov rdi, [dpy]
        lea rsi, [ev]
        call XNextEvent

        cmp dword [ev], 12
        je onExpose

    jmp mainloop

    onExpose:
        call draw
        ;%macro Button 5
        ;    lea rdi, [%1]
        ;    lea rsi, [%2]
        ;    lea rdx, [%3]
        ;    lea rcx, [%4]
        ;    mov r9, %5
        ;    call DrawButton
        ;%endmacro
        
        push rbx
        push r12

        lea rbx, buttons
        mov r12, buttonsTotal

        .DrawButtonsLoop:
        mov edi, [rbx + Button.x]
        mov esi, [rbx + Button.y]
        mov rdx, [rbx + Button.width]
        mov rcx, [rbx + Button.height]
        mov r9d, [rbx + Button.type]
        call DrawButton

        add rbx, Button_size
        dec r12
        jnz .DrawButtonsLoop 

        pop r12
        pop rbx

        jmp mainloop

    draw: ; Result window
        %define border_radius 1
        %define margin 5
        %define resultborderwidth  2
        %define result_w 270
        %define result_h 80
        ; Border
        call SetForegroundGray4
        mov rdi, margin + border_radius
        mov rsi, margin
        mov rdx, result_w - border_radius * 2
        mov rcx, result_h
        call DrawRectangle

        mov rdi, margin
        mov rsi, margin + border_radius
        mov rdx, result_w
        mov rcx, result_h - border_radius * 2
        call DrawRectangle

        ; Top
        call SetForegroundGray1
        mov rdi, margin + resultborderwidth
        mov rsi, margin + resultborderwidth
        mov rdx, result_w - resultborderwidth * 2
        mov rcx, result_h / 2
        call DrawRectangle

        ; Bottom
        call SetForegroundWhite
        mov rdi, margin + resultborderwidth
        mov rsi, margin - resultborderwidth + result_h / 2
        mov rdx, result_w - resultborderwidth * 2
        mov rcx, result_h / 2
        call DrawRectangle
        ret

    DrawButton: ; rdi X, rsi Y, rdx, W, rcx, H, r8 Label (TODO), r9 Type (0 dark, 1 light)
        push rbp
        push rbx
        push r12
        push r13
        push r14
        push r15

        mov r12, rdi
        mov r13, rsi
        mov r14, rdx
        mov r15, rcx
        mov rbp, r9

        ; Border
        call SetForegroundGray4
        lea rdi, [r12 + 1]
        mov rsi, r13
        lea rdx, [r14 - 2]
        mov rcx, r15
        call DrawRectangle 

        mov rdi, r12
        lea rsi, [r13 + 1]
        mov rdx, r14
        lea rcx, [r15 - 2]
        call DrawRectangle 

        ; Top Gradient
        call .ColorSelectTop
        lea rdi, [r12 + 2]
        lea rsi, [r13 + 2]
        lea rdx, [r14 - 4]
        lea rcx, [r15 - 4]
        shr rcx, 1
        mov rbx, rcx
        call DrawRectangle

        ; Bottom Gradient
        call .ColorSelectBottom
        lea rdi, [r12 + 2]
        lea rsi, [r13 + rbx + 2]
        lea rdx, [r14 - 4]
        lea rcx, [r15 - 4]
        sub rcx, rbx
        call DrawRectangle

        pop r15
        pop r14
        pop r13
        pop r12
        pop rbx
        pop rbp
        ret

        .ColorSelectTop:
            test rbp, rbp
            jz .DarkTop

            call SetForegroundGray3
            ret

            .DarkTop:
            call SetForegroundGray6
            ret

        .ColorSelectBottom:
            test rbp, rbp
            jz .DarkBottom

            call SetForegroundGray2
            ret

            .DarkBottom:
            call SetForegroundGray5
            ret

    DrawRectangle: ; rdi X, rsi Y, rdx W, rcx H
        push rcx
        mov r9, rdx
        mov rcx, rdi
        mov r8, rsi
        mov rdi, [dpy]
        mov rsi, [win]
        mov rdx, [gc]
        call XFillRectangle
        add rsp, 8
        ret

    ForegroundBoilerplate:
        mov rdi, [dpy]
        mov rsi, [gc]
        call XSetForeground
        ret

    SetForegroundWhite:
        mov rdx, 0xFFFFFF
        jmp ForegroundBoilerplate

    SetForegroundGray1:
        mov rdx, 0xF4F9FD
        jmp ForegroundBoilerplate

    SetForegroundGray2: ; Button primary bottom
        mov rdx, 0xECF4FA
        jmp ForegroundBoilerplate

    SetForegroundGray3: ; Button primary top
        mov rdx, 0xF6FAFE
        jmp ForegroundBoilerplate

    SetForegroundGray4: ; Border
        mov rdx, 0x8797AA
        jmp ForegroundBoilerplate

    SetForegroundGray5: ; Button secondary bottom
        mov rdx, 0xD5E0EE
        jmp ForegroundBoilerplate

    SetForegroundGray6: ; Button secondary top
        mov rdx, 0xECF2F8
        jmp ForegroundBoilerplate

    exit:
    mov eax, 60
    xor rdi, rdi
    syscall