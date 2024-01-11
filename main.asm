.model small
.stack 256h
.data
    ;colored symbols
    FIELD_SYMBOL = 10DBh
    BLACK_SYMBOL = 00DBh
    WHITE_SYMBOL = 0FFDBh

    ORANGE_SYMBOL = 44DBh
    PURPLE_SYMBOL = 55DBh
    BLUE_SYMBOL = 33DBh
    GREEN_SYMBOL = 22DBh

    ;playing filed sizes
    TERMINAL_COLUMN_BYTES = 160
    PLAYING_FIELD_ROW_COUNT_BYTES = 21
    PLAYING_FIELD_COLUMN_COUNT_BYTES = 44

    PLAYING_FIELD_SIZE_BYTES =  PLAYING_FIELD_ROW_COUNT_BYTES * PLAYING_FIELD_COLUMN_COUNT_BYTES

    VIDEO_RAM = 0B800h

    ;keys
    RIGHT_KEY = 4dh
    LEFT_KEY = 4bh

    squareFigure        db 1, 1, 0, 0
                        db 1, 1, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    longFigure          db 2, 0, 0, 0
                        db 2, 0, 0, 0
                        db 2, 0, 0, 0
                        db 0, 0, 0, 0

    longRotated         db 2, 2, 2, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    lFigure             db 4, 0, 0, 0
                        db 4, 0, 0, 0
                        db 4, 4, 0, 0
                        db 0, 0, 0, 0

    lFigureRotation1    db 4, 4, 4, 0
                        db 0, 0, 4, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    lFigureRotation2    db 0, 0, 4, 0
                        db 4, 4, 4, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigure             db 0, 3, 0, 0
                        db 3, 3, 3, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigureRotation1    db 3, 0, 0, 0
                        db 3, 3, 0, 0
                        db 3, 0, 0, 0
                        db 0, 0, 0, 0

    tFigureRotation2    db 3, 3, 3, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigureRotation3    db 0, 3, 0, 0
                        db 3, 3, 0, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0

    playingField db PLAYING_FIELD_SIZE_BYTES dup(0)
    ; each figure has this attrs
    curFigureOffset dw offset lFigureRotation2

    curFigureWudth db 0
    curFigureHeight db 0
    curFigureRotationAmount db 0
    curFigureRotationId db 0

    xCoord db 0
    yCoord db 0
.code

pickColor proc ;is macross better?
    cmp al, 1
    je @@pickSquareColor

    cmp al, 2
    je @@pickLColor

    cmp al, 3
    je @@pickTColor

    cmp al, 4
    je @@pickLColor

    @@pickSquareColor:
        mov ax, ORANGE_SYMBOL
        jmp @@ret
    @@pickLongColor:
        mov ax, PURPLE_SYMBOL
        jmp @@ret

    @@pickTColor:
        mov ax, GREEN_SYMBOL
        jmp @@ret
        
    @@pickLColor:
        mov ax, BLUE_SYMBOL
        jmp @@ret

@@ret:
    ret
pickColor endp

; prepare BX Before call
fillEmptyRow proc
    mov ax, BLACK_SYMBOL ; 20 space 10 color

    @@empty:
        stosw ; ax -> es[di]
        dec bx
        jnz @@empty
ret
fillEmptyRow endp

initPlayingField proc 
    ;init data segments
    mov ax, ds
    mov es, ax
    mov di, offset playingField
    
    mov bl, 0
    @@row:
        mov ax, WHITE_SYMBOL ; write border
        stosw

        mov ax, FIELD_SYMBOL
        mov cx, (PLAYING_FIELD_COLUMN_COUNT_BYTES - 4) / 2
        rep stosw

        mov ax, WHITE_SYMBOL ; write border
        stosw

        inc bl
        cmp bl, PLAYING_FIELD_ROW_COUNT_BYTES - 1
        jl @@row

    mov ax, WHITE_SYMBOL ; write border
    mov cx, PLAYING_FIELD_COLUMN_COUNT_BYTES / 2
    rep stosw
ret
initPlayingField endp

drawPlayingField proc
    mov bx, VIDEO_RAM
    mov es, bx
    mov di, TERMINAL_COLUMN_BYTES

    mov si, offset playingField ;start figure position on playing field
    mov bl, 0
    @@row:
    mov cx, PLAYING_FIELD_COLUMN_COUNT_BYTES / 2

    @@col:
    lodsw
    stosw
    loop @@col

    sub di, PLAYING_FIELD_COLUMN_COUNT_BYTES
    add di, TERMINAL_COLUMN_BYTES

    inc bl
    cmp bl, PLAYING_FIELD_ROW_COUNT_BYTES
    jl @@row
    
    ret
drawPlayingField endp

inplaceCurrentFigure proc
    mov ax, ds
    mov es, ax

    mov di, offset playingField ;start position
    mov si, [curFigureOffset]

    mov al, [yCoord]
    mov bl, PLAYING_FIELD_COLUMN_COUNT_BYTES
    mul bl
    add di, ax

    xor ax, ax
    mov al, [xCoord]
    add di, ax

    mov bl, 0
    @@row:
    add di, 2

    mov cx, 4
    @@col:
    lodsb
    cmp al, 0
    je @@skip

    call pickColor
    stosw
    stosw
    jmp @@nextTick

    @@skip:
        add di, 4

    @@nextTick:
    loop @@col

    sub di, 16 + 2 ;figure + border
    add di, PLAYING_FIELD_COLUMN_COUNT_BYTES

    inc bl
    cmp bl, 4
    jl @@row
ret
inplaceCurrentFigure endp

removeCurrFigure proc
    mov ax, ds
    mov es, ax

    mov di, offset playingField ;start position
    mov si, [curFigureOffset]

    mov al, [yCoord]
    mov bl, PLAYING_FIELD_COLUMN_COUNT_BYTES
    mul bl
    add di, ax

    xor ax, ax
    mov al, [xCoord]
    add di, ax

    mov bl, 0
    @@row:
    add di, 2

    mov cx, 4
    @@col:
    lodsb
    cmp al, 0
    je @@skip

    mov ax, FIELD_SYMBOL
    stosw
    stosw
    jmp @@nextTick

    @@skip:
        add di, 4

    @@nextTick:
    loop @@col

    sub di, 16 + 2 ;figure + border
    add di, PLAYING_FIELD_COLUMN_COUNT_BYTES

    inc bl
    cmp bl, 4
    jl @@row
ret
removeCurrFigure endp

sleep proc
    push cx
    mov cx, 0Fh
    mov dx, 4240h
    mov ah, 86h
    int 15h
    ret
sleep endp

handleKey proc
jmp @@startHandleKey

@@handleRight:
    mov al, [xCoord]
    mov ah, PLAYING_FIELD_COLUMN_COUNT_BYTES + 1
    sub ah, [curFigureWudth]

    cmp al, ah
    jae @@clearBuffer

    add al, 4
    mov [xCoord], al
    jmp @@clearBuffer

@@handleLeft:
    mov al, [xCoord]
    cmp al, 0
    je @@clearBuffer

    sub al, 4
    mov [xCoord], al
    jmp @@clearBuffer

@@clearBuffer:
    mov ah, 0h ; read from buffer
    int 16h

    mov ah, 1h ; mov ah -> scan code, al -> asci
    int 16h
    jnz @@clearBuffer ; check zero flag

    jmp @@ret

@@startHandleKey:
    mov ah, 1h ; mov ah -> scan code, al -> asci
    int 16h
    jz @@ret ; check zero flag

    cmp ah, RIGHT_KEY
    je @@handleRight

    cmp ah, LEFT_KEY
    je @@handleLeft

    @@ret:
        ret
handleKey endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

main: 
    mov ax, @data
    mov ds, ax

    call initPlayingField

    mov cx, 12
    @@cycle:
    push cx
    call inplaceCurrentFigure
    call drawPlayingField
    call removeCurrFigure
    call sleep
    call handleKey
    pop cx

    mov al, [yCoord]
    inc al
    mov [yCoord], al
    loop @@cycle

    @@exit: 
        call exit
end main