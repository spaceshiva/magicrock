;; AI jump

SwitchBank #$1C
	
LDY Object_type,x
LDA ObjectJumpSpeedLo,y
EOR #$FF
STA Object_v_speed_lo,x
LDA ObjectJumpSpeedHi,y
EOR #$FF
STA Object_v_speed_hi,x

ReturnBank
RTS