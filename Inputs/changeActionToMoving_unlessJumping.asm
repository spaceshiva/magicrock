    STX temp ;; assumes the object we want to move is in x.
    GetActionStep temp

    CMP #$01 ;; walking
    BEQ +skipChangeToMove

    CMP #$07 ;; hurt
    BEQ +skipChangeToMove

    CMP #$02 ;; the state of your jump animation
    BEQ +skipChangeToMove
    
    CMP #$03 ;; the state of your shoot animation
    BEQ +skipChangeToMove

    ChangeActionStep temp, #$01 ;; assumes that "walk" is in action 1
        ;arg0 = what object?
        ;arg1 = what behavior?

    +skipChangeToMove
        RTS