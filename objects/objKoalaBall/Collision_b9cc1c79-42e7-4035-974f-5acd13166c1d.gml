/// @description Insert description here
// You can write your code in this editor

scrPlaySound(Koala_Ground_Thud, false);
if(x > room_speed/2)
	global.leftScore++;
else
	global.rightScore++;

instance_destroy();