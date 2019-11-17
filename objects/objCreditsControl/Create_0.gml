/// @description Insert description here
// You can write your code in this editor

canExitScreen = false;
alarm[0] = 1.5*room_speed;

if(global.leftScore > global.rightScore)
	layer_set_visible("Assets_P1_Wins", true);
else
	layer_set_visible("Assets_P2_Wins", true);