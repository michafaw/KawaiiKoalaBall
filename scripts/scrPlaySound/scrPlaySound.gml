/// Plays a sound. Optionally modifies the pitch slightly.

var soundToPlay = argument0;
var shouldAdjustPitch = argument1;

if(!audio_exists(argument0))
	return noone;

if(audio_is_playing(soundToPlay))
	audio_stop_sound(soundToPlay);
	
var newSound = audio_play_sound(soundToPlay, 0, false);
if(shouldAdjustPitch) {
	audio_sound_pitch(newSound, choose(1.0, 1.04, 0.96, 1.02, 0.98)); //1.0594 = 1/2 step
}

return newSound;