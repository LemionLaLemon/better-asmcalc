default rel

global _start
; debug
extern dbprint
extern dberr

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
extern XFillRectangle
extern XDrawString
extern XLoadQueryFont
extern XSetFont
extern XTextWidth
extern XDefaultVisual
extern XDefaultColormap
extern XInternAtom
extern XSetWMProtocols
extern XCloseDisplay

; Xft functions
extern XftFontOpenName
extern XftDrawCreate
extern XftColorAllocValue
extern XftTextExtentsUtf8
extern XftDrawStringUtf8

; input masks
KeyPressMask equ 1 << 0
ButtonPressMask equ 1 << 2
ExposureMask equ 1 << 15
EventMask equ KeyPressMask | ButtonPressMask | ExposureMask

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

    leftmouseprint db "LMB pressed",10,0
    leftmouseprint_len equ $ - leftmouseprint

    font_name db "Cantarell-12", 0

    wm_delete_name db "WM_DELETE_WINDOW", 0

    text_rgba: ; can you believe it's rrrrggggbbbbaaaa
        dw 0x2020
        dw 0x2020
        dw 0x2020
        dw 0xFFFF

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
        dd 5, 90, 50, 40, 0, "B" ; backspace
        dq label_bk
        dd 60, 90, 50, 40, 0, "E" ; clear entry
        dq label_ce
        dd 115, 90, 50, 40, 0, "C" ; clear
        dq label_c
        dd 170, 90, 50, 40, 0, "(" ; (
        dq label_lp
        dd 225, 90, 50, 40, 0, ")" ; )
        dq label_rp

        dd 5, 135, 50, 40, 1, "7"
        dq label_7
        dd 60, 135, 50, 40, 1, "8"
        dq label_8
        dd 115, 135, 50, 40, 1, "9"
        dq label_9
        dd 170, 135, 50, 40, 0, "/" ; division
        dq label_dv
        dd 225, 135, 50, 40, 0, "S" ; square root
        dq label_sr

        dd 5, 180, 50, 40, 1, "4"
        dq label_4
        dd 60, 180, 50, 40, 1, "5"
        dq label_5
        dd 115, 180, 50, 40, 1, "6"
        dq label_6
        dd 170, 180, 50, 40, 0, "*" ; multiplication
        dq label_mt
        dd 225, 180, 50, 40, 0, "R" ; reciprocal
        dq label_rc

        dd 5, 225, 50, 40, 1, "1"
        dq label_1
        dd 60, 225, 50, 40, 1, "2"
        dq label_2
        dd 115, 225, 50, 40, 1, "3"
        dq label_3
        dd 170, 225, 50, 40, 0, "-" ; subtraction
        dq label_sb
        dd 225, 225, 50, 85, 0, "=" ; equals
        dq label_eq

        dd 5, 270, 105, 40, 1, "0"
        dq label_0
        dd 115, 270, 50, 40, 1, "." ; decimal
        dq label_dc
        dd 170, 270, 50, 40, 0, "+" ; addition
        dq label_ad

    buttonsTotal equ ($ - buttons) / Button_size

    buttonlabels:
        label_bk db "←", 0
        label_ce db "CE", 0
        label_c db "C", 0
        label_lp db "(  ", 0
        label_rp db ")", 0
        label_dv db "÷", 0
        label_sr db "√", 0
        label_mt db "×", 0
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
    border resb 8
    win resb 8
    dpy resb 8
    wm_delete_atom resq 1

    ev resb 192 ; XEvent 

    gc resb 8

    font_struct resq 1

    xft_font resq 1
    xft_draw resq 1
    xft_color resb 16

    expression_cap equ 256
    expressionBuffer resb expression_cap
    expressionLength resq 1

section .text
_start:
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
    mov qword [rsp+16], 0xD9E4F1
    call XCreateSimpleWindow
    add rsp, 32 ; free up stack to conserve ram and save the earth :>
    mov [win], rax 

    mov rdi, [dpy]
    lea rsi, [wm_delete_name]
    xor edx, edx
    call XInternAtom
    mov [wm_delete_atom], rax

    mov rdi, [dpy]
    mov rsi, [win]
    lea rdx, [wm_delete_atom]
    mov ecx, 1
    call XSetWMProtocols

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

    mov rdi, [dpy]
    mov esi, [screen_num]
    lea rdx, [font_name]
    call XftFontOpenName

    test rax, rax
    jz exit
    mov [xft_font], rax

    mov rdi, [dpy]
    mov esi, [screen_num]
    call XDefaultVisual
    mov r12, rax

    mov rdi, [dpy]
    mov esi, [screen_num]
    call XDefaultColormap
    mov r13, rax

    mov rdi, [dpy]
    mov rsi, [win]
    mov rdx, r12
    mov rcx, r13
    call XftDrawCreate

    test rax, rax
    jz exit
    
    mov [xft_draw], rax

    mov rdi, [dpy]
    mov rsi, r12
    mov rdx, r13
    lea rcx, [text_rgba]
    lea r8, [xft_color]
    call XftColorAllocValue

    test eax, eax
    jz exit

    %define btn_w 50
    %define btn_h 40
    %define gap 5
    ; below must add up to btn_h
    %define btn_top 24
    %define btn_bottom 27

    ; Main program loop
    mainloop:
        mov rdi, [dpy]
        lea rsi, [ev]
        call XNextEvent

        ; Expose event
        cmp dword [ev], 12
        je onExpose

        ; Button press event
        cmp dword [ev], 4
        je onButtonPress

        ; Key press event
        cmp dword [ev], 2
        je onKeyPress

        cmp dword [ev], 33
        je onClientMessage

    jmp mainloop

    onClientMessage:
        mov rax, [ev + 56]
        cmp rax, [wm_delete_atom]
        je .closeWindow

        jmp mainloop

        .closeWindow:
            mov rdi, [dpy]
            call XCloseDisplay
            jmp exit

    onKeyPress:

    onButtonPress:
        struc Mouse
            .type resd 1
            .pad0 resb 60
            .x resd 1
            .y resd 1
            .xroot resd 1
            .yroot resd 1
            .state resd 1
            .button resd 1
        endstruc

        mov rdi, leftmouseprint
        mov rsi, leftmouseprint_len
        call dbprint

        ; left mouse
        mov eax, [ev + Mouse.button]
        cmp eax, 1
        jne .break

        mov edi, [ev + Mouse.x]
        mov esi, [ev + Mouse.y]

        ; for button in Buttons do
        ; if mouse.x >= button.x
        ; and mouse.x < button.x + button.width
        ; and mouse.y >= button.y
        ; and mouse.y < button.y + button.height
        lea rcx, buttons
        mov r12, buttonsTotal

        .ForEachButton:
            mov eax, [ev + Mouse.x]
            cmp eax, [rcx + Button.x]
            jl .skip

            mov edx, [rcx + Button.width]
            add edx, [rcx + Button.x]
            cmp eax, edx
            jge .skip

            mov eax, [ev + Mouse.y]
            cmp eax, [rcx + Button.y]
            jl .skip

            mov edx, [rcx + Button.height]
            add edx, [rcx + Button.y]
            cmp eax, edx
            jge .skip

            jmp .found

            .skip:
                add rcx, Button_size
                dec r12
                jnz .ForEachButton
            
            jmp .break

        .found:
            movzx edi, byte [rcx + Button.id]

            cmp dil, "B"
            ; je .backspace
            cmp dil, "E"
            ; je .clearEntry
            cmp dil, "C"
            ; je .clearAll
            cmp dil, "S"
            ; je .squareRoot
            cmp dil, "R"
            ; je .reciprocal
            cmp dil, '='
            ; je .evaluate

            call addToBuffer

            mov r12, rcx

            mov rdi, expressionBuffer
            mov rsi, expressionLength
            call dbprint

            jmp .break

        .break:
            jmp mainloop

    ; Add a character to the expression buffer
    ; @param rdi character to append
    addToBuffer:
        mov rcx, [expressionLength]

        cmp rcx, expression_cap - 1
        jae .full

        mov [expressionBuffer + rcx], dil
        inc rcx
        mov byte [expressionBuffer + rcx], 0
        mov [expressionLength], rcx

        .full:
            ret

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
            mov r8d, [rbx + Button.type]
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

    ; Draws a centered label on a button
    ; @param rdi *Button
    DrawCenteredLabel:
        push rbx
        push r12
        push r13
        sub rsp, 32

        mov rbx, rdi

        ; strlen
        mov rdi, [rbx + Button.label]
        call stringutilsstrlen
        mov r12d, eax

        ; center x
        mov rdi, [dpy]
        mov rsi, [xft_font]
        mov rdx, [rbx + Button.label]
        mov ecx, r12d
        lea r8, [rsp]
        call XftTextExtentsUtf8

        movzx eax, word [rsp]
        movsx edx, word [rsp + 4]

        mov r13d, [rbx + Button.width]
        sub r13d, eax
        sar r13d, 1
        sub r13d, edx
        add r13d, [rbx + Button.x]

        ; center y
        movsx eax, word [rsp + 2]
        movsx edx, word [rsp + 6]

        mov r8d, [rbx + Button.height]
        sub r8d, eax
        sar r8d, 1
        add r8d, edx
        add r8d, [rbx + Button.y]

        mov rdi, [xft_draw]
        lea rsi, [xft_color]
        mov rdx, [xft_font]
        mov ecx, r13d
        mov r9, [rbx + Button.label]

        mov [rsp], r12
        call XftDrawStringUtf8

        add rsp, 32
        pop r13
        pop r12
        pop rbx
        ret

    ; Draws a button somewhere
    ; @param rdi X Position
    ; @param rdi Y Position
    ; @param rdx Width
    ; @param rcx Height
    ; @param r8 Type (0 dark ｜1 light)
    DrawButton:
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
        mov rbp, r8

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

    ; Draws a rectangle
    ; @param rdi X position
    ; @param rsi Y position
    ; @param rdx Width
    ; @param rcx Height
    DrawRectangle:
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