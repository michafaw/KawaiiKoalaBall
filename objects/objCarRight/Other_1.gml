/// @description Insert description here
// You can write your code in this editor

speed = 0;
	
if (x - sprite_get_xoffset(sprite_index) < 0)
	x = sprite_get_xoffset(sprite_index);
else if (x - sprite_get_xoffset(sprite_index) + sprite_width > room_width)
	x = room_width + sprite_get_xoffset(sprite_index) - sprite_width

// Play screech sound -- Micha TODO
