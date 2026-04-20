; assfetch - x86_64 system info
; build: nasm -f elf64 fetch.asm -o fetch.o && ld fetch.o -o assfetch

default rel

section .data
    ; Gruvbox colors
    c1 db 27, '[38;5;208m', 0
    c2 db 27, '[38;5;142m', 0
    c3 db 27, '[38;5;223m', 0
    rs db 27, '[0m', 0
    
    ; Color blocks
    dots db 27, '[48;5;142m  ', 27, '[48;5;214m  ', 27, '[48;5;208m  ', 27, '[0m', 10, 0

    ; Penguin art
    a1 db "    .--.     ", 0
    a2 db "   |o_o |    ", 0
    a3 db "   |:_/ |    ", 0
    a4 db "  //   \ \   ", 0
    a5 db " (|     | )  ", 0
    a6 db "/'\_   _/`\\ ", 0
    a7 db "\___)=(___/  ", 0

    art dq a1, a2, a3, a4, a5, a6, a7

    t_at  db "@", 0
    t_os  db "os  : ", 0
    t_ker db "ker : ", 0
    t_cpu db "cpu : ", 0
    t_up  db "up  : ", 0
    t_mem db "mem : ", 0
    t_sh  db "sh  : ", 0
    u_min db " min", 0
    u_mib db " MiB", 0
    u_sep db " / ", 0
    unk   db "unknown", 0

    f_os  db "/etc/os-release", 0
    f_cpu db "/proc/cpuinfo", 0
    v_usr db "USER", 0
    v_sh  db "SHELL", 0
    nl    db 10, 0

section .bss
    u_buf   resb 1024
    si_buf  resb 128
    e_usr   resb 64
    e_sh    resb 64
    o_name  resb 128
    c_name  resb 128
    up_str  resb 32
    m_used  resb 32
    m_tot   resb 32
    n_buf   resb 32
    tmp     resb 4096

section .text
    global _start

_start:
    ; Environment
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

    ; Info gathering
    mov rax, 63
    lea rdi, [u_buf]
    syscall

    mov rax, 99
    lea rdi, [si_buf]
    syscall

    call parse_os
    call parse_cpu
    
    ; Uptime
    mov rax, [si_buf]
    xor rdx, rdx
    mov rbx, 60
    div rbx
    call itoa
    lea rdi, [up_str]
    call copy_s
    lea rsi, [u_min]
    call copy_s
    
    call calc_mem

    ; Draw loop
    xor r12, r12
.loop:
    lea rsi, [c1]
    call pr
    
    cmp r12, 7
    jl .p_art
    lea rsi, [.blank]
    call pr
    jmp .align
.p_art:
    mov rbx, [art + r12*8]
    mov rsi, rbx
    call pr
    
    mov rsi, rbx
    xor rdx, rdx
.len:
    cmp byte [rsi+rdx], 0
    je .pad
    inc rdx
    jmp .len
.pad:
    mov rcx, 18 ; Padding width
    sub rcx, rdx
    jle .info
.spc:
    push rcx
    mov rax, 1
    mov rdi, 1
    lea rsi, [.s]
    mov rdx, 1
    syscall
    pop rcx
    loop .spc
.align:
    jmp .info

section .data
    .blank db "             ", 0
    .s     db " ", 0
section .text

.info:
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
    cmp r12, 7
    je .i_d
    jmp .next

.i_u:
    lea rsi, [c2]
    call pr
    lea rsi, [e_usr]
    call pr 
    lea rsi, [t_at]
    call pr
    lea rsi, [u_buf + 65]
    call pr
    jmp .next
.i_o:
    lea rsi, [c2]
    call pr
    lea rsi, [t_os]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [o_name]
    call pr
    jmp .next
.i_k:
    lea rsi, [c3]
    call pr
    lea rsi, [t_ker]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [u_buf + 130]
    call pr
    jmp .next
.i_c:
    lea rsi, [c2]
    call pr
    lea rsi, [t_cpu]
    call pr
    lea rsi, [rs]
    call pr
    lea rsi, [c_name]
    call pr
    jmp .next
.i_p:
    lea rsi, [c3]
    call pr
    lea rsi, [t_up]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [up_str]
    call pr
    jmp .next
.i_m:
    lea rsi, [c2]
    call pr
    lea rsi, [t_mem]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [m_used]
    call pr
    lea rsi, [u_sep]
    call pr
    lea rsi, [m_tot]
    call pr
    lea rsi, [u_mib]
    call pr
    jmp .next
.i_s:
    lea rsi, [c3]
    call pr
    lea rsi, [t_sh]
    call pr 
    lea rsi, [rs]
    call pr
    lea rsi, [e_sh]
    call pr
    jmp .next
.i_d:
    lea rsi, [dots]
    call pr
    jmp .exit

.next:
    lea rsi, [nl]
    call pr
    inc r12
    cmp r12, 8
    jl .loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

; --- Functions ---

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
    lea rdi, [f_os]
    xor rsi, rsi
    syscall
    test rax, rax
    js .err
    mov rdi, rax
    xor rax, rax
    lea rsi, [tmp]
    mov rdx, 1024
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp]
.f_pretty:
    cmp byte [rsi], 0
    je .err
    cmp dword [rsi], 'PRET'
    je .found
    inc rsi
    jmp .f_pretty
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
    lea rdi, [f_cpu]
    xor rsi, rsi
    syscall
    test rax, rax
    js .err
    mov rdi, rax
    xor rax, rax
    lea rsi, [tmp]
    mov rdx, 4096
    syscall
    mov rax, 3
    syscall
    lea rsi, [tmp]
.f_model:
    cmp byte [rsi], 0
    je .err
    ; Ищем "model name"
    cmp dword [rsi], 'mode'
    jne .nxt
    cmp dword [rsi+4], 'l na'
    je .found
.nxt:
    inc rsi
    jmp .f_model
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
