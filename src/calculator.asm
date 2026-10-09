default rel

global _start
; debug
extern dbprint ; rdi *buf, rsi strlen
extern dberr ; rdi *buf, rsi strlen

; stringutils
extern stringutilsstrlen

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
extern XDrawString
extern XLoadQueryFont
extern XSetFont
extern XTextWidth

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
        .label: resq 1
    endstruc

    buttons:
        ; x, y, w, h, type, id, label
        dd 5, 90, 50, 40, 0, "BK" ; backspace
        dq label_bk
        dd 60, 90, 50, 40, 0, "CE" ; clear entry
        dq label_ce
        dd 115, 90, 50, 40, 0, "C" ; clear
        dq label_c
        dd 170, 90, 50, 40, 0, "PM" ; ±
        dq label_pm
        dd 225, 90, 50, 40, 0, "SR" ; √
        dq label_sr

        dd 5, 135, 50, 40, 1, 7
        dq label_7
        dd 60, 135, 50, 40, 1, 8
        dq label_8
        dd 115, 135, 50, 40, 1, 9
        dq label_9
        dd 170, 135, 50, 40, 0, "DV" ; division
        dq label_dv
        dd 225, 135, 50, 40, 0, "MD" ; modulo
        dq label_md

        dd 5, 180, 50, 40, 1, 4
        dq label_4
        dd 60, 180, 50, 40, 1, 5
        dq label_5
        dd 115, 180, 50, 40, 1, 6
        dq label_6
        dd 170, 180, 50, 40, 0, "MT" ; multiplication
        dq label_mt
        dd 225, 180, 50, 40, 0, "RC" ; reciprocal
        dq label_rc

        dd 5, 225, 50, 40, 1, 1
        dq label_1
        dd 60, 225, 50, 40, 1, 2
        dq label_2
        dd 115, 225, 50, 40, 1, 3
        dq label_3
        dd 170, 225, 50, 40, 0, "SB" ; subtraction
        dq label_sb
        dd 225, 225, 50, 85, 0, "EQ" ; equals
        dq label_eq

        dd 5, 270, 105, 40, 1, 0
        dq label_0
        dd 115, 270, 50, 40, 1, "DC" ; decimal
        dq label_dc
        dd 170, 270, 50, 40, 0, "AD" ; addition
        dq label_ad


    buttonsTotal equ ($ - buttons) / Button_size

    buttonlabels:
        label_bk db "←", 0
        label_ce db "CE", 0
        label_c db "C", 0
        label_pm db "±", 0
        label_sr db "√", 0
        label_dv db "/", 0
        label_md db "%", 0
        label_mt db "*", 0
        label_rc db "1/x", 0
        label_sb db "-", 0
        label_eq db "=", 0
        label_dc db ".", 0
        label_ad db "+", 0
        label_0 db "0",0
        label_1 db "1",0
        label_2 db "2",0
        label_3 db "3",0
        label_4 db "4",0
        label_5 db "5",0
        label_6 db "6",0
        label_7 db "7",0
        label_8 db "8",0
        label_9 db "9",0

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

    font_struct resq 1

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

    ; mov rdi, [dpy]
    ; lea rsi, [font_name]
    ; call XLoadQueryFont

    ; test rax, rax
    ; jz exit

    ; mov [font_struct], rax

    ; mov rdi, [dpy]
    ; mov rsi, [gc]
    ; mov rax, [font_struct]
    ; mov rdx, [rax]
    ; call XSetFont

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

            mov rdi, rbx
            call DrawCenteredLabel

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

    DrawCenteredLabel: ; rdi *Button (struct)
        push rbx
        push r12
        sub rsp, 8

        mov rbx, rdi

        ; strlen
        mov rdi, [rbx + Button.label]
        call stringutilsstrlen
        mov r12d, eax

        mov rdx, 0x202020
        call ForegroundBoilerplate

        mov ecx, [rbx + Button.width]
        mov eax, r12d
        imul eax, 6
        sub ecx, eax
        sar ecx, 1
        add ecx, [rbx + Button.x]

        mov r8d, [rbx + Button.height]
        sar r8d, 1
        add r8d, [rbx + Button.y]
        add r8d, 5

        mov rdi, [dpy]
        mov rsi, [win]
        mov rdx, [gc]
        mov r9, [rbx + Button.label]

        mov [rsp], r12
        call XDrawString

        add rsp, 8
        pop r12
        pop rbx
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
        sub rsp, 8
        mov rdi, [dpy]
        mov rsi, [gc]
        call XSetForeground
        add rsp, 8
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