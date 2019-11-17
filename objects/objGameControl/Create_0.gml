/// @description Insert description here
// You can write your code in this editor

addKoalaTimerMin = 3*room_speed
addKoalaTimerMax = 4*room_speed
if(FOUNTAIN_MODE) {
	addKoalaTimerMin = 3//*room_speed
	addKoalaTimerMax = 4//*room_speed
}

// Show the first ball after a small delay
alarm[0] = 1*room_speed;

