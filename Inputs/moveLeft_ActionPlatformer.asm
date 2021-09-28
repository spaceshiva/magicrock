;;;; 
    STX temp ;; assumes the object we want to move is in x.
    GetActionStep temp

    CMP #$07 ;; hurt
    BEQ +skipMovingLeft
    
    CMP #$03 ;; the state of your shoot animation
    BEQ +skipMovingLeft

    CMP #06 ;; recoiled
    BEQ +skipMovingLeft

    StartMoving temp, #LEFT
    STX temp ;; assumes the object we want to move is in x.
    ChangeFacingDirection temp, #FACE_LEFT

    +skipMovingLeft
        RTS