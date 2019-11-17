/// @description Insert description here
// You can write your code in this editor

event_inherited();


pathPosition += pathSpeed;

if(pathPosition >= 1.0)
	pathSpeed = -abs(pathSpeed);
else if(pathPosition <= 0.0)
	pathSpeed = abs(pathSpeed);
pathPostion = clamp(pathPosition, 0.0, 1.0)
	
x = path_get_x(pathName, pathPosition)
y = path_get_y(pathName, pathPosition)