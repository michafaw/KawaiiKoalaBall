/// @description Insert description here
// You can write your code in this editor

event_inherited();

addKoalaTimerMin = 3*room_speed
addKoalaTimerMax = 4*room_speed
if(FOUNTAIN_MODE || RAIN_MODE) {
	addKoalaTimerMin = 3;
	addKoalaTimerMax = 4;
}

// Show the first ball after a small delay
alarm[0] = 1*room_speed;

global.koalaSpawnRate = 2.0

audio_play_sound(Car_Idle, 90, true);

