; assfetch - Fully Dynamic x86_64 Assembly Fetch
; Created by Rootly
; Сборка: nasm -f elf64 fetch.asm -o fetch.o && ld fetch.o -o fetch

default rel

section .data
    c_org   db 27, '[38;5;208m', 0
    c_yel   db 27, '[38;5;214m', 0
    c_grn   db 27, '[38;5;142m', 0
    c_cre   db 27, '[38;5;223m', 0
    reset   db 27, '[0m', 0
    dots    db 27, '[48;5;142m  ', 27, '[48;5;214m  ', 27, '[48;5;208m  ', 27, '[0m', 10, 0

    l1 db "    .--.     ", 0
    l2 db "   |o_o |    ", 0
    l3 db "   |:_/ |    ", 0
    l4 db "  //   \ \   ", 0
    l5 db " (|     | )  ", 0
    l6 db "/'\_   _/`\\ ", 0
    l7 db "\___)=(___/  ", 0

    art_ptr dq l1, l2, l3, l4, l5, l6, l7

    p_at    db "@", 0
    p_os    db "os  : ", 0
    p_ker   db "ker : ", 0
    p_cpu   db "cpu : ", 0
    p_up    db "up  : ", 0
    p_mem   db "mem : ", 0
    p_sh    db "sh  : ", 0
    m_min   db " min", 0
    m_mib   db " MiB", 0
    m_sep   db " / ", 0
    unk     db "unknown", 0

    OS_PATH  db "/etc/os-release", 0
    CPU_PATH db "/proc/cpuinfo", 0
    U_VAR    db "USER", 0
    S_VAR    db "SHELL", 0
    NL       db 10, 0

section .bss
    u_buf   resb 1024
    si_buf  resb 128
    e_user  resb 64
    e_sh    resb 64
    o_name  resb 128
    c_name  resb 128
    up_str  resb 32
    m_used  resb 32
    m_total resb 32
    n_buf   resb 32
    tmp_buf resb 4096

section .text
    global _start

_start:
    mov rbp, [rsp]
    lea rsi, [rsp + 8 + rbp*8 + 8]

    push rsi
    mov rdx, U_VAR
    lea rdi, [e_user]
    call get_env
    pop rsi
    mov rdx, S_VAR
    lea rdi, [e_sh]
    call get_env

    mov rax, 63
    lea rdi, [u_buf]
    syscall

    mov rax, 99
    lea rdi, [si_buf]
    syscall

    call parse_os
    call parse_cpu
    
    mov rax, [si_buf]
    xor rdx, rdx
    mov rbx, 60
    div rbx
    call itoa
    lea rdi, [up_str]
    call copy_s
    lea rsi, [m_min]
    call copy_s
    
    call calc_mem

    xor r12, r12
.loop:
    lea rsi, [c_org]
    call pr
    
    cmp r12, 7
    jl .print_art
    lea rsi, [.blank_art]
    call pr
    jmp .align_done

.print_art:
    mov rbx, [art_ptr + r12*8]
    mov rsi, rbx
    call pr
    
    mov rsi, rbx
    xor rdx, rdx
.len:
    cmp byte [rsi+rdx], 0
    je .align
    inc rdx
    jmp .len
.align:
    mov rcx, 22
    sub rcx, rdx
    jle .info
.spc:
    push rcx
    mov rax, 1
    mov rdi, 1
    lea rsi, [.s_char]
    mov rdx, 1
    syscall
    pop rcx
    loop .spc
.align_done:
    jmp .info

section .data
    .blank_art db "             ", 0
    .s_char    db " ", 0
section .text

.info:
    cmp r12, 0
    je .d_u
    cmp r12, 1
    je .d_o
    cmp r12, 2
    je .d_k
    cmp r12, 3
    je .d_cpu
    cmp r12, 4
    je .d_upt
    cmp r12, 5
    je .d_m
    cmp r12, 6
    je .d_sh
    cmp r12, 7
    je .d_d
    jmp .next

.d_u:
    lea rsi, [c_grn]
    call pr
    lea rsi, [e_user]
    call pr 
    lea rsi, [p_at]
    call pr
    lea rsi, [u_buf + 65]
    call pr
    jmp .next
.d_o:
    lea rsi, [c_grn]
    call pr
    lea rsi, [p_os]
    call pr 
    lea rsi, [reset]
    call pr
    lea rsi, [o_name]
    call pr
    jmp .next
.d_k:
    lea rsi, [c_cre]
    call pr
    lea rsi, [p_ker]
    call pr 
    lea rsi, [reset]
    call pr
    lea rsi, [u_buf + 130]
    call pr
    jmp .next
.d_cpu:
    lea rsi, [c_grn]
    call pr
    lea rsi, [p_cpu]
    call pr
    lea rsi, [reset]
    call pr
    lea rsi, [c_name]
    call pr
    jmp .next
.d_upt:
    lea rsi, [c_cre]
    call pr
    lea rsi, [p_up]
    call pr 
    lea rsi, [reset]
    call pr
    lea rsi, [up_str]
    call pr
    jmp .next
.d_m:
    lea rsi, [c_grn]
    call pr
    lea rsi, [p_mem]
    call pr 
    lea rsi, [reset]
    call pr
    lea rsi, [m_used]
    call pr
    lea rsi, [m_sep]
    call pr
    lea rsi, [m_total]
    call pr
    lea rsi, [m_mib]
    call pr
    jmp .next
.d_sh:
    lea rsi, [c_cre]
    call pr
    lea rsi, [p_sh]
    call pr 
    lea rsi, [reset]
    call pr
    lea rsi, [e_sh]
    call pr
    jmp .next
.d_d:
    lea rsi, [dots]
    call pr
    jmp .exit

.next:
    lea rsi, [NL]
    call pr
    inc r12
    cmp r12, 8
    jl .loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; --- Utils ---

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
    mov rax, [si_buf + 32]
    sub rax, [si_buf + 40]
    xor rdx, rdx
    mov ebx, [si_buf + 104]
    mul rbx
    mov rbx, 1048576
    div rbx
    call itoa
    lea rdi, [m_used]
    call copy_s
    mov rax, [si_buf + 32]
    xor rdx, rdx
    mov ebx, [si_buf + 104]
    mul rbx
    mov rbx, 1048576
    div rbx
    call itoa
    lea rdi, [m_total]
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
    cmp ah, 0
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
    lea rdi, [OS_PATH]
    mov rsi, 0
    syscall
    test rax, rax
    js .err
    mov rdi, rax
    mov rax, 0
    lea rsi, [tmp_buf]
    mov rdx, 1024
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp_buf]
.find:
    cmp byte [rsi], 0
    je .err
    cmp dword [rsi], 'PRET'
    je .found
    inc rsi
    jmp .find
.found:
.skip:
    cmp byte [rsi], '='
    je .start
    inc rsi
    jmp .skip
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
    cmp al, 0
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
    lea rdi, [CPU_PATH]
    mov rsi, 0
    syscall
    test rax, rax
    js .err
    mov rdi, rax
    mov rax, 0
    lea rsi, [tmp_buf]
    mov rdx, 4096
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp_buf]
.find:
    cmp byte [rsi], 0
    je .err
    cmp dword [rsi], 'mode'
    je .found
    inc rsi
    jmp .find
.found:
.skip:
    cmp byte [rsi], ':'
    je .start
    inc rsi
    jmp .skip
.start:
    add rsi, 2
    lea rdi, [c_name]
.cl:
    lodsb
    cmp al, 10
    je .done
    cmp al, 0
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