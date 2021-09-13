;; do handle physics.


	LDA Object_x_lo,x
	STA xHold_lo
	LDA Object_x_hi,x
	STA xHold_hi
	STA xPrev

	LDA Object_screen,x
	STA xHold_screen
	sta screenPrev
	
	LDA Object_y_lo,x
	STA yHold_lo
	LDA Object_y_hi,x
	STA yHold_hi
	STA yPrev
	
	; LDA currentNametable
	; AND #%00001111
	; STA xHold_screen
	
	; LDA currentNametable
	; LSR
	; LSR
	; LSR
	; LSR
	; STA yHold_screen
	
	
	
	
	
	LDA Object_status,x
	AND #%00000100
	BNE doHandlePhysics
	JMP skipPhysics
doHandlePhysics:

	LDA #$00
	STA collisionsToCheck ;; blank out collisions to check.
	
	;;; check to see if we are using aiming physics.
	;;; if we are using aim physics, Object_direction will have it's 3rd bit flipped. xxxxXxxx
	LDA Object_direction,x
	AND #%00001000
	BEQ useNormalDirectionalPhysics
		;; use aimed physics.
		;; Aimed physics doesn't need to update speed.
		
		LDA Object_h_speed_lo,x
		BPL AddHspeedToAimedX
			;; subtract h speed to aimed x
			LDA Object_h_speed_lo,x
			EOR #$FF
			STA temp
			
			LDA Object_x_lo,x
			sec
			sbc temp
			STA xHold_lo
			LDA Object_x_hi,x
			sbc Object_h_speed_hi,x
			STA xHold_hi
			JMP figureAimedVspeed
		AddHspeedToAimedX:
			LDA Object_x_lo,x
			CLC
			ADC Object_h_speed_lo,x
			STA xHold_lo
			LDA Object_x_hi,x
			ADC Object_h_speed_hi,x
			STA xHold_hi
		
		figureAimedVspeed:

		LDA Object_v_speed_lo,x
		BPL AddVSpeedToAimedY
			;; subtract v speed to aimed y
			LDA Object_v_speed_lo,x
			EOR #$FF
			STA temp
			LDA Object_y_lo,x
			clc
			adc temp
			STA yHold_lo
			LDA Object_y_hi,x
			adc Object_v_speed_hi,x
			STA yHold_hi
			JMP doneWithAimedV
		AddVSpeedToAimedY:
			LDA Object_y_lo,x
			sec
			sbc Object_v_speed_lo,x
			STA yHold_lo
			LDA Object_y_hi,x
			sbc Object_v_speed_hi,x
			STA yHold_hi
		doneWithAimedV:
		
		
		JMP skipPhysics ;; skips all the acc/dec stuff and goes right to movement based on speed
							;; which was figured out in the directional macro.
							
	useNormalDirectionalPhysics:
	;;; jump out to bank 1C to load in physics values.
	;SwitchBank #$1C
		
		LDY Object_type,x
		LDA ObjectMaxSpeed,y
		ASL
		ASL
		ASL
		ASL
		;AND #%00001111
		STA myMaxSpeed
		LDA ObjectMaxSpeed,y
		LSR
		LSR
		LSR
		LSR
		STA myMaxSpeed+1
		;;; now high max speed byte is the actual high byte of speed
		;;; low max speed byte is the low byte of speed
		LDA #$00
        STA myAcc+1
        LDA ObjectAccAmount,y
        STA myAcc
    
	
		LDA ObjectBboxLeft,y
		STA self_left
		CLC
		ADC ObjectWidth,y
		STA self_right
		SEC
		SBC self_left
		LSR
		STA self_center_x
		
		LDA ObjectBboxTop,y
		STA self_top
		CLC
		ADC ObjectHeight,y
		STA self_bottom
		SEC
		SBC self_top
		LSR
		STA self_center_y ;; self center in the vertical direction.


		

	
;	ReturnBank
	;;;; deal with acceleration / deceleration

	
	LDA Object_direction,x
	AND #%10000000
	BNE doHvel
	JMP doHdec
	doHvel:
	
		;; we have activated horizontal inertia for this object
		LDA Object_h_speed_lo,x
		CLC
		ADC myAcc
		STA Object_h_speed_lo,x
		STA temp
		LDA Object_h_speed_hi,x
		ADC myAcc+1
		STA Object_h_speed_hi,x
		STA temp1
		
		;;; now, evaluate against max speed.
		Compare16 temp1, temp, myMaxSpeed+1,myMaxSpeed
		+
		;;;; we have reached the max speed.
		LDA myMaxSpeed
		STA Object_h_speed_lo,x
		LDA myMaxSpeed+1
		STA Object_h_speed_hi,x
		
		JMP doneWithAccFetch
		++
		LDA temp
		STA Object_h_speed_lo,x
		LDA temp1
		STA Object_h_speed_hi,x
		
		doneWithAccFetch:
		JMP skipDoHdec
doHdec:
	LDA Object_h_speed_hi,x
	CLC
	ADC Object_h_speed_lo,x
	BEQ skipDoHdec
	
	LDA Object_h_speed_lo,x
	SEC
	SBC myAcc
	STA temp
	
	LDA Object_h_speed_hi,x
	SBC myAcc+1
	STA temp1
	BCC zeroHdec ;; if the result of the 16 bit compare is 
					;; less than zero, clamp the acc to zero.
					;; Otherwise, make it the stored values.
	
	LDA temp1
	STA Object_h_speed_hi,x
	LDA temp
	STA Object_h_speed_lo,x
	JMP skipDoHdec
	
zeroHdec:
	LDA #$00
	STA Object_h_speed_hi,x
	STA Object_h_speed_lo,x
	

skipDoHdec:


	LDA directionByte
	AND #%00001111
	STA directionByte

	LDA Object_h_speed_lo,x
	STA tempA
	LDA Object_h_speed_hi,x
	STA tempB
	

	LDA Object_direction,x
	AND #%01000000
	BNE isMovingRight
	;isMovingLeft
	
	
	;;; set to check points 0 and 3 (top left and bottom left.)
	LDA collisionsToCheck
	ORA #%00001111
	STA collisionsToCheck 
	
		LDA tempA
		CLC
		ADC tempB
		BNE hSpeedIsNotZero
			;; h speed is zero, which means no h direction
			LDA directionByte
			AND #%01111111
			STA directionByte
			JMP gotHmoveDirection
		hSpeedIsNotZero:

			LDA directionByte
			ORA #%10000000
			AND #%10111111 ;; "left"
			STA directionByte
	JMP gotHmoveDirection
isMovingRight:
	
		;;; set to check points 1 and 2 (top right and bottom right.)
	LDA collisionsToCheck
	ORA #%00001111
	STA collisionsToCheck 
		LDA tempA
		clc
		ADC tempB
		BNE hSpeedIsNotZero2
			;; h speed is zero, which means no h direction
			LDA directionByte
			AND #%01111111
			STA directionByte
			JMP gotHmoveDirection
		hSpeedIsNotZero2:
			LDA directionByte
			ORA #%11000000 ;; "right"
			STA directionByte
gotHmoveDirection:
	
	LDA directionByte
	AND #%01000000
	BNE doMoveRight
;;doMoveLeft:
	LDA Object_x_lo,x
	SEC
	SBC tempA
	STA xHold_lo
	LDA Object_x_hi,x
	SBC tempB
	STA xHold_hi
	LDA Object_screen,x
	;SBC #$00
	STA xHold_screen
	
	
	 LDA #BOUNDS_LEFT
    BNE doNonZeroBoundsLeftCheck
        LDA Object_x_lo,x
        SEC
        SBC tempA
        LDA Object_x_hi,x
        SBC tempB
        BEQ doLeftBounds
        BCC doLeftBounds
            JMP doneWithH
    
    doNonZeroBoundsLeftCheck:
        LDA Object_x_lo,x
        SEC
        SBC tempA
        LDA Object_x_hi,x
        SBC tempB
    ;;;;;;;;;;;;;;;;; check xHold_hi against left bounds.
    CMP #BOUNDS_LEFT
    BEQ doLeftBounds
    BCC doLeftBounds
        JMP doneWithH
    doLeftBounds
			LDA xPrev
			STA xHold_hi
			STA Object_x_hi,x
            LDA #$03
            STA screenUpdateByte
            JSR doHandleBounds
	
	

	JMP doneWithH
doMoveRight:
	;; update x position.
	
	LDA Object_x_lo,x
	clc
	adc tempA
	STA xHold_lo
	LDA Object_x_hi,x
	adc tempB
	STA xHold_hi
	LDA Object_screen,x
	;ADC #$00
	STA xHold_screen
	LDA xHold_hi
	clc
	ADC self_right 
	BCS +doRightBounds
		JMP doneWithH
	+doRightBounds:
	
		LDA #$01
		STA screenUpdateByte
		LDA xPrev
		STA xHold_hi
		STA Object_x_hi,x
		JSR doHandleBounds
		; jmp doneWithH
doneWithH:
	
	LDA Object_vulnerability,x
	AND #%00000001
	BEQ +skip
		;;; What should we do if vulnerability bit 0 is flipped?
		JMP doneWithGravity
	+skip
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; GRAVITY VALUES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Here, you can manipulate the constants for MAX_FALL_SPEED, GRAVITY_LO and GRAVITY_HI
;;;; to work with your game.  
;;;;; MAX_FALL_SPEED = the maximum speed a player can fall.  It is good to give this a max speed
;;;;; so the player doesn't begin falling so fast that he falls through blocks.
;;;;; GRAVITY_LO / HI = the low and high bytes for gravity.  The two bytes work sort of like 
;;;;; a minute and hour hand on a watch.  So if you thought about it like minutes and hours, if you put "1" in hi and "30" in low
;;;;; you would add an hour and a half every time that gravity was engaged.  If you put 1 in hi and 45 in low,
;;;;; it would add an hour and 45 minutes every time gravity was engaged (a little faster.
;;;;; ** NOTE, that is not literal, just a way to easily understand it.
;;;;; HI will likely be a low number...0-4, I would imagine.  Not much more.  Written #$xx.
;;;;; LO could be anything, #$00 - #$FF if you want to write in hex, or if you just want to write in regular
;;;;; decimal values, #x will work, any value between #0 and #255.  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Handle Gravity.
;;;;;;;;;;;;;;; Change these constants to change gravity's behavior.
MAX_FALL_SPEED = #$04
GRAVITY_LO = #$40
GRAVITY_HI = #$00



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LDA Object_x_hi,x
	CLC
	ADC self_left
	STA temp
		JSR getPointColTable
	LDA Object_x_hi,x
	CLC
	ADC self_right
	STA temp3 ;; the right bottom collision point.
	LDA Object_y_lo,x
	CLC 
	ADC Object_v_speed_lo,x
	LDA Object_y_hi,x
	ADC Object_v_speed_hi,x
	CLC
	ADC self_bottom
	STA temp1
	;;; CHECK FOR SOLID TILE, which is tile type 1 in this module.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;; In this module, we have
		;; 1 = solid
		;; 7 = one way platform
		;; 9 = prize block, which behaves as a solid
		;; 10 (0A) = ladder, whose top behaves like a solid.
		;; Here is where we handle the "landing" scenario for all of those possibilities.
		
		
	GetCollisionPoint temp, temp1, tempA ;; is it a solid?
		CMP #$01
		BNE +isNotSolid 
			JMP +isSolid
		+isNotSolid
		CMP #$07
		BNE +isNotOneWaySolid
			JMP +isOneWaySolid
		+isNotOneWaySolid
		CMP #$09
		BNE +isNotSolid
			JMP +isSolid
		+isNotSolid
		CMP #$0A
		BEQ +isLadderSolid
		
	GetCollisionPoint temp3, temp1, tempA ;; is it a solid?
		CMP #$01
		BNE +isNotSolid
			JMP +isSolid
		+isNotSolid
		CMP #$07
		BNE +isNotSolid
			JMP +isOneWaySolid
		+isNotSolid
		CMP #$09
		BNE +isNotSolid
			JMP +isSolid
		+isNotSolid
		CMP #$0A
		BEQ +isLadderSolid
			JMP +notSolid
			
	+isLadderSolid
		LDA Object_v_speed_hi,x
		BEQ +checkSolid
		BPL +checkSolid
			JMP +notSolid
		+checkSolid
		LDA temp1
		SEC
		SBC #$02
		SEC
		SBC Object_v_speed_hi,x
		STA tempy
		GetCollisionPoint temp, tempy, tempA ;; is it a solid
			BEQ +checkForSecondPoint
			CMP #$0A
			BEQ +notSolid
		GetCollisionPoint temp3, tempy, tempA ;; is it a solid?	
			BEQ +checkForFirstPoint
			CMP #$0A
			BEQ +notSolid
			JMP +isSolid
				+checkForSecondPoint
					GetCollisionPoint temp3, tempy, tempA ;; is it a solid?
					BEQ +isSolid
					JMP +notSolid
				+checkForFirstPoint
					GetCollisionPoint temp, tempy, tempA ;; is it a solid?
					BEQ +isSolid
					JMP +notSolid
					
					
	+isOneWaySolid
		;; a special kind of solid
		LDA Object_v_speed_hi,x
		BMI +notSolid ;; a jumpthrough platform is definitely not solid if moving up through it.
			;;; however, it is not solid if we haven't cleared it yet.
			TYA
			AND #%11110000
			CLC 
			ADC Object_v_speed_hi,x
			CMP temp1
			BEQ +isSolid
			BCS +isSolid
			JMP +notSolid
			
	+isSolid

		JMP isSolidSoLand
	
	
	
		+notSolid:
		
			;; is not solid, don't land.
			LDA Object_y_lo,x
			CLC
			ADC Object_v_speed_lo,x
			STA yHold_lo
			LDA Object_y_hi,x
			ADC Object_v_speed_hi,x
			STA Object_y_hi,x
			STA yHold_hi
			
			LDA Object_v_speed_lo,x
			CLC
			ADC #GRAVITY_LO
			STA Object_v_speed_lo,x
			LDA Object_v_speed_hi,x
			ADC #GRAVITY_HI
			STA Object_v_speed_hi,x
			
				LDA Object_v_speed_hi,x
				CMP #MAX_FALL_SPEED
				BNE notOverFallSpeed
					;; is at least max fall speed.
					LDA #$00
					STA Object_v_speed_lo,x
				notOverFallSpeed:
				
				
			
			JMP doneWithGravity
	
isSolidSoLand:
	;; move to position
	;;; load the top of the tile that is being run into.
	

		;; force y to tile boundary.	
		; LDA tileY
		; AND #%11110000
		; SEC
		; SBC self_bottom
		; SEC
		; SBC #$01
		; STA Object_y_hi,x
		; STA yHold_hi
		
		STX temp
		GetActionStep temp
		CMP #$07 ;; hurt
		BNE +notHurt
			JMP +continueLand
		+notHurt:
		CMP #$02 ;; we are jumping
		BEQ +inJumpStep
			JMP +continueLand
		
		+inJumpStep:
			; only checks gamepad #1
			LDA gamepad 
			AND #%11000000
			BNE +changeToWalk_Dpadpressed
				JMP +checkLandingDpadNotpressed
			; dpad is pressed, so we walk
			+changeToWalk_Dpadpressed:
				STX temp
				ChangeActionStep temp, #$01 ; change to walk
				JMP +continueLand

			+checkLandingDpadNotpressed:
				STX temp
				ChangeActionStep temp, #$00 ; change to idle
		
		+continueLand:
			LDA #$00
			STA Object_v_speed_lo,x
			STA Object_v_speed_hi,x
			
doneWithGravity:

skipPhysics: