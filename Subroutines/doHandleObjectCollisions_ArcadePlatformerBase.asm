	;;; object collions have to check from current index
	;;; through the rest of the objects on the field of play.
	;;; Objects prior to its index have already checked against this particular object
	SwitchBank #$1C
;;STEP 1: Check for inactivity.
	LDA Object_status,x
	AND #%10000000
	BNE +doCheckSelfForObjectCollision
		;; object is inactive.
		JMP +skipObjectCollisionCheck
	+doCheckSelfForObjectCollision:
;;STEP 2: Check for hurt state.
	;;; In this module, monsters will use action step 7 for their hurt state.
	TXA
	STA selfObject
	STA temp
	GetActionStep temp
	CMP #$07
	BNE +notHurt
		JMP +skipObjectCollisionCheck
	+notHurt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;STEP 3: Set up bounds for self collision.
	TXA
	PHA
	LDY Object_type,x
	LDA ObjectFlags,y
	STA tempA ;; temp A now holds the current object flags.
			;; collision box is still held over from the physics routine.
	LDA xHold_hi;Object_x_hi,x
	CLC
	ADC self_left
	STA bounds_left
	LDA xHold_hi;Object_x_hi,x
	CLC
	ADC self_right
	STA bounds_right
	
	LDA yHold_hi;Object_y_hi,x
	CLC
	ADC self_top
	STA bounds_top
	LDA yHold_hi;Object_y_hi,x
	CLC
	ADC self_bottom
	STA bounds_bottom
	
	LDA Object_screen,x
	STA self_screen
	STA self_screen_left
	STA self_screen_right
	
	TYA
	PHA
	;;; we probably want this to live inside bank 1C
	;;; so that we can access flag data easily with no RAM.
	;;;; Right now, in this module, it is there by default.
	;;;; If it is not, we will have to bankswap to 1c here.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Check the type of object.
;;; If it is a weapon, it will check against monsters only.
		LDA Object_flags,x
		AND #%00000100
		BNE +isWeapon
			JMP +notPlayerWeapon
		+isWeapon

				LDX #$00
				loop_objectCollision:
					CPX selfObject
						BNE +notSelfObject
							JMP +skipCollision
						+notSelfObject
				LDA Object_status,x
				AND #%10000000
				BNE +isActive
					JMP +skipCollision
				+isActive:
				LDA Object_flags,x
				AND #%00001000
				BNE isMonsterWeaponCol
					JMP +notAmonsterWeaponCollision
				isMonsterWeaponCol:
					JSR getOtherColBox
					JSR doCompareBoundingBoxes
						;;; if they have collided, it is a 1
						;;; if not, it is a zero.
						BEQ +skipCollision
							
							TXA
							STA otherObject
							;; There was a collision between a monster and a weapon.
							;; weapon is self.
							;; monster is other.
							; DestroyObject
							;ChangeActionStep otherObject, #$07
							;ReturnBank
								;SwitchBank #$18
								JSR doHandleHurtMonster
								ReturnBank
							LDX selfObject
							DestroyObject
							JMP +done				
					+skipCollision
				+notAmonsterWeaponCollision
				INX
				CPX #TOTAL_MAX_OBJECTS
				BEQ +lastCollisionForThisObject
					JMP loop_objectCollision
			+lastCollisionForThisObject
			JMP +done
			
			
		+notPlayerWeapon
			
			LDA Object_flags,x
			AND #%00000010
			BNE +isPlayerForCol
				;; not player for collions
					JMP +notPlayerForCollisions
			+isPlayerForCol
				;;; check against monsters.
					LDX #$00
					loop_objectPlayerCollisions:
						CPX selfObject
						BNE +notSelfObject
							JMP +skipCollision
						+notSelfObject
						LDA Object_status,x
						AND #%10000000
						BNE +isActive
							JMP +skipCollision
						+isActive
						LDA Object_flags,x
						AND #%00001000
						BNE +isPlayerMonsterCol
							JMP +notPlayerMonsterCollision
						+isPlayerMonsterCol
							
							JSR getOtherColBox
							JSR doCompareBoundingBoxes
								;;; if they have collided, it is a 1
								;;; if not, it is a zero.
								BNE +dontSkipCol
									JMP +skipCollision
								+dontSkipCol
									TXA
									STA otherObject
									;; There was a collision between a monster and a weapon.
									;; player is self.
									;; monster is other.
									;JMP RESET
									ReturnBank
									;SwitchBank #$18
										TXA
										PHA
										LDX selfObject
										JSR doHandleHurtPlayer
										PLA
										TAX
									;ReturnBank
									JMP +done
									
						+notPlayerMonsterCollision:
							LDA Object_flags,x
							AND #%00100000
							BNE +isPlayerPowerupCol
								JMP +isNotPlayerPowerupCol
							+isPlayerPowerupCol
								JSR getOtherColBox
								JSR doCompareBoundingBoxes
								BNE +doCollision
									JMP +skipCollision
								+doCollision
									TXA
									STA otherObject
									;; There was a collision between a player and a powerup.
									;; player is self.
									;; powerup is other.
									DestroyObject
									.include SCR_PICKUP_SCRIPTS
									JMP +done
						
						+isNotPlayerPowerupCol	
							LDA Object_flags,x
							AND #%10000000
							BNE +isPlayerNPCCol
								JMP +isNotPlayerNPCCol
							+isPlayerNPCCol
								;; stop moving the block since we don't know yet if we will need to move it
								StopMoving otherObject, #$FF, #$00

								;; check for collision elements
								JSR getOtherColBox
								JSR doCompareBoundingBoxes
								BNE +handleCollision
									JMP +skipCollision
								+handleCollision
									;LDA #%00000001
									STA colInfo ;; the result of the collision algorithm is loaded in A


									STX otherObject
									;; There was a collision between a player and a block.
									;; player is self.
									;; block is other.

									;; only handle jumping, if we landed above the block
									LDA colInfo
									AND #%00000010
									BNE +handleJumpLanding
										JMP +handleBlockMovement

									+handleJumpLanding
										;; TODO: 
										;; handles player landing in the block after a jump
										;; land player in the block head
										GetActionStep selfObject
										CMP #$02 ;; we are jumping
										BEQ +inJumpStep
											JMP +handleBlockMovement ;; not jumping, check if we need to move it
										+inJumpStep
											; only checks gamepad #1
											LDA gamepad 
											AND #%11000000
											BNE +changeToWalk_Dpadpressed
												JMP +checkLandingDpadNotpressed
											; dpad is pressed, so we walk
											+changeToWalk_Dpadpressed:
												ChangeActionStep selfObject, #$01 ; change to walk
												JMP +handleBlockMovement

											+checkLandingDpadNotpressed:
												ChangeActionStep selfObject, #$00 ; change to idle
									
									+handleBlockMovement
									LDA colInfo
									AND #%00000010 ;; if we have vertical, don't move
									BEQ +continueCheck
										JMP +resetsPosition

									+continueCheck
									LDA Object_vulnerability,X
									AND #%00000010 ;; flag 1 (we don't move these blocks)
									BEQ +doBlockMovement
										JMP +resetsPosition

									;; updates block movement									
									+doBlockMovement
										LDA gamepad 
										AND #%10000000
										BNE +moveBlockRight
											JMP +checkBlockLeft
										
										+moveBlockRight
											StartMoving otherObject, #RIGHT
											JMP +resetsPosition
										
										+checkBlockLeft
											LDA gamepad 
											AND #%01000000
											BEQ +resetsPosition
												StartMoving otherObject, #LEFT

									; clean up, fix both position to not entwine
									+resetsPosition
									TXA 
									PHA
										LDX selfObject
										LDA xPrev
										STA Object_x_hi,x
										STA xHold_hi
										
										LDA yPrev
										STA Object_y_hi,x
										STA yHold_hi
										
										LDA #$00
										STA Object_h_speed_lo,x
										STA Object_h_speed_hi,x
										STA Object_v_speed_lo,x
										STA Object_v_speed_hi,x
										STA Object_x_lo,x
										STA Object_y_lo,x
									PLA
									TAX

									JMP +done
									
							+isNotPlayerNPCCol
								LDA #$00
								STA colInfo
								StopMoving otherObject, #$FF, #$00

							+skipCollision

					
							INX
							CPX #TOTAL_MAX_OBJECTS
							BEQ +lastCollisionForThisObject
								JMP loop_objectPlayerCollisions
							+lastCollisionForThisObject
							; PLA
							; TAX
							JMP +done
						
							
							;; Add other object to object collision types here.
						JMP +done
							
			
		+notPlayerForCollisions
	
+done	
	PLA
	TAY
	PLA
	TAX
+skipObjectCollisionCheck
	ReturnBank