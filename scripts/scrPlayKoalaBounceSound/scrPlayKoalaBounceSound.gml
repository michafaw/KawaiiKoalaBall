/// scrPlayKoalaBounceSound(koalaInstance)

var koalaInstance = argument0;

// Make sure we didn't just play a bounce sound
if(koalaInstance.currentSound == noone || !audio_is_playing(koalaInstance.currentSound)) {
	var soundToPlay = choose(Koala_Bounce_A, Koala_Bounce_B);
	koalaInstance.currentSound = scrPlaySound(soundToPlay, true);
}

