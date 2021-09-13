;;;; 
    STX temp ;; assumes the object we want to move is in x.
    GetActionStep temp

    CMP #$07 ;; hurt
    BEQ +skipMovingRight
    
    CMP #$03 ;; the state of your shoot animation
    BEQ +skipMovingRight

    StartMoving temp, #RIGHT
    STX temp ;; assumes the object we want to move is in x.
    ChangeFacingDirection temp, #FACE_RIGHT
    
    +skipMovingRight
      RTS