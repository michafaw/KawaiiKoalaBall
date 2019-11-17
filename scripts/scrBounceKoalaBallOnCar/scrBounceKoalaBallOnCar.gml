///scrBounceKoalaBallOnCar(koalaBallInstance, carInstance)

var koalaBallInstance = argument0;
var carInstance = argument1;

var maxRange = 48; // Actually ends up as 48
var chunk = maxRange/6;


scrPlayKoalaBounceSound(koalaBallInstance);

var newSpeed = koalaBallInstance.carBounceSpeed
var rotationDuration = 1;
var rotationAmplitude = 0;

xDiff = koalaBallInstance.x - carInstance.x;
if(xDiff < -chunk*3) {
	direction = 130
	newSpeed *= 0.85
	rotationAmplitude = 1
} else if(xDiff < -chunk) {
	direction = 110
	newSpeed *= 0.9
	rotationAmplitude = 0.5
} else if(xDiff < 0) {
	direction = 95
	newSpeed *= 0.8
	rotationAmplitude = 0.1
} else if(xDiff < chunk) {
	direction = 85
	newSpeed *= 0.8
	rotationAmplitude = -0.1
} else if(xDiff < chunk*3) {
	direction = 70
	newSpeed *= 0.9
	rotationAmplitude = -0.5
} else {
	direction = 50
	newSpeed *= 0.85
	rotationAmplitude = -1
}

koalaBallInstance.speed = newSpeed

rotationAmplitude *= random_range(0.9, 1.11)
var newRotationAction = PRActionRotateBy(rotationAmplitude*360, PRActionEaseIdLinear, rotationDuration);
PRActionStopAction(koalaBallInstance, "koala_rotation");
PRActionPlay(koalaBallInstance, PRActionRepeatForever(newRotationAction), "koala_rotation");

