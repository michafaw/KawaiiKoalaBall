/// @description Insert description here
// You can write your code in this editor

var pathPosition = random(1)
if(FOUNTAIN_MODE)
	pathPosition = random(0.10) + 0.45 // Fountain mode
	
xx = path_get_x(pathKoalaDrop, pathPosition)
yy = path_get_y(pathKoalaDrop, pathPosition)


scrCreateKoalaBall(xx, yy)
alarm[0] = irandom_range(addKoalaTimerMin, addKoalaTimerMax)