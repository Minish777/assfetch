; assfetch v1.5 - fast sys info tool
; author: rootly
default rel

section .data
    ; gruvbox colors
    c_art db 27, '[38;5;208m', 0
    c_lbl db 27, '[38;5;142m', 0
    c_val db 27, '[38;5;223m', 0
    rs    db 27, '[0m', 0
    
    ; penguin art
    a1 db "    .--.     ", 0
    a2 db "   |o_o |    ", 0
    a3 db "   |:_/ |    ", 0
    a4 db "  //   \ \   ", 0
    a5 db " (|     | )  ", 0
    a6 db "/'\_   _/`\\ ", 0
    a7 db "\___)=(___/  ", 0
    art dq a1, a2, a3, a4, a5, a6, a7

    t_os  db "os  : ", 0
    t_ker db "ker : ", 0
    t_cpu db "cpu : ", 0
    t_up  db "up  : ", 0
    t_mem db "mem : ", 0
    t_sh  db "sh  : ", 0
    
    f_os  db "/etc/os-release", 0
    f_cpu db "/proc/cpuinfo", 0
    v_usr db "USER", 0
    v_sh  db "SHELL", 0
    unk   db "unknown", 0
    nl    db 10, 0
    sep   db " / ", 0
    mib   db " MiB", 0
    unit  db " min", 0

section .bss
    u_buf   resb 1024
    si_buf  resb 128
    e_usr   resb 64
    e_sh    resb 64
    o_name  resb 128
    c_name  resb 128
    m_used  resb 32
    m_tot   resb 32
    n_buf   resb 32
    tmp     resb 16384 ; large buffer for cpuinfo

section .text
    global _start

_start:
    ; fetch env
    mov rbp, [rsp]
    lea rsi, [rsp + 8 + rbp*8 + 8]
    push rsi
    mov rdx, v_usr
    lea rdi, [e_usr]
    call get_env
    pop rsi
    mov rdx, v_sh
    lea rdi, [e_sh]
    call get_env

    ; system calls
    mov rax, 63 ; uname
    lea rdi, [u_buf]
    syscall
    mov rax, 99 ; sysinfo
    lea rdi, [si_buf]
    syscall

    call parse_os
    call parse_cpu
    call calc_mem

    ; main loop
    xor r12, r12
.loop:
    lea rsi, [c_art]
    call pr
    mov rsi, [art + r12*8]
    call pr
    
    ; align info
    mov rcx, 18
.spc:
    push rcx
    mov rax, 1
    mov rdi, 1
    lea rsi, [.s]
    mov rdx, 1
    syscall
    pop rcx
    loop .spc

    ; render info lines
    cmp r12, 0
    je .i_u
    cmp r12, 1
    je .i_o
    cmp r12, 2
    je .i_k
    cmp r12, 3
    je .i_c
    cmp r12, 4
    je .i_p
    cmp r12, 5
    je .i_m
    cmp r12, 6
    je .i_s
    jmp .next

.i_u:
    lea rsi, [c_lbl]
    call pr
    lea rsi, [e_usr]
    call pr 
    mov rsi, .at
    call pr
    lea rsi, [u_buf + 65]
    call pr
    jmp .next
section .data
    .at db "@", 0
    .s  db " ", 0
section .text

.i_o:
    lea rsi, [c_lbl]
    call pr
    lea rsi, [t_os]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [o_name]
    call pr
    jmp .next
.i_k:
    lea rsi, [c_val]
    call pr
    lea rsi, [t_ker]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [u_buf + 130]
    call pr
    jmp .next
.i_c:
    lea rsi, [c_lbl]
    call pr
    lea rsi, [t_cpu]
    call pr
    lea rsi, [rs]
    call pr
    lea rsi, [c_name]
    call pr
    jmp .next
.i_p:
    lea rsi, [c_val]
    call pr
    lea rsi, [t_up]
    call pr 
    lea rsi, [rs]
    call pr
    mov rax, [si_buf]
    xor rdx, rdx
    mov rbx, 60
    div rbx
    call itoa
    call pr
    lea rsi, [unit]
    call pr
    jmp .next
.i_m:
    lea rsi, [c_lbl]
    call pr
    lea rsi, [t_mem]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [m_used]
    call pr
    lea rsi, [sep]
    call pr
    lea rsi, [m_tot]
    call pr
    lea rsi, [mib]
    call pr
    jmp .next
.i_s:
    lea rsi, [c_val]
    call pr
    lea rsi, [t_sh]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [e_sh]
    call pr

.next:
    lea rsi, [nl]
    call pr
    inc r12
    cmp r12, 7
    jl .loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; --- logic ---

pr:
    push rsi
    push rax
    push rdi
    push rdx
    xor rdx, rdx
.l:
    cmp byte [rsi+rdx], 0
    je .w
    inc rdx
    jmp .l
.w:
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    pop rdi
    pop rax
    pop rsi
    ret

itoa:
    lea rdi, [n_buf + 30]
    mov byte [rdi], 0
    mov rbx, 10
.l:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .l
    mov rsi, rdi
    ret

copy_s:
    lodsb
    stosb
    test al, al
    jnz copy_s
    dec rdi
    ret

calc_mem:
    ; memory math with overflow fix
    mov r8, [si_buf + 104] ; unit
    mov rax, [si_buf + 32] ; total
    sub rax, [si_buf + 40] ; free
    mul r8
    mov rbx, 1048576
    div rbx
    call itoa
    lea rdi, [m_used]
    call copy_s

    mov rax, [si_buf + 32]
    mul r8
    mov rbx, 1048576
    div rbx
    call itoa
    lea rdi, [m_tot]
    call copy_s
    ret

get_env:
.l:
    mov rcx, [rsi]
    test rcx, rcx
    jz .f
    mov rbx, rdx
    mov r9, rcx
.m:
    mov al, [r9]
    mov ah, [rbx]
    test ah, ah
    je .e
    cmp al, ah
    jne .n
    inc r9
    inc rbx
    jmp .m
.e:
    cmp byte [r9], '='
    jne .n
    inc r9
.c:
    mov al, [r9]
    mov [rdi], al
    inc r9
    inc rdi
    test al, al
    jnz .c
    ret
.n:
    add rsi, 8
    jmp .l
.f:
    lea rsi, [unk]
    call copy_s
    ret

parse_os:
    mov rax, 2
    lea rdi, [f_os]
    xor rsi, rsi
    syscall
    mov rdi, rax
    xor rax, rax
    lea rsi, [tmp]
    mov rdx, 2048
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp]
.f_p:
    cmp byte [rsi], 0
    je .err
    cmp dword [rsi], 'PRET'
    je .found
    inc rsi
    jmp .f_p
.found:
    cmp byte [rsi], '='
    je .start
    inc rsi
    jmp .found
.start:
    inc rsi
    cmp byte [rsi], '"'
    jne .copy
    inc rsi
.copy:
    lea rdi, [o_name]
.cl:
    lodsb
    cmp al, '"'
    je .done
    cmp al, 10
    je .done
    stosb
    jmp .cl
.done:
    mov byte [rdi], 0
    ret
.err:
    lea rsi, [unk]
    lea rdi, [o_name]
    call copy_s
    ret

parse_cpu:
    mov rax, 2
    lea rdi, [f_cpu]
    xor rsi, rsi
    syscall
    mov rdi, rax
    lea rsi, [tmp]
    mov rdx, 16384
    xor rax, rax
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp]
.find:
    cmp byte [rsi], 0
    je .err
    cmp dword [rsi], 'mode'
    jne .nxt
    cmp dword [rsi+4], 'l na'
    je .found
.nxt:
    inc rsi
    jmp .find
.found:
    cmp byte [rsi], ':'
    je .start
    inc rsi
    jmp .found
.start:
    add rsi, 2
    lea rdi, [c_name]
.cl:
    lodsb
    cmp al, 10
    je .done
    stosb
    jmp .cl
.done:
    mov byte [rdi], 0
    ret
.err:
    lea rsi, [unk]
    lea rdi, [c_name]
    call copy_s
    ret
