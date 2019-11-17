/// @description Insert description here
// You can write your code in this editor

var topBounceHorizontalNudge = 1;
var needsTopBounceHorizontalNudge = false;

var rightCollision = other.bbox_right > bbox_left && other.bbox_right < bbox_right;
var leftCollision = other.bbox_left > bbox_left && other.bbox_left < bbox_right;
var topCollision = other.bbox_top > bbox_top && other.bbox_top < bbox_bottom;


// Something not quite right here, but not obvious what it is
// See a ball that drops straight down and how it goes too far into the bounding box
if(topCollision && rightCollision && y < other.bbox_top) {
	// Bounce right, off of the top right side
	hspeed = abs(hspeed)
} else if(topCollision && rightCollision && !leftCollision && y > other.bbox_top) {
	// Bounce up, off of the top right side
	vspeed = -abs(vspeed)
	// Give it a small bit of additional horizontal movement if it's mostly bouncing vertically
	if(abs(hspeed) < 1)
		needsTopBounceHorizontalNudge = true
	show_debug_message("Debug - Bounce up, off of the top right side");	
} else if(topCollision && leftCollision && y < other.bbox_top) {
	// Bounce left, off of the top left side
	hspeed = -abs(hspeed)
} else if(topCollision && leftCollision && !rightCollision && y > other.bbox_top) {
	// Bounce up, off of the top left side
	vspeed = -abs(vspeed)
	// Give it a small bit of additional horizontal movement if it's mostly bouncing vertically
	if(abs(hspeed) < 1)
		needsTopBounceHorizontalNudge = true
	show_debug_message("Debug - Bounce up, off of the top left side");	
} else if(topCollision) {
	// Bounce up, off of the top side
	vspeed = -abs(vspeed)
	// Give it a small bit of additional horizontal movement if it's mostly bouncing vertically
	if(abs(hspeed) < 1)
		needsTopBounceHorizontalNudge = true
	show_debug_message("Debug - Bounce up, off of the top side");
} else if(rightCollision) {
	// Bounce right, off of the right side
	hspeed = abs(hspeed)
} else if(leftCollision) {
	// Bounce left, off of the left side
	hspeed = -abs(hspeed)
} else {
	show_debug_message("Warning - Collided with the net, but this case wasn't covered");	
}

if(needsTopBounceHorizontalNudge) {
	// Give it a small bit of additional horizontal movement if it's mostly bouncing vertically
	if(x > other.x)
		hspeed += topBounceHorizontalNudge;
	else if (x < other.x)
		hspeed -= topBounceHorizontalNudge;
	else
		hspeed += choose(topBounceHorizontalNudge, -topBounceHorizontalNudge);
	show_debug_message("Debug - Bumping hspeed to " + string(hspeed) + " - x/other.x: " + string(x) + "/" + string(other.x));
}