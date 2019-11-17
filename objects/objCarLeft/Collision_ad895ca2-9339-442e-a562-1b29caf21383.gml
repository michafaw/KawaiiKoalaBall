/// @description Insert description here
// You can write your code in this editor

speed = 0;

if (x - sprite_get_xoffset(sprite_index) + sprite_width > other.bbox_left)
	x = other.bbox_left + sprite_get_xoffset(sprite_index) - sprite_width