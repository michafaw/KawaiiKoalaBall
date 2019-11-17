/// @description Insert description here
// You can write your code in this editor


var rightCollision = bbox_right > room_width;
var leftCollision = bbox_left < 0;

if(rightCollision)
	hspeed = -abs(hspeed)
	
if(leftCollision)
	hspeed = abs(hspeed)