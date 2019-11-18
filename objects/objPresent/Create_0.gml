
event_inherited();

baseGravity = 0.06;
gravity_direction = 270;
gravity = baseGravity;

carBounceSpeed = 7;

maxSpeed = 15;

currentSound = noone;

var playRustleSound = PRActionRunScript(scrPlayUniqueSound, Tree_Rustle, true);
var pauseAction = PRActionWait(0.75);
var playDropSound = PRActionRunScript(scrPlayUniqueSound, Koala_Falling, true);
var sequence = PRActionSequence(playRustleSound, pauseAction, playDropSound);
PRActionPlay(self, sequence);

image_index = 5;
alarm[0] = room_speed;
image_speed = 0;