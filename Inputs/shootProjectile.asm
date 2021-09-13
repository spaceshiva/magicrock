;;; Create a Projectile.
;;; Assumes that the projectile you want to create is in GameObject Slot 03.

	LDA bulletTimer
	BEQ +canShoot
		;; bullet timer not reset yet.
		;; we will decrease bullet timer in game timer scripts.
		;; and if it is zero, keep it at zero.
		RTS
	+canShoot

	STX temp 
	GetActionStep temp
	CMP #$07 ;; dead people won't shoot
    BNE +notHurt
        RTS
    +notHurt
	; TODO: when we get why the move script still moves the char if on shooting action, remove this conditional
	CMP #01 ;; walking
	BNE +notWalking
        RTS
    +notWalking ;; we can shoot
    CMP #$02 ;; assumes 2 is jump
    BNE +notJump
        RTS
    +notJump ;; we can shoot
	CMP #03 ;; shooting
	BNE +notShooting
        RTS
    +notShooting ;; we can shoot

    ;; change player action to "shooting"
    STX temp
	ChangeActionStep temp, #$03
	StopMoving temp, #$FF, #$00

	TXA
	PHA
    TYA
    PHA
	
	LDX player1_object
	LDA Object_screen,x
	STA tempD
	
	LDA Object_x_hi,x
	CLC
	ADC #$02
	STA tempA
	
	LDA Object_y_hi,x
	CLC
	ADC #$01
	STA tempB
	
	LDA Object_direction,x
	AND #%00000111
	STA tempC
	
	CreateObjectOnScreen tempA, tempB, #$03, #$00, tempD 
		;;; x, y, object, starting action.
		;;; and now with that object, copy the player's
		;;; direction and start it moving that way.
		LDA tempC
		STA Object_direction,x
		TAY
		LDA DirectionTableOrdered,y
		STA temp1
		TXA
		STA temp
		StartMoving temp, temp1
		
		LDA #$15
		STA bulletTimer

    PLA
    TAY
    PLA
    TAX
	
    
    RTS