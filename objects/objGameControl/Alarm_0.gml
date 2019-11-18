/// @description Insert description here
// You can write your code in this editor

var pathPosition = random(1)
if(FOUNTAIN_MODE && !RAIN_MODE)
	pathPosition = random(0.10) + 0.45 // Fountain mode drops koalas in the center
	
xx = path_get_x(pathKoalaDrop, pathPosition)
yy = path_get_y(pathKoalaDrop, pathPosition)

if(random(1.0) < 0.875)
	scrCreateKoalaBall(xx, yy);
else
	scrCreatePresent(xx, yy);

var respawnTime = irandom_range(addKoalaTimerMin, addKoalaTimerMax);
if(global.koalaSpawnRate > 0)
	alarm[0] = respawnTime/global.koalaSpawnRate;
else
  alarm[0] = respawnTime;
	
