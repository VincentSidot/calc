format ELF64 executable 3
entry start

; =============================== DEFINITIONS ===============================

define SYS_read 0
define SYS_write 1
; ...
define SYS_exit 60

define STDIN 0
define STDOUT 1
define STDERR 2


define BUFFER_LEN 1024
define OPSTACK_SIZE 256
define TOKEN_SIZE 256
define CALLSTACK_SIZE 64

define TOKEN_TYPE_NUMBER 0
define TOKEN_TYPE_OPERATOR 1


; ================================= MACROS ==================================


macro syscall number, arg1, arg2, arg3, arg4, arg5, arg6 {
    if number eq
        display "Warning: syscall number not provided"
    else
        mov rax, number
    end if
    if arg1 eq
    else
        mov rdi, arg1
    end if
    if arg2 eq
    else
        mov rsi, arg2
    end if
    if arg3 eq
    else
        mov rdx, arg3
    end if
    if arg4 eq
    else
        mov r10, arg4
    end if
    if arg5 eq
    else
        mov r8, arg5
    end if
    if arg6 eq
    else
        mov r9, arg6
    end if
    syscall
}

; Define a static string inside the data segment
;   string: the string to print
macro sstr name, [string] {
    common
    name db string, 0
    name#.len = $ - name
}

; Print a static string
;   string: the string to print
macro sprint name {
    write STDOUT, name, name#.len
}


; Write to a file descriptor
;   fd: the file descriptor
;   ptr: the pointer to the buffer
;   ptr.len: the length of the buffer
macro write fd, ptr, ptr.len {
    syscall SYS_write, fd, ptr, ptr.len
}

; Read from a file descriptor
;   fd: the file descriptor
;   ptr: the pointer to the buffer
;   ptr.len: the length of the buffer
macro read fd, ptr, ptr.len {
    syscall SYS_read, fd, ptr, ptr.len
}

; Exit the program
;   code: the exit code
macro exit code {
    if code eq
        mov rdi, 0
    else
        mov rdi, code
    end if
    syscall SYS_exit
}

; Compare two strings
;  str1: the first string
;  str2: the second string
; Note:
;  This macro sets the zero flag if the strings are equal
;  The strings must be null-terminated
macro strcmp str1, str2 {
    mov rcx, str1
    mov rdx, str2
    .loop:
        mov al, [rcx]
        cmp al, [rdx]
        jne .end
        test al, al
        jz .end
        inc rcx
        inc rdx
        jmp .loop
    .end:
    test al, al
}

; This macro skips whitespace characters
; ptr: the pointer to the string
; eof: the label to jump to if the string is empty (optional)
; Note:
;   This macro modifies the pointer to the next non-whitespace character
;   The macro sets the zero flag if the string is empty
;   The macro does not check for the null terminator
;   The macro modifies the r8 register
macro parse_whitespace ptr, eof {
    local .skip_whitespace
    .skip_whitespace:
        mov r8b, BYTE [ptr]; Load the character
        inc ptr; Increment the pointer
        check_whitespace r8b, .skip_whitespace, eof
}

; This macro checks if a character is a whitespace
; reg: the register to check
; next: the label to jump to if the character is a whitespace
; eof: the label to jump to if the character is the null terminator
macro check_whitespace reg, next, eof {
    cmp reg, ' '
    je next
    cmp reg, 10
    je next
    if eof eq
    else
        cmp reg, 0
        je eof
    end if
}

; scall is a part stack to store return address and qword values
; This stack is limitied to CALLSTACK_SIZE qword
macro op_setup_scall {
    mov r13, scall
}

macro op_push_scall value {
    cmp r13, scallEnd ; 2op to avoid scall_overflow
    je scall_overflow ; Worth it?
    mov [r13], value
    add r13, 8
}

macro op_pop_scall reg {
    sub r13, 8
    mov reg, [r13]
}

; Stack presentation
; 8      |  TOKEN_TYPE
; 16     |  TOKEN_VALUE
; 24     |  TOKEN_TYPE
; 32     |  TOKEN_VALUE
; ...

macro op_fetch_token rtype, rvalue {
    local .op_fetch_number
    pop rtype ; Get the token type
    cmp rtype, TOKEN_TYPE_NUMBER
    je .op_fetch_number
    cmp rtype, TOKEN_TYPE_OPERATOR
    jne bad_input
    pop rvalue ; Get the function pointer
    if rvalue eq rax
        op_push_scall rbx
    end if
    call rvalue ; Call the operation
    if rvalue eq rax
        op_pop_scall rbx
    end if
    .op_fetch_number:
    pop rvalue ; Get the number
}

macro op_setup_pop {
    pop rax; Get the return address
    op_push_scall rax; Push the return address
    ; add rsp, 8; Remove the dummy value
    op_fetch_token r10, rbx; Get the second operand
    op_fetch_token r9, rax; Get the first operand
}

macro op_setup_ret {
    push rax; Push the result
    op_pop_scall rax; Pop the return address
    push rax; Push the return address
    ret
}
; Code
segment readable executable

; Operations
; operand are from the stack
; return value is pushed to the stack

op_add:
    op_setup_pop
    add rax, rbx; Add the operands
    op_setup_ret
op_sub:
    op_setup_pop
    sub rax, rbx; Sub the operands
    op_setup_ret
op_mul:
    op_setup_pop
    mul rbx; Mul the operands
    op_setup_ret
op_div:
    op_setup_pop
    xor rdx, rdx; Clear rdx
    div rbx; Divide the operands
    op_setup_ret

; Convert a string to an integer
; Input:
;   ptr: the pointer to the string null terminated (rax)
;   rdi: the base of the integer
;   rsi: flag to indicate if a number as been found
; Return:
;   rax: the integer value
;   rdi: the pointer to the next character after the integer
atoi:
    mov r9, rdi ; save the base
    mov rdi, rax ; r9 hold the pointer to the string
    mov rsi, 0 ; no number found

    ; Clear used registers
    xor r8,r8 ; r8 = 0
    xor rax, rax; rax = 0

    ; trim starting whitespace
    parse_whitespace rdi, .end

    .parse_number:
        cmp r8b, '0' ; Check if the character is a digit
        jl .end ; If not, return 0
        cmp r8b, '9'
        jg .end

        mov rsi, 1; Set the number found flag
        
        ; Parse the integer
        sub r8b, '0'; Convert the character to a digit
        mul r9; Multiply rax by 10
        add rax, r8; Add the digit to rax 
        mov r8b, BYTE [rdi]; Load the next character
        inc rdi; Move to the next character
    jmp .parse_number; Continue parsing the number

    .end:
    dec rdi; Move back to the last character
    ; Note:
    ;   rdi points to the next character after the integer
    ;   rax contains the integer value
    ret

; Print an integer
; Input:
;   rax: the integer value
;   rdi: the base
putd:
    ; Iterate through the digits and push them on the stack
    mov rsi, rsp; Save the pointer to the stack
    ; Handle the special case of 0
    test rax, rax
    jnz .not_zero
    dec rsp
    mov byte [rsp], '0'
    jmp .print
    .not_zero:
        ; Fetch the last digit
        xor rdx, rdx; Clear rdx
        div rdi; rax = rax / rdi, rdx = rax % rdi
        add rdx, '0'; Convert the digit to ASCII
        dec rsp; Move the stack pointer
        mov byte [rsp], dl; Store the digit on the stack
        test rax, rax; Check if the quotient is zero
        jnz .not_zero; If not, continue with the next digit
    .print:
    ; Print the digits from the stack
        mov r8, rsi; r8 = pointer to the stack
        sub r8, rsp; r8 = number of digits
        write STDOUT, rsp, r8; Write the digits to the standard output
        add rsp, r8; Adjust the stack pointer
    ret


; Tokenize a string (parse until next whitespace)
;   ptr: the pointer to the string (rdi modified)
;   dst: the destination buffer (rdx)
;   dst_len: the length of the destination buffer (rcx)
;   return: the length of the token (rax)
extract_token:
    xor rax, rax
    parse_whitespace rdi, .eof

    ; Copy content of r8 to rdx
    .copy:
        check_whitespace r8b, .zero, .eof
        cmp r8b, '0'
        jl .non_digit
        cmp r8b, '9'; Check if the character is a digit
        jg .non_digit
        ; We are parsing a digit
        jmp .zero
    .non_digit:
        mov BYTE [rdx], r8b ; Copy the character to the destination buffer
        inc rdx ; Move to the next destination character
        cmp rdx, rcx ; Check if we reached the end of the buffer
        je .end ; If so, return
        inc rax ; Increment the length of the token
        inc rdi ; Move to the next character
        mov r8b, BYTE [rdi]; Load the next character
    .zero:
        dec rdi; Move back to the last character
    .eof:
        mov BYTE [rdx], 0
    .end:
    ret

; Pop tokens stack to stack
pop_tokens:
    pop rax; Save return address in rax
    ; r15 hold the operation stack size
    .jpop:
        xor r11, r11; Clear r11
        dec r15
        mov r11b, [op + r15]; Get the token type
        push QWORD [OPERATION_TABLE + 8 * r11]
        push TOKEN_TYPE_OPERATOR
    cmp r15, 0
    jg .jpop
    
    push rax; Push the return address
    ret ; Should not segfault (hopefully)

tokenize:
    ; r15 hold the operation stack size
    xor r15, r15; Clear r15.
    mov r14, rsp; Save the buffer pointer
    mov rax, buffer
    .iter:
        mov rdi, 10
        call atoi
        ; rdi is the pointer to the buffer
        ; we need to not modify rdi
        

        cmp rsi, 0
        je .token_found
        
        ; Push the token to the stack
        push rax
        push TOKEN_TYPE_NUMBER


        jmp .trailing_iter
    .token_found:
        mov rdx, token
        mov rcx, TOKEN_SIZE
        call extract_token
        ; If the token size is not 1, it's not a valid operator
        cmp rax, 1
        jne bad_input

        ; Check if the token is an operator
        movzx rax, BYTE [token]
        cmp rax, 47
        jg .junkown
        sub rax, 42
        jc .junkown; Invalid operator less than 42
        jmp QWORD [.jtable + rax * 8]; Jump to the operator
        ; rax*8 is the index of the operator in the table qword
        .jtable: ; Table of operators (42-47)
            dq .jmul; 42
            dq .jadd; 43
            dq .junkown; 44
            dq .jsub; 45
            dq .junkown; 46
            dq .jdiv; 47

        .jadd:
            mov r13b, [OP_ADD_KIND]
            jmp .jcheckpop
        .jsub:
            mov r13b, [OP_SUB_KIND]
            jmp .jcheckpop
        .jmul:
            mov r13b, [OP_MUL_KIND]
            jmp .jend
        .jdiv:
            mov r13b, [OP_DIV_KIND]
            jmp .jend
        .junkown:
            jmp unknown_token
        .jcheckpop:
            ; Check if op stack is empty
            cmp r15, 0
            je .jend ; No operator just push
            movzx r11, BYTE [op + r15 - 1]; Get the last operator
            movzx r12, BYTE [OP_SUB_KIND]
            cmp r11, r12
            jl .jend
            ; We need to pop all the operatos in the stack
            call pop_tokens
        .jend:
            inc r15
            mov [op + r15 - 1], r13b
            
    .trailing_iter:
        ; Check if we reached the end of the buffer
        mov r8b, [rdi]
        cmp r8b, 0
        je .stop_iter

        ; Prepare for the next iteration
        mov rax, rdi; Rax is ptr for atoi
        jmp .iter
    .stop_iter:
        ; Push trailing operators to the stack
        call pop_tokens
        ; We can make the calculation. We will use r15 as the value holder
        pop rax ; Get the first token
        cmp rax, TOKEN_TYPE_OPERATOR
        jne bad_input; The first token should be an operator
        pop rax ; Get the operator ptr
        op_setup_scall ; Setup the op return stack
        call rax ; Call the operator

        pop r10; Save the result to r10
        ret

stop:
    sprint t_goodbye
    exit 0
scall_overflow:
    mov rsp, r14 ; Reset the stack
    add rsp, 8; Remove the return address
    sprint t_scallOverflow
    jmp start
unknown_token:
    mov rsp, r14 ; Reset the stack
    add rsp, 8; Remove the return address
    sprint t_unknownToken
    jmp start
bad_input:
    mov rsp, r14 ; Reset the stack
    add rsp, 8; Remove the return address
    sprint t_badInput
    jmp start
no_input:
    sprint t_noInput
start:

    sprint t_input
    ; Let's read from stdin
    read STDIN, buffer, BUFFER_LEN
    cmp rax, 1
    jle no_input

    ; Add a null terminator
    mov [buffer + rax - 1], 0 ; Do not include the t_newline
    push rax; Save the length of the buffer

    ; Check if the user wants to stop
    strcmp buffer, s_stopchar
    je stop
    call tokenize ; r10 hold the result
    
    ; pop rax; Restore the length of the buffer
    sprint t_result_1
    pop rdx; Restore the length of the buffer
    write STDOUT, buffer
    sprint t_result_2

    mov rax, r10 ; rax hold the result
    mov rdi, 10 ; Base 10
    call putd
    sprint t_newline
jmp start

; Data

segment readable

define COLOR_RED 0x1b,0x5b,0x30,0x3b,0x33,0x31,0x6d
define COLOR_YELLOW 0x1b,0x5b,0x33,0x33,0x6d
define COLOR_GREEN 0x1b,0x5b,0x33,0x32,0x6d
define COLOR_RESET 0x1b,0x5b,0x30,0x6d
define RESET_PREV_LINE 0x1b,0x5b,0x31,0x41,0xd,0x1b,0x5b,0x4b

; SStrings
sstr t_input, "> "
sstr t_result_1, RESET_PREV_LINE, "> "
sstr t_result_2, " = ", COLOR_GREEN
sstr t_goodbye, COLOR_YELLOW, "Goodbye!", COLOR_RESET, 10
sstr t_noInput, "No input provided", 10
sstr t_unknownToken, COLOR_RED, "Unknown token", COLOR_RESET, 10
sstr t_badInput, COLOR_RED, "Bad input", COLOR_RESET, 10
sstr t_scallOverflow, COLOR_RED, "Operation stack overflow", COLOR_RESET, 10

sstr t_newline, COLOR_RESET, 10

; Strings
s_stopchar db "q", 0

; Operator kinds
OP_ADD_KIND db 0
OP_SUB_KIND db 1
OP_MUL_KIND db 2
OP_DIV_KIND db 3

; Operation table
OPERATION_TABLE:
    dq op_add; ADD
    dq op_sub; SUB
    dq op_mul; MUL
    dq op_div; DIV

segment readable writable

; Define
buffer rb BUFFER_LEN ; STDIN Read buffer
op rb OPSTACK_SIZE ; Operation stacks
token rb TOKEN_SIZE; Token parsing buffer
scall rq CALLSTACK_SIZE; Call stack
scallEnd: