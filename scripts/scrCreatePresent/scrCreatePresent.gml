/// scrCreatePresent(x, y)

var xx = argument0;
var yy = argument1;

show_debug_message("Debug - Creating present at " + string(xx) + ", " + string(yy));
var newKoala = instance_create_layer(xx, yy, "Instances", objPresent)

newKoala.speed = 2;
newKoala.direction = 90;

return newKoala;