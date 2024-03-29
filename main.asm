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
    YELLOW_SYMBOL = 66DBh

    ;playing filed sizes
    TERMINAL_COLUMN_BYTES = 160
    PLAYING_FIELD_ROW_COUNT_BYTES = 21
    PLAYING_FIELD_COLUMN_COUNT_BYTES = 44

    PLAYING_FIELD_SIZE_BYTES =  PLAYING_FIELD_ROW_COUNT_BYTES * PLAYING_FIELD_COLUMN_COUNT_BYTES

    VIDEO_RAM = 0B800h

    ;keys
    RIGHT_KEY = 4dh
    LEFT_KEY = 4bh
    ENTER_KEY = 1ch
    SPACE_KEY = 39h
    FIGURE_AMOUNT = 5

    FIGURE_SIZE_BYTES = 16
    
    ; square 1
    squareFigure        db 1, 1, 0, 0
                        db 1, 1, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    ; long 2
    longFigure          db 2, 0, 0, 0
                        db 2, 0, 0, 0
                        db 2, 0, 0, 0
                        db 2, 0, 0, 0

    longFigure1         db 2, 2, 2, 2
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    longFigure2         db 0, 0, 0, 2
                        db 0, 0, 0, 2
                        db 0, 0, 0, 2
                        db 0, 0, 0, 2

    longFigure3         db 0, 0, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0
                        db 2, 2, 2, 2                    

    ; l figure 4
    lFigure             db 4, 0, 0, 0
                        db 4, 0, 0, 0
                        db 4, 4, 0, 0
                        db 0, 0, 0, 0

    lFigure1            db 4, 4, 4, 0
                        db 4, 0, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    lFigure2            db 4, 4, 0, 0
                        db 0, 4, 0, 0
                        db 0, 4, 0, 0
                        db 0, 0, 0, 0

    lFigure3            db 0, 0, 4, 0
                        db 4, 4, 4, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    ; t figure 4
    tFigure             db 0, 3, 0, 0
                        db 3, 3, 3, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigure1            db 3, 0, 0, 0
                        db 3, 3, 0, 0
                        db 3, 0, 0, 0
                        db 0, 0, 0, 0
    
    tFigure2            db 3, 3, 3, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0

    tFigure3            db 0, 3, 0, 0
                        db 3, 3, 0, 0
                        db 0, 3, 0, 0
                        db 0, 0, 0, 0

    ; Z figure
    zFigure             db 5, 0, 0, 0
                        db 5, 5, 0, 0
                        db 0, 5, 0, 0
                        db 0, 0, 0, 0

    ; Z figure 2
    zFigure1            db 0, 5, 5, 0
                        db 5, 5, 0, 0
                        db 0, 0, 0, 0
                        db 0, 0, 0, 0


    playingField db PLAYING_FIELD_SIZE_BYTES dup(0)
    currFigureBaseOffset dw 0
    currFigureOffset dw 0
    currFigureState db 0
    currFigureStateAmount db 0

    xCoord db 0
    yCoord db 0

    figureOffsetList dw offset squareFigure, offset longFigure, offset tFigure, offset lFigure, offset zFigure
    figureStatesAmount db 0, 3, 3, 3, 1
.code

pickColor proc ;is macross better?
    cmp al, 1
    je @@pickSquareColor

    cmp al, 2
    je @@pickLongColor

    cmp al, 3
    je @@pickTColor

    cmp al, 4
    je @@pickLColor

    cmp al, 5
    je @@pickZColor

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

    @@pickZColor:
        mov ax, YELLOW_SYMBOL
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
    mov di, 0

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
    mov si, [currFigureOffset]

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

; TODO: Избавиться от дублирования
removeCurrFigure proc
    mov ax, ds
    mov es, ax

    mov di, offset playingField ;start position
    mov si, [currFigureOffset]

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
    add al, 4
    mov [xCoord], al
    jmp @@clearBuffer

@@handleSpace:
    mov al, [currFigureState]
    mov ah, [currFigureStateAmount]

    cmp al, ah
    jne @@nextState

    mov al, 0
    jmp @@changeCurrFigure

    @@nextState:
    inc al

    @@changeCurrFigure:
    mov [currFigureState], al
    mov ah, FIGURE_SIZE_BYTES
    mul ah

    mov bx, [currFigureBaseOffset]
    add bx, ax

    mov [currFigureOffset], bx
    
    jmp @@clearBuffer

@@handleLeft:
    mov al, [xCoord]
    cmp al, 0
    je @@clearBuffer

    sub al, 4
    mov [xCoord], al
    jmp @@clearBuffer

@@handleEnter:
    call exit

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

    cmp ah, ENTER_KEY
    je @@handleEnter

    cmp ah, SPACE_KEY
    je @@handleSpace

    jmp @@clearBuffer

    @@ret:
        ret
handleKey endp

checkFinished proc
    mov di, offset playingField ;start position

    mov al, [yCoord]
    mov bl, PLAYING_FIELD_COLUMN_COUNT_BYTES
    mul bl
    add di, ax

    xor ax, ax
    mov al, [xCoord]
    add di, ax
    add di, 2 ;left

    mov si, [currFigureOffset]
    
    mov cx, 4
    @@row:

    mov bx, 0
    @@col:
    mov al, [si + bx]
    cmp al, 0
    je @@nextCol

    @@checkNextRow:
    mov ax, @data:[di + PLAYING_FIELD_COLUMN_COUNT_BYTES]
    cmp ax, FIELD_SYMBOL
    je @@nextCol

    cmp cx, 1 ;last row and under not empty field
    je prepareNewFigure

    mov al, [si + bx + 4] ; check next figure row
    cmp al, 0
    je prepareNewFigure

    @@nextCol:
    add di, 4

    inc bx
    cmp bx, 4
    jl @@col

    @@nextRow:
    add si, 4 ;next figure row

    sub di, 16 ;next figure row
    add di, PLAYING_FIELD_COLUMN_COUNT_BYTES
    loop @@row

    ret
checkFinished endp

exit proc
    mov ah, 4ch
    int 21h
    ret
exit endp

random proc
    mov ah, 00h
    int 1ah  

    mov ax, dx   
    xor dx, dx  

    mov cx, FIGURE_AMOUNT
    div cx
  
    mov ax, dx

    ret
random endp

pickRandomFigure proc
    call random

    mov bx, offset figureStatesAmount
    mov si, ax
    mov bl, [bx + si]
    mov [currFigureStateAmount], bl

    mov dl, 2
    mul dl
    
    mov bx, offset figureOffsetList
    add bx, ax

    mov dx, [currFigureOffset]
 
    mov ax, [bx]
    mov [currFigureOffset], ax
    mov [currFigureBaseOffset], ax

    ret
pickRandomFigure endp

main: 
    mov ax, @data
    mov ds, ax

    call initPlayingField

    prepareNewFigure:
    mov [xCoord], 0
    mov [yCoord], 0
    call pickRandomFigure

    @@cycle:
    call inplaceCurrentFigure
    call drawPlayingField
    call checkFinished
    call removeCurrFigure
    call sleep
    call handleKey

    mov al, [yCoord]
    inc al
    mov [yCoord], al
    jmp @@cycle

    @@exit: 
        call exit
end main
