
event_inherited();

baseGravity = 0.08;
gravity_direction = 270;
gravity = baseGravity;

carBounceSpeed = 12;

maxSpeed = 15;

currentSound = noone;

var playRustleSound = PRActionRunScript(scrPlayUniqueSound, Tree_Rustle, true);
var pauseAction = PRActionWait(0.75);
var playDropSound = PRActionRunScript(scrPlayUniqueSound, Koala_Falling, true);

var sequence = PRActionSequence(playRustleSound, pauseAction, playDropSound);

PRActionPlay(self, sequence);