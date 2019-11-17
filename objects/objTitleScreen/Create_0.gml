/// @description Insert description here
// You can write your code in this editor

if(global.activeMusic == noone || !audio_is_playing(global.activeMusic)) {
	global.activeMusic = audio_play_sound(musMainTheme, 0, true);
}