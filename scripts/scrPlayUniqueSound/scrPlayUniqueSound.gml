/// Plays a sound. Stops any other instances of the same sound that are playing

var soundToPlay = argument0;
var shouldAdjustPitch = argument1;

if(!audio_exists(argument0))
	return;

if(audio_is_playing(soundToPlay))
	audio_stop_sound(soundToPlay);
	
return scrPlaySound(soundToPlay, shouldAdjustPitch);