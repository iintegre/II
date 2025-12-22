[org 0x7c00]

start:
    ; Clear screen / Set video mode 80x25
    mov ax, 0x0003
    int 0x10

    ; Print Splash in YELLOW (0x0E)
    mov si, msg_splash
    mov bl, 0x0E
    call print_string_color
    call print_newline

main_loop:
    ; Print prompt in WHITE (0x0F)
    mov si, msg_prompt
    mov bl, 0x0F
    call print_string_color

    ; Get user input
    mov di, buffer
    call get_input

    ; --- Command Logic ---
    mov si, buffer

    mov di, cmd_info
    call compare_strings
    je show_info

    mov si, buffer
    mov di, cmd_reboot
    call compare_strings
    je do_reboot

    mov si, buffer
    mov di, cmd_shutdown
    call compare_strings
    je do_shutdown

    jmp main_loop

show_info:
    mov si, msg_info
    mov bl, 0x0B      ; Cyan
    call print_string_color
    call print_newline
    jmp main_loop

do_reboot:
    jmp 0xFFFF:0x0000

do_shutdown:
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
    ; If QEMU specific port fails, try older APM
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    jmp main_loop

print_string_color:
    lodsb
    or al, al
    jz .done
    mov ah, 0x09      ; Write char + attribute
    mov bh, 0
    mov cx, 1
    int 0x10
    mov ah, 0x03      ; Get cursor
    int 0x10
    inc dl            ; Move cursor right
    mov ah, 0x02      ; Set cursor
    int 0x10
    jmp print_string_color
.done:
    ret

print_newline:
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    ret

get_input:
    xor cx, cx
.loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d
    je .enter_pressed
    cmp al, 0x08
    je .backspace_pressed
    cmp cx, 31          ; Buffer limit
    je .loop
    stosb
    inc cx
    mov ah, 0x0e
    int 0x10
    jmp .loop
.backspace_pressed:
    jcxz .loop
    dec cx
    dec di
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop
.enter_pressed:
    mov al, 0
    stosb
    call print_newline
    ret

compare_strings:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.not_equal:
    clc
    ret
.equal:
    stc
    ret

; --- Data ---
msg_splash   db 'II made by IINTEGRE', 0
msg_prompt   db '> ', 0
msg_info     db 'infos: Kernel II25, version "debug"', 0
cmd_info     db 'info', 0
cmd_reboot   db 'reboot', 0
cmd_shutdown db 'shutdown', 0
buffer       times 32 db 0

times 510-($-$$) db 0
dw 0xaa55
