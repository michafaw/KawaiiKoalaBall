/// @description Insert description here
// You can write your code in this editor

event_inherited();

var leftButton = ord("A")
var rightButton = ord("D")
var forwardImageAngle = 5;
var reverseImageAngle = -2;
speed *= 0.97

var speedToAnimationRatio = 25/room_speed
image_speed = speed * speedToAnimationRatio;

sandCloudInstance.x = x + sandCloudOffset[0];
sandCloudInstance.y = y + sandCloudOffset[1];
if(image_angle == forwardImageAngle)
	sandCloudInstance.y += 4;

if(keyboard_check_pressed(leftButton)) {
	sandCloudInstance.image_index = 0;
	scrPlaySound(Car_Movement_A, true);
	if(speed > maxSpeed*0.9)
		scrPlaySound(Car_Skid, true);
} else if(keyboard_check_pressed(rightButton)) {
	sandCloudInstance.image_index = 0;
	scrPlaySound(Car_Movement_A, true);
	if(speed < -maxSpeed*0.9)
		scrPlaySound(Car_Skid, true);
}


if(keyboard_check(rightButton) && speed > 0.6) {
	image_angle = forwardImageAngle;
} else if(keyboard_check(leftButton) && speed < -0.6) {
	image_angle = reverseImageAngle;
} else {
	image_angle = 0;
}


if(keyboard_check_released(leftButton) || keyboard_check_released(rightButton))
	sandCloudInstance.visible = false;