

var powerUp = choose(0, 1)

switch(powerUp) {
	case 0:
		with(objKoalaBall) {
			var dupe = instance_create_layer(x, y, "Instances", objKoalaBall);
			dupe.direction = self.direction;
			dupe.speed = self.speed;
			dupe.direction += random_range(-15, 15)
			dupe.speed *= random_range(0.9, 1.1);
		}
		show_debug_message("Doubling koala count to " + string(instance_number(objKoalaBall)));
		break;
	case 1:
		with(objGameControl) {
			var increase = PRActionRunScript(scrIncreaseKoalaSpawn)
			var wait = PRActionWait(10)
			var decrease = PRActionRunScript(scrDecreaseKoalaSpawn)
			var sequence = PRActionSequence(increase, wait, decrease);
			PRActionPlay(instance_find(objGameControl, 0), sequence);
		}
		break;
}