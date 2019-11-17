/// @description Insert description here
// You can write your code in this editor

speed = 0;

if (x - sprite_get_xoffset(sprite_index) < other.bbox_right)
	x = other.bbox_right + sprite_get_xoffset(sprite_index);