/// @description Insert description here
// You can write your code in this editor

scrPlaySound(Koala_Ground_Thud, false);
if(x > room_width/2)
	global.leftScore++;
else
	global.rightScore++;
	
show_debug_message("Score: " + string(global.leftScore) + "-" + string(global.rightScore))

scrCheckScore();

instance_destroy();