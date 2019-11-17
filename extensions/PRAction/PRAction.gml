// **********************************************************************************************
// CORE FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionInit
/// @description Initialize PRAction for this object.  Call once in the Create event.

// Internal use only.
_practionActions = array_create(2, noone);  // Default to 2 action slots.  Will grow if necessary.
_practionStatus = PRActionStatusStopped;
_practionPlayingActionsCount = 0;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionDestroy
/// @description Deinitialize PRAction for this object.  Call once in the Destroy event.

var actionsLength = array_length_1d(_practionActions);
for (var i = 0; i < actionsLength; i++) {
	_practionActions[i] = noone;
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionUpdate
/// @description Frame update.  Call every game frame in the Step event.

if _practionStatus != PRActionStatusPlaying { return; }
var actionCount = array_length_1d(_practionActions);

// Iterate through each valid action and update them for the current frame.
for (var i = 0; i < actionCount; i++) {
	var currentAction = _practionActions[i];
	if currentAction != noone {
		if _PRActionUpdate(currentAction) {
			// Action has completed, so stop it.
			PRActionStop(self, i);
			if (_practionPlayingActionsCount == 0) break;
		}
	}
}

// ---------------------------------------------------------------------------------------------------------------------
#define _PRActionUpdate
/// @desc Advances the frame for the current action and processes it.  (Internal use only.)
/// @arg action

var action = argument0;
var actionCompleted = false;

var actionType = action[1];
switch (actionType) {
	case PRActionTypeSequence:
		var sequenceIndex = action[4];
		var sequenceActions = action[18];
		var actionInSequence = sequenceActions[sequenceIndex];

		if _PRActionUpdate(actionInSequence) {
			var actionCount = array_length_1d(action[18]);
			action[@ 4] = sequenceIndex + 1;
			if action[4] >= actionCount {
				actionCompleted = true;
				action[@ 4] = 0;
			}
		}
		break;

	case PRActionTypeGroup:
		actionCompleted = true;
		var groupActions = action[18];
		var groupActionsCompleted = action[4];
		var actionCount = array_length_1d(groupActions);

		for (var i = 0; i < actionCount; i++) {
			if !groupActionsCompleted[i] {
				var actionInGroup = groupActions[i];
				if _PRActionUpdate(actionInGroup)
					groupActionsCompleted[i] = true;
				else
					actionCompleted = false;
			}
		}

		if actionCompleted
			action[@ 4] = array_create(actionCount, false);
		else
			action[@ 4] = groupActionsCompleted;

		break;

	case PRActionTypeRepeater:
		var actionToRepeatArray = action[18];
		var actionToRepeat = actionToRepeatArray[0];
		if action[4] > 0 or action[4] == -1 { // Repeat count
			if _PRActionUpdate(actionToRepeat) {
				if action[4] > 0 {
					if --action[@ 4] == 0 {
						actionCompleted = true;
						action[@ 4] = action[16];
					}
				}
			}
		}
		break;

	default:
		if (action[12] < action[13] or action[12] == 0) {
			// Initialize action values for first update.
			if action[12] == 0 { _PRActionUpdateCalcDeltas(action); }

			// Apply easing equation.
			_PRActionUpdateEase(action);

			if action[12] == action[13] {
				actionCompleted = true;
				action[@ 12] = 0;
			}
		}
		break;
}

return actionCompleted;

// ---------------------------------------------------------------------------------------------------------------------
#define _PRActionUpdateCalcDeltas
/// @desc Calculates the delta/start values of the given action.  (Internal use only.)
/// @arg action

var action = argument0;

if action[1] == PRActionTypeWait return;
var isInstantAction = (action[13] == 0);

// Reset action's values from the original action template.  Skip index 0 which may contain the name.
var originalAction = action[3];
for (var i = 1; i < _PRActionActionSize; i++) {
	if i != 3 action[@ i] = originalAction[i];
}

// Calculate and store the delta change values and the start values.
switch (action[1]) { // Action type
	case PRActionTypeSequence:
	case PRActionTypeGroup:
		action[@ 4] = 0;
		break;
	case PRActionTypeRepeater:
		action[@ 4] = action[16];
		break;
	case PRActionTypeCustomScript1:
		if !isInstantAction action[@ 10] = action[8] - action[6];
		break;
	case PRActionTypeCustomColorScript:
		var colorDeltas = action[10];
		colorDeltas[0] = color_get_red(action[8]) - color_get_red(action[6]);
		colorDeltas[1] = color_get_green(action[8]) - color_get_green(action[6]);
		colorDeltas[2] = color_get_blue(action[8]) - color_get_blue(action[6]);
		action[@ 10] = colorDeltas;
		break;
	case PRActionTypeCustomScript2:
		if !isInstantAction {
			action[@ 10] = action[8] - action[6];
			action[@ 11] = action[9] - action[7];
		}
		break;
	case PRActionTypeCustomVarTo:
		action[@ 6] = variable_instance_get(self, action[4]);
		action[@ 10] = action[8] - action[6];
		break;
	case PRActionTypeCustomVarBy:
		action[@ 6] = variable_instance_get(self, action[4]);
		action[@ 16] = action[6];
		action[@ 10] = action[8];
		action[@ 8] = action[6] + action[8];
		break;
	case PRActionTypeCustomColorVarTo:
		action[@ 6] = variable_instance_get(self, action[4]);

		var colorDeltas = action[10];
		colorDeltas[0] = color_get_red(action[8]) - color_get_red(action[6]);
		colorDeltas[1] = color_get_green(action[8]) - color_get_green(action[6]);
		colorDeltas[2] = color_get_blue(action[8]) - color_get_blue(action[6]);
		action[@ 10] = colorDeltas;
		break;
	case PRActionTypeCustomColorVarBy:
		action[@ 6] = variable_instance_get(self, action[4]);
		action[@ 16] = action[6];
		action[@ 10] = action[8];

		var colorDeltas = action[8];
		var finalDestColor = array_create(3, 0);
		finalDestColor[0] = color_get_red(action[6]) + colorDeltas[0];
		finalDestColor[1] = color_get_green(action[6]) + colorDeltas[1];
		finalDestColor[2] = color_get_blue(action[6]) + colorDeltas[2];

		// Value limiter option.
		if action[15] {
			clamp(finalDestColor[0], 0, 255);
			clamp(finalDestColor[1], 0, 255);
			clamp(finalDestColor[2], 0, 255);
		}

		action[@ 8] = finalDestColor;
		break;
	case PRActionTypeMoveTo:
		action[@ 6] = x;
		action[@ 7] = y;
		action[@ 10] = action[8] - x;
		action[@ 11] = action[9] - y;
		break;
	case PRActionTypeMoveBy:
		action[@ 6] = x;
		action[@ 7] = y;
		action[@ 16] = x;
		action[@ 17] = y;
		action[@ 10] = action[8];
		action[@ 11] = action[9];
		action[@ 8] = x + action[8];
		action[@ 9] = y + action[9];
		break;
	case PRActionTypeMoveXTo:
		action[@ 6] = x;
		action[@ 10] = action[8] - x;
		break;
	case PRActionTypeMoveXBy:
		action[@ 6] = x;
		action[@ 16] = x;
		action[@ 10] = action[8];
		action[@ 8] = x + action[8];
		break;
	case PRActionTypeMoveYTo:
		action[@ 6] = y;
		action[@ 10] = action[8] - y;
		break;
	case PRActionTypeMoveYBy:
		action[@ 6] = y;
		action[@ 16] = y;
		action[@ 10] = action[8];
		action[@ 8] = y + action[8];
		break;
	case PRActionTypeRotateTo:
		action[@ 6] = image_angle;
		action[@ 10] = action[8] - image_angle;
		break;
	case PRActionTypeRotateBy:
		action[@ 6] = image_angle;
		action[@ 16] = image_angle;
		action[@ 10] = action[8];
		action[@ 8] = image_angle + action[8];
		break;
	case PRActionTypeScaleXTo:
		action[@ 6] = image_xscale;
		action[@ 10] = action[8] - image_xscale;
		break;
	case PRActionTypeScaleXBy:
		action[@ 6] = image_xscale;
		action[@ 16] = image_xscale;
		action[@ 10] = action[8];
		action[@ 8] = image_xscale + action[8];
		break;
	case PRActionTypeScaleYTo:
		action[@ 6] = image_yscale;
		action[@ 10] = action[8] - image_yscale;
		break;
	case PRActionTypeScaleYBy:
		action[@ 6] = image_yscale;
		action[@ 16] = image_yscale;
		action[@ 10] = action[8];
		action[@ 8] = image_yscale + action[8];
		break;
	case PRActionTypeScaleTo:
		action[@ 6] = image_xscale;
		action[@ 7] = image_yscale;
		action[@ 10] = action[8] - image_xscale;
		action[@ 11] = action[9] - image_yscale;
		break;
	case PRActionTypeScaleBy:
		action[@ 6] = image_xscale;
		action[@ 7] = image_yscale;
		action[@ 16] = image_xscale;
		action[@ 17] = image_yscale;
		action[@ 10] = action[8];
		action[@ 11] = action[9];
		action[@ 8] = image_xscale + action[8];
		action[@ 9] = image_yscale + action[9];
		break;
	case PRActionTypeAlphaTo:
		action[@ 6] = image_alpha;
		action[@ 10] = action[8] - image_alpha;
		break;
	case PRActionTypeAlphaBy:
		action[@ 6] = image_alpha;
		action[@ 16] = image_alpha;
		action[@ 10] = action[8];
		action[@ 8] = image_alpha + action[8];
		break;
	case PRActionTypeBlendTo:
		action[@ 6] = image_blend;

		var colorDeltas = action[10];
		colorDeltas[0] = color_get_red(action[8]) - color_get_red(image_blend);
		colorDeltas[1] = color_get_green(action[8]) - color_get_green(image_blend);
		colorDeltas[2] = color_get_blue(action[8]) - color_get_blue(image_blend);
		action[@ 10] = colorDeltas;
		break;
	case PRActionTypeBlendBy:
		action[@ 6] = image_blend;
		action[@ 16] = image_blend;
		action[@ 10] = action[8];

		var colorDeltas = action[8];
		var finalDestColor = array_create(3, 0);
		finalDestColor[0] = color_get_red(image_blend) + colorDeltas[0];
		finalDestColor[1] = color_get_green(image_blend) + colorDeltas[1];
		finalDestColor[2] = color_get_blue(image_blend) + colorDeltas[2];

		// Value limiter option.
		if action[15] {
			clamp(finalDestColor[0], 0, 255);
			clamp(finalDestColor[1], 0, 255);
			clamp(finalDestColor[2], 0, 255);
		}

		action[@ 8] = finalDestColor;
		break;
	case PRActionTypeImageSpeedTo:
		action[@ 6] = image_speed;
		action[@ 10] = action[8] - image_speed;
		break;
	case PRActionTypeImageSpeedBy:
		action[@ 6] = image_speed;
		action[@ 16] = image_speed;
		action[@ 10] = action[8];
		action[@ 8] = image_speed + action[8];
		break;
	case PRActionTypeDepthTo:
		action[@ 6] = depth;
		action[@ 10] = action[8] - depth;
		break;
	case PRActionTypeDepthBy:
		action[@ 6] = depth;
		action[@ 16] = depth;
		action[@ 10] = action[8];
		action[@ 8] = depth + action[8];
		break;
}

// ---------------------------------------------------------------------------------------------------------------------
#define _PRActionUpdateEase
/// @desc Updates the ease values of the given action.  (Internal use only.)
/// @arg action

var action = argument0;

var newValue1 = 0;
var newValue2 = 0;
var isInstantAction = (action[13] == 0);
var isColorAction = (action[1] == PRActionTypeBlendTo or action[1] == PRActionTypeBlendBy or action[1] == PRActionTypeCustomColorVarTo or action[1] == PRActionTypeCustomColorVarBy or action[1] == PRActionTypeCustomColorScript);

// Increment current step, if not an instant action.
if !isInstantAction action[@ 12]++;

if action[1] == PRActionTypeWait return;

// Run ease scripts to determine the new values.
if !isInstantAction {
	if !isColorAction {
		// Real number values.
		if action[5] >= 1 newValue1 = script_execute(action[2], action[12], action[6], action[10], action[13], action[14]);
		if action[5] >= 2 newValue2 = script_execute(action[2], action[12], action[7], action[11], action[13], action[14]);
	}
	else {
		// Color values.
		var colorDelta = noone;
		var redComponent = 0;
		var greenComponent = 0;
		var blueComponent = 0;

		// Cycle through the number of values that need updating (up to 2).
		for (var i = 0; i < action[5]; i++) {
			colorDelta = action[10 + i];
			redComponent = color_get_red(action[6 + i]);
			greenComponent = color_get_green(action[6 + i]);
			blueComponent = color_get_blue(action[6 + i]);
			redComponent = script_execute(action[2], action[12], redComponent, colorDelta[0], action[13], action[14]);
			greenComponent = script_execute(action[2], action[12], greenComponent, colorDelta[1], action[13], action[14]);
			blueComponent = script_execute(action[2], action[12], blueComponent, colorDelta[2], action[13], action[14]);

			// Value limiter option.
			if action[15] {
				clamp(redComponent, 0, 255);
				clamp(greenComponent, 0, 255);
				clamp(blueComponent, 0, 255);
			}

			// Only 2 values supported.
			if i == 0 newValue1 = make_color_rgb(redComponent, greenComponent, blueComponent);
			if i == 1 newValue2 = make_color_rgb(redComponent, greenComponent, blueComponent);
		}
	}
}
else {
	if action[5] >= 1 newValue1 = action[8];
	if action[5] >= 2 newValue2 = action[9];
}

// Apply the new value(s) depending on the action type chosen.
switch (action[1]) { // Action type
	case PRActionTypeCustomVarTo:
	case PRActionTypeCustomColorVarTo:
	case PRActionTypeSetVar:
		variable_instance_set(self, action[4], newValue1);
		break;
	case PRActionTypeCustomScript1:
	case PRActionTypeCustomColorScript:
		script_execute(action[4], newValue1);
		break;
	case PRActionTypeCustomScript2:
		script_execute(action[4], newValue1, newValue2);
		break;
	case PRActionTypeCustomVarBy:
		var value = variable_instance_get(self, action[4]);
		value = value - (action[16] - action[6]) + (newValue1 - action[6]);
		variable_instance_set(self, action[4], value);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeCustomColorVarBy:
		var value = variable_instance_get(self, action[4]);
		var blendRed = color_get_red(value);
		var blendGreen = color_get_green(value);
		var blendBlue = color_get_blue(value);
		var storRed = color_get_red(action[16]);
		var storGreen = color_get_green(action[16]);
		var storBlue = color_get_blue(action[16]);
		var startRed = color_get_red(action[6]);
		var startGreen = color_get_green(action[6]);
		var startBlue = color_get_blue(action[6]);
		var newVal1Red = color_get_red(newValue1);
		var newVal1Green = color_get_green(newValue1);
		var newVal1Blue = color_get_blue(newValue1);
		var newRed = blendRed - (storRed - startRed) + (newVal1Red - startRed);
		var newGreen = blendGreen - (storGreen - startGreen) + (newVal1Green - startGreen);
		var newBlue = blendBlue - (storBlue - startBlue) + (newVal1Blue - startBlue);
		value = make_color_rgb(newRed, newGreen, newBlue);
		variable_instance_set(self, action[4], value);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeMoveTo:
		x = newValue1;
		y = newValue2;
		break;
	case PRActionTypeMoveBy:
		x = x - (action[16] - action[6]) + (newValue1 - action[6]);
		y = y - (action[17] - action[7]) + (newValue2 - action[7]);
		action[@ 16] = newValue1;
		action[@ 17] = newValue2;
		break;
	case PRActionTypeMoveXTo:
		x = newValue1;
		break;
	case PRActionTypeMoveXBy:
		x = x - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeMoveYTo:
		y = newValue1;
		break;
	case PRActionTypeMoveYBy:
		y = y - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeRotateTo:
		image_angle = newValue1;
		break;
	case PRActionTypeRotateBy:
		image_angle = image_angle - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeScaleXTo:
		image_xscale = newValue1;
		break;
	case PRActionTypeScaleXBy:
		image_xscale = image_xscale - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeScaleYTo:
		image_yscale = newValue1;
		break;
	case PRActionTypeScaleYBy:
		image_yscale = image_yscale - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeScaleTo:
		image_xscale = newValue1;
		image_yscale = newValue2;
		break;
	case PRActionTypeScaleBy:
		image_xscale = image_xscale - (action[16] - action[6]) + (newValue1 - action[6]);
		image_yscale = image_yscale - (action[17] - action[7]) + (newValue2 - action[7]);
		action[@ 16] = newValue1;
		action[@ 17] = newValue2;
		break;
	case PRActionTypeAlphaTo:
		image_alpha = newValue1;
		break;
	case PRActionTypeAlphaBy:
		image_alpha = image_alpha - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeBlendTo:
		image_blend = newValue1;
		break;
	case PRActionTypeBlendBy:
		var blendRed = color_get_red(image_blend);
		var blendGreen = color_get_green(image_blend);
		var blendBlue = color_get_blue(image_blend);
		var storRed = color_get_red(action[16]);
		var storGreen = color_get_green(action[16]);
		var storBlue = color_get_blue(action[16]);
		var startRed = color_get_red(action[6]);
		var startGreen = color_get_green(action[6]);
		var startBlue = color_get_blue(action[6]);
		var newVal1Red = color_get_red(newValue1);
		var newVal1Green = color_get_green(newValue1);
		var newVal1Blue = color_get_blue(newValue1);
		var newRed = blendRed - (storRed - startRed) + (newVal1Red - startRed);
		var newGreen = blendGreen - (storGreen - startGreen) + (newVal1Green - startGreen);
		var newBlue = blendBlue - (storBlue - startBlue) + (newVal1Blue - startBlue);
		image_blend = make_color_rgb(newRed, newGreen, newBlue);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeImageSpeedTo:
		image_speed = newValue1;
		break;
	case PRActionTypeImageSpeedBy:
		image_speed = image_speed - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeDepthTo:
		depth = newValue1;
		break;
	case PRActionTypeDepthBy:
		depth = depth - (action[16] - action[6]) + (newValue1 - action[6]);
		action[@ 16] = newValue1;
		break;
	case PRActionTypeRunScript:
		// Run script passing it the number of arguments in the action.
		if action[5] == 0 script_execute(action[4]);
		else if action[5] == 1 script_execute(action[4], action[6]);
		else if action[5] == 2 script_execute(action[4], action[6], action[7]);
		else if action[5] == 3 script_execute(action[4], action[6], action[7], action[8]);
		else if action[5] == 4 script_execute(action[4], action[6], action[7], action[8], action[9]);
		else if action[5] == 5 script_execute(action[4], action[6], action[7], action[8], action[9], action[10]);
		else if action[5] == 6 script_execute(action[4], action[6], action[7], action[8], action[9], action[10], action[11]);
		else if action[5] == 7 script_execute(action[4], action[6], action[7], action[8], action[9], action[10], action[11], action[16]);
		else if action[5] == 8 script_execute(action[4], action[6], action[7], action[8], action[9], action[10], action[11], action[16], action[17]);
		break;
	case PRActionTypeRunUserEvent:
		event_user(action[4]);
		break;
	case PRActionTypePlaySound:
		audio_play_sound(action[4], action[6], action[7]);
		break;
	case PRActionTypeStopSound:
		audio_stop_sound(action[4]);
		break;
	case PRActionTypeStopAllSounds:
		audio_stop_all();
		break;
	case PRActionTypeHide:
		visible = false;
		break;
	case PRActionTypeUnhide:
		visible = true;
		break;
	case PRActionTypeSpriteIndex:
		if action[6] != noone sprite_index = action[6];
		if action[7] != noone image_index = action[7];
		break;
	case PRActionTypeChangeLayer:
		var layerId = layer_get_id(action[4]);
		if layerId != -1
			layer = layerId;
		break;
	case PRActionTypePlayAction:
		PRActionPlay(action[4], action[18]);
		break;
	case PRActionTypeStopAction:
		PRActionStop(action[4], action[18]);
		break;
	case PRActionTypeStopAllAction:
		PRActionStopAll(action[4]);
		break;
	case PRActionTypeDestroyObject:
		instance_destroy(action[4]);
		break;
	case PRActionTypeGotoRoom:
		room_goto(action[4]);
		break;
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionPlay
/// @description Plays the given action in the context of the given object.  Does not interrupt other actions being played.  Returns the action's slot index.
/// @arg obj
/// @arg action
/// @arg [optionalName]

var obj = argument[0];
var action = argument[1];

var name = "";
if argument_count >= 3 name = argument[2];

var slot = noone;

with (obj) {
	// Mark the instance's PRAction status as playing.
	_practionStatus = PRActionStatusPlaying;

	// Prep the action for playing.
	action = _PRActionPlayPrep(action, name);

	// Locate an open slot in the instance to put the action into.
	var arrayLength = array_length_1d(_practionActions);
	for (slot = 0; slot < arrayLength; slot++) {
		if _practionActions[slot] == noone {
			break;
		}
	}

	// If no slot found, create a new slot.
	if slot == arrayLength { _practionActions[slot] = noone; }

	// Assign the action array to the object instance's open slot.
	_practionActions[slot] = action;
	_practionPlayingActionsCount++;
}

return slot;

// ---------------------------------------------------------------------------------------------------------------------
#define _PRActionPlayPrep
/// @description Preps the given action for playing.  (Internal use only.)
/// @arg action
/// @arg name

var action = argument0;
var name = argument1;

// Copy the actions configuration into an action array.  When done, the action is prepped.
var preppedAction = array_create(_PRActionActionSize, noone);
var originalAction = array_create(_PRActionActionSize, noone);
for (var i = 0; i < _PRActionActionSize; i++) {
	preppedAction[i] = action[i];
	originalAction[i] = action[i];
}

preppedAction[0] = name;
preppedAction[3] = originalAction;

// If the prepped action is a container (sequence, group), then prep each of the actions within as well.
if preppedAction[1] == PRActionTypeSequence or preppedAction[1] == PRActionTypeGroup or preppedAction[1] == PRActionTypeRepeater {
	var actionsInContainer = preppedAction[18];
	var actionsInContainerCount = array_length_1d(actionsInContainer);
	var preppedContainerActions = array_create(actionsInContainerCount, noone);

	for (var i = 0; i < actionsInContainerCount; i++) {
		var preppedContainerAction = _PRActionPlayPrep(actionsInContainer[i], "");
		preppedContainerActions[i] = preppedContainerAction;
	}

	preppedAction[18] = preppedContainerActions;
}

return preppedAction;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStop
/// @description Stops the action at the given slot index or with the given name.
/// @arg obj
/// @arg slotIndexOrName

var obj = argument0;

// Determine if a name was given or a slot index.
var name = "";
var slotIndex = noone;
if is_string(argument1)
	name = argument1;
else
	slotIndex = argument1;

with (obj) {
	var actionCount = array_length_1d(_practionActions);

	if slotIndex != noone {
		// A slot index was given.  So stop the action in that slot.
		_practionActions[slotIndex] = noone;
	}
	else {
		// A name was given so stop all actions with that name.
		for (var i = 0; i < actionCount; i++) {
			var action = _practionActions[i];
			if action != noone and action[0] == name {
				_practionActions[i] = noone;
				_practionPlayingActionsCount--;
			}
		}
	}

	// Set the instance's PRAction status to stopped if no actions are running.
	for (var i = 0; i < actionCount; i++) {
		if _practionActions[i] != noone { return; }
	}

	_practionStatus = PRActionStatusStopped;
	_practionPlayingActionsCount = 0;
	_practionActions = array_create(2, noone);
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStopAll
/// @description Stops all the actions running for the given object.
/// @arg obj

var obj = argument0;

with (obj) {
	var actionCount = array_length_1d(_practionActions);
	for (var i = 0; i < actionCount; i++) {
		_practionActions[i] = noone;
	}

	_practionStatus = PRActionStatusStopped;
	_practionPlayingActionsCount = 0;
	_practionActions = array_create(2, noone);
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionPause
/// @description Pauses currently running actions for the given object.
/// @arg obj

var obj = argument0;

with (obj) {
	if _practionStatus == PRActionStatusPlaying
		_practionStatus = PRActionStatusPaused;
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionResume
/// @description Resume actions after being paused for the given object.
/// @arg obj

var obj = argument0;

with (obj) {
	if _practionStatus == PRActionStatusPaused
		_practionStatus = PRActionStatusPlaying;
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStatus
/// @description Returns the current status of the PRAction engine for the given object.
/// @arg obj
gml_pragma("forceinline");
return argument0._practionStatus;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionIsPlaying
/// @description Returns whether or not the action with the given name or slot index is playing.
/// @arg obj
/// @arg slotIndexOrName

var obj = argument0;

// Determine if a name was given or a slot index.
var name = "";
var slotIndex = noone;
if is_string(argument1)
	name = argument1;
else
	slotIndex = argument1;

with (obj) {
	if slotIndex != noone {
		// A slot index was given.  So return true if playing, else false.
		return (_practionActions[slotIndex] != noone);
	}
	else {
		// A name was given so check if any action with that name is playing.
		var actionCount = array_length_1d(_practionActions);
		for (var i = 0; i < actionCount; i++) {
			var action = _practionActions[i];
			if action != noone and action[0] == name { return true; }
		}

		return false;
	}
}










// **********************************************************************************************
// ADDITIONAL FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSetEase
/// @description Set the given action's ease function.
/// @arg action
/// @arg easeId

var action = argument0;
var easeId = argument1;

if action[1] == PRActionTypeSequence or action[1] == PRActionTypeGroup or action[1] == PRActionTypeRepeater or action[13] == 0 return;

switch (easeId) {
	case PRActionEaseIdLinear:
		action[@ 2] = asset_get_index("PRActionEaseLinear");
		break;
	case PRActionEaseIdQuadraticIn:
		action[@ 2] = asset_get_index("PRActionEaseQuadraticIn");
		break;
	case PRActionEaseIdQuadraticOut:
		action[@ 2] = asset_get_index("PRActionEaseQuadraticOut");
		break;
	case PRActionEaseIdQuadraticInOut:
		action[@ 2] = asset_get_index("PRActionEaseQuadraticInOut");
		break;
	case PRActionEaseIdCubicIn:
		action[@ 2] = asset_get_index("PRActionEaseCubicIn");
		break;
	case PRActionEaseIdCubicOut:
		action[@ 2] = asset_get_index("PRActionEaseCubicOut");
		break;
	case PRActionEaseIdCubicInOut:
		action[@ 2] = asset_get_index("PRActionEaseCubicInOut");
		break;
	case PRActionEaseIdQuarticIn:
		action[@ 2] = asset_get_index("PRActionEaseQuarticIn");
		break;
	case PRActionEaseIdQuarticOut:
		action[@ 2] = asset_get_index("PRActionEaseQuarticOut");
		break;
	case PRActionEaseIdQuarticInOut:
		action[@ 2] = asset_get_index("PRActionEaseQuarticInOut");
		break;
	case PRActionEaseIdQuinticIn:
		action[@ 2] = asset_get_index("PRActionEaseQuinticIn");
		break;
	case PRActionEaseIdQuinticOut:
		action[@ 2] = asset_get_index("PRActionEaseQuinticOut");
		break;
	case PRActionEaseIdQuinticInOut:
		action[@ 2] = asset_get_index("PRActionEaseQuinticInOut");
		break;
	case PRActionEaseIdSinusoidalIn:
		action[@ 2] = asset_get_index("PRActionEaseSinusoidalIn");
		break;
	case PRActionEaseIdSinusoidalOut:
		action[@ 2] = asset_get_index("PRActionEaseSinusoidalOut");
		break;
	case PRActionEaseIdSinusoidalInOut:
		action[@ 2] = asset_get_index("PRActionEaseSinusoidalInOut");
		break;
	case PRActionEaseIdExponentialIn:
		action[@ 2] = asset_get_index("PRActionEaseExponentialIn");
		break;
	case PRActionEaseIdExponentialOut:
		action[@ 2] = asset_get_index("PRActionEaseExponentialOut");
		break;
	case PRActionEaseIdExponentialInOut:
		action[@ 2] = asset_get_index("PRActionEaseExponentialInOut");
		break;
	case PRActionEaseIdCircularIn:
		action[@ 2] = asset_get_index("PRActionEaseCircularIn");
		break;
	case PRActionEaseIdCircularOut:
		action[@ 2] = asset_get_index("PRActionEaseCircularOut");
		break;
	case PRActionEaseIdCircularInOut:
		action[@ 2] = asset_get_index("PRActionEaseCircularInOut");
		break;
	case PRActionEaseIdBackIn:
		// Set the default data1 value if the previous ease id was not a back function.
		if action[2] != PRActionEaseIdBackIn and action[2] != PRActionEaseIdBackOut and action[2] != PRActionEaseIdBackInOut
			action[@ 14] = 1;
		action[@ 2] = asset_get_index("PRActionEaseBackIn");
		break;
	case PRActionEaseIdBackOut:
		// Set the default data1 value if the previous ease id was not a back function.
		if action[2] != PRActionEaseIdBackIn and action[2] != PRActionEaseIdBackOut and action[2] != PRActionEaseIdBackInOut
			action[@ 14] = 1;
		action[@ 2] = asset_get_index("PRActionEaseBackOut");
		break;
	case PRActionEaseIdBackInOut:
		// Set the default data1 value if the previous ease id was not a back function.
		if action[2] != PRActionEaseIdBackIn and action[2] != PRActionEaseIdBackOut and action[2] != PRActionEaseIdBackInOut
			action[@ 14] = 1;
		action[@ 2] = asset_get_index("PRActionEaseBackInOut");
		break;
	default:
		show_error("Undefined easeId encountered: " + string(easeId), true);
		break;
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSetData1
/// @description Set the given action's data 1 property.  Affects certain easing types.
/// @arg action
/// @arg data1

gml_pragma("forceinline");
argument0[@ 14] = argument1;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSetData2
/// @description Set the given action's data 2 property.  Affects certain actions.
/// @arg action
/// @arg data2

gml_pragma("forceinline");
argument0[@ 15] = argument1;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionPlayCount
/// @description Returns the number of currently playing actions for the given object.  Includes paused actions.
/// @arg obj
gml_pragma("forceinline");
return argument0._practionPlayingActionsCount;










// **********************************************************************************************
// STANDARD ACTION CREATION FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define _PRActionCreateBlankAction
/// @description Create a new uninitialized action.  (Internal use only.)
/// @arg easeId
/// @arg durationSecs

var easeId = argument0;
var durationSecs = argument1;

var durationInSteps = ceil(durationSecs * game_get_speed(gamespeed_fps));

// New array to keep track of values.
var newActionArray = array_create(_PRActionActionSize);
newActionArray[0]  = "";                           // Action name
newActionArray[1]  = noone;                        // Action type
newActionArray[2]  = noone;                        // Ease function script
newActionArray[3]  = noone;                        // Original action
newActionArray[4]  = 0;                            // Function specific value 1
newActionArray[5]  = 0;                            // Number of values
newActionArray[6]  = 0;                            // Start value 1
newActionArray[7]  = 0;                            // Start value 2
newActionArray[8]  = 0;                            // Destination value 1
newActionArray[9]  = 0;                            // Destination value 2
newActionArray[10] = 0;                            // Delta change for value 1
newActionArray[11] = 0;                            // Delta change for value 2
newActionArray[12] = 0;                            // Current step
newActionArray[13] = durationInSteps;              // Total steps
newActionArray[14] = 0;                            // Data 1 (Easing tweaker)
newActionArray[15] = 0;                            // Data 2 (Function tweaker)
newActionArray[16] = 0;                            // Storage 1
newActionArray[17] = 0;                            // Storage 2
newActionArray[18] = 0;                            // Action specific value 2

// Determine the ease function script to use.
if easeId != noone PRActionSetEase(newActionArray, easeId);

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomVarTo
/// @description Create an action that updates the given variable (real number) to the given value over time.
/// @arg varName
/// @arg toValue
/// @arg easeId
/// @arg durationSecs

var varName = argument0;
var toValue = argument1;
var easeId = argument2;
var durationSecs = argument3;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomVarTo;
newActionArray[5]  = 1;
newActionArray[8]  = toValue;
newActionArray[4]  = varName;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomVarBy
/// @description Create an action that updates the given variable (real number) by the given value over time.
/// @arg varName
/// @arg byValue
/// @arg easeId
/// @arg durationSecs

var varName = argument0;
var byValue = argument1;
var easeId = argument2;
var durationSecs = argument3;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomVarBy;
newActionArray[5]  = 1;
newActionArray[8]  = byValue;
newActionArray[4]  = varName;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomColorVarTo
/// @description Create an action that updates the given instance variable (color type) to the given color over time.
/// @arg varName
/// @arg toColor
/// @arg easeId
/// @arg durationSecs

var varName = argument0;
var toColor = argument1;
var easeId = argument2;
var durationSecs = argument3;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomColorVarTo;
newActionArray[5]  = 1;
newActionArray[8]  = toColor;
newActionArray[4]  = varName;
newActionArray[10] = array_create(3, 0); // To store individual color component deltas, which can include negative values.

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomColorVarBy
/// @description Create an action that updates the given instance variable (color type) by the given color deltas over time.
/// @arg varName
/// @arg byRed
/// @arg byGreen
/// @arg byBlue
/// @arg easeId
/// @arg durationSecs

var varName = argument0;
var byRed = argument1;
var byGreen = argument2;
var byBlue = argument3;
var easeId = argument4;
var durationSecs = argument5;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomColorVarBy;
newActionArray[5]  = 1;
newActionArray[8]  = [byRed, byGreen, byBlue];
newActionArray[4]  = varName;
newActionArray[10] = array_create(3, 0); // To store individual color component deltas, which can include negative values.
newActionArray[15] = true; // Limits dest colors to the range 0 to 255.

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomScript1
/// @description Create an action that calls a custom script for each frame update.  Given script must receive 1 numeric argument.
/// @arg scriptId
/// @arg fromValue
/// @arg toValue
/// @arg easeId
/// @arg durationSecs

var scriptId = argument0;
var fromValue = argument1;
var toValue = argument2;
var easeId = argument3;
var durationSecs = argument4;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomScript1;
newActionArray[5]  = 1;
newActionArray[6]  = fromValue;
newActionArray[8]  = toValue;
newActionArray[4]  = scriptId;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomScript2
/// @description Create an action that calls a custom script for each frame update.  Given script must receive 2 numeric arguments.
/// @arg scriptId
/// @arg fromValue1
/// @arg fromValue2
/// @arg toValue1
/// @arg toValue2
/// @arg easeId
/// @arg durationSecs

var scriptId = argument0;
var fromValue1 = argument1;
var fromValue2 = argument2;
var toValue1 = argument3;
var toValue2 = argument4;
var easeId = argument5;
var durationSecs = argument6;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomScript2;
newActionArray[5]  = 2;
newActionArray[6]  = fromValue1;
newActionArray[7]  = fromValue2;
newActionArray[8]  = toValue1;
newActionArray[9]  = toValue2;
newActionArray[4]  = scriptId;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionCustomColorScript
/// @description Create an action that calls a custom script for each frame update.  Given script must receive 1 color type argument.
/// @arg scriptId
/// @arg fromColor
/// @arg toColor
/// @arg easeId
/// @arg durationSecs

var scriptId = argument0;
var fromColor = argument1;
var toColor = argument2;
var easeId = argument3;
var durationSecs = argument4;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeCustomColorScript;
newActionArray[5]  = 1;
newActionArray[6]  = fromColor;
newActionArray[8]  = toColor;
newActionArray[4]  = scriptId;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveTo
/// @description Create an action that moves an object's x and y coordinates to the given values.
/// @arg moveToX
/// @arg moveToY
/// @arg easeId
/// @arg durationSecs

var moveToX = argument0;
var moveToY = argument1;
var easeId = argument2;
var durationSecs = argument3;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveTo;
newActionArray[5]  = 2;
newActionArray[8]  = moveToX;
newActionArray[9]  = moveToY;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveBy
/// @description Create an action that moves an object's x and y coordinates by the given values.
/// @arg moveByX
/// @arg moveByY
/// @arg easeId
/// @arg durationSecs

var moveByX = argument0;
var moveByY = argument1;
var easeId = argument2;
var durationSecs = argument3;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveBy;
newActionArray[5]  = 2;
newActionArray[8]  = moveByX;
newActionArray[9]  = moveByY;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveXTo
/// @description Create an action that moves an object's x coordinate to the given value.
/// @arg moveToX
/// @arg easeId
/// @arg durationSecs

var moveToX = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveXTo;
newActionArray[5]  = 1;
newActionArray[8]  = moveToX;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveXBy
/// @description Create an action that moves an object's x coordinate by the given value.
/// @arg moveByX
/// @arg easeId
/// @arg durationSecs

var moveByX = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveXBy;
newActionArray[5]  = 1;
newActionArray[8]  = moveByX;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveYTo
/// @description Create an action that moves an object's y coordinate to the given value.
/// @arg moveToY
/// @arg easeId
/// @arg durationSecs

var moveToY = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveYTo;
newActionArray[5]  = 1;
newActionArray[8]  = moveToY;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionMoveYBy
/// @description Create an action that moves an object's y coordinate by the given value.
/// @arg moveByY
/// @arg easeId
/// @arg durationSecs

var moveByY = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeMoveYBy;
newActionArray[5]  = 1;
newActionArray[8]  = moveByY;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleTo
/// @description Create an action that scales object's X and Y dimensions to the given value.
/// @arg scaleTo
/// @arg easeId
/// @arg durationSecs

var scaleTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleTo;
newActionArray[5]  = 2;
newActionArray[8]  = scaleTo;
newActionArray[9]  = scaleTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleBy
/// @description Create an action that scales object's X and Y dimensions by the given value.
/// @arg scaleBy
/// @arg easeId
/// @arg durationSecs

var scaleBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleBy;
newActionArray[5]  = 2;
newActionArray[8]  = scaleBy;
newActionArray[9]  = scaleBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleXTo
/// @description Create an action that scales object's X dimension to the given value.
/// @arg scaleTo
/// @arg easeId
/// @arg durationSecs

var scaleTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleXTo;
newActionArray[5]  = 1;
newActionArray[8]  = scaleTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleXBy
/// @description Create an action that scales object's X dimension by the given value.
/// @arg scaleBy
/// @arg easeId
/// @arg durationSecs

var scaleBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleXBy;
newActionArray[5]  = 1;
newActionArray[8]  = scaleBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleYTo
/// @description Create an action that scales object's Y dimension to the given value.
/// @arg scaleTo
/// @arg easeId
/// @arg durationSecs

var scaleTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleYTo;
newActionArray[5]  = 1;
newActionArray[8]  = scaleTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionScaleYBy
/// @description Create an action that scales object's Y dimension by the given value.
/// @arg scaleBy
/// @arg easeId
/// @arg durationSecs

var scaleBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeScaleYBy;
newActionArray[5]  = 1;
newActionArray[8]  = scaleBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionAlphaTo
/// @description Create an action that changes the object's alpha value to the given value.
/// @arg alphaTo
/// @arg easeId
/// @arg durationSecs

var alphaTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeAlphaTo;
newActionArray[5]  = 1;
newActionArray[8]  = alphaTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionAlphaBy
/// @description Create an action that changes the object's alpha value by the given value.
/// @arg alphaBy
/// @arg easeId
/// @arg durationSecs

var alphaBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeAlphaBy;
newActionArray[5]  = 1;
newActionArray[8]  = alphaBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionBlendTo
/// @description Create an action that changes the object's image blend color to the given color.
/// @arg blendToColor
/// @arg easeId
/// @arg durationSecs

var blendToColor = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeBlendTo;
newActionArray[5]  = 1;
newActionArray[8]  = blendToColor;
newActionArray[10] = array_create(3, 0); // To store individual color component deltas, which can include negative values.

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionBlendBy
/// @description Create an action that changes the object's image blend color by the given color component values.
/// @arg byRed
/// @arg byGreen
/// @arg byBlue
/// @arg easeId
/// @arg durationSecs

var byRed = argument0;
var byGreen = argument1;
var byBlue = argument2;
var easeId = argument3;
var durationSecs = argument4;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeBlendBy;
newActionArray[5]  = 1;
newActionArray[8]  = [byRed, byGreen, byBlue];
newActionArray[15] = true; // Limits dest colors to the range 0 to 255.

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRotateTo
/// @description Create an action that rotates the object to the given value.
/// @arg rotateTo
/// @arg easeId
/// @arg durationSecs

var rotateTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeRotateTo;
newActionArray[5]  = 1;
newActionArray[8]  = rotateTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRotateBy
/// @description Create an action that rotates the object by the given value.
/// @arg rotateBy
/// @arg easeId
/// @arg durationSecs

var rotateBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeRotateBy;
newActionArray[5]  = 1;
newActionArray[8]  = rotateBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionImageSpeedTo
/// @description Create an action that changes the object's image speed to the given value.
/// @arg imageSpeedTo
/// @arg easeId
/// @arg durationSecs

var imageSpeedTo = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeImageSpeedTo;
newActionArray[5]  = 1;
newActionArray[8]  = imageSpeedTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionImageSpeedBy
/// @description Create an action that changes the object's image speed by the given value.
/// @arg imageSpeedBy
/// @arg easeId
/// @arg durationSecs

var imageSpeedBy = argument0;
var easeId = argument1;
var durationSecs = argument2;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(easeId, durationSecs);
newActionArray[1]  = PRActionTypeImageSpeedBy;
newActionArray[5]  = 1;
newActionArray[8]  = imageSpeedBy;

return newActionArray;










// **********************************************************************************************
// CONTAINER ACTION CREATION FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSequence
/// @description Create an action that plays the given sequence of actions one after the other.
/// @arg action1,action2,action3,...

var actions = array_create(argument_count, noone);

// Copy arguments into the actions array.
for (var i = 0; i < argument_count; i++) {
	actions[i] = argument[i];
}

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeSequence;
newActionArray[18] = actions;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSequenceArr
/// @description Create an action that plays the given sequence of actions one after the other.
/// @arg actionArray

var actionArray = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeSequence;
newActionArray[18] = actionArray;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionGroup
/// @description Create an action that plays the given group of actions simultaneously.
/// @arg action1,action2,action3,...

var actions = array_create(argument_count, noone);

// Copy arguments into the actions array.
for (var i = 0; i < argument_count; i++) {
	actions[i] = argument[i];
}

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeGroup;
newActionArray[4]  = array_create(argument_count, false);
newActionArray[18] = actions;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRepeat
/// @description Create an action that repeats the given action a given number of times.
/// @arg action
/// @arg repeatCount

var action = argument0;
var repeatCount = argument1;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeRepeater;
newActionArray[4] = repeatCount;
newActionArray[16] = repeatCount;
newActionArray[18] = [action];

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRepeatForever
/// @description Create an action that repeats the given action an unlimited number of times.
/// @arg action

var action = argument0;
return PRActionRepeat(action, -1);










// **********************************************************************************************
// INSTANT ACTION CREATION FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionWait
/// @description Create an action that does nothing for the given duration.
/// @arg durationSecs

var durationSecs = argument0;
if durationSecs < 0 durationSecs = 0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, durationSecs);
newActionArray[1]  = PRActionTypeWait;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRunScript
/// @description Create an action that runs the given script passing it the given arguments (8 max.)
/// @arg scriptId
/// @arg arg1,arg2,arg3,...

var scriptId = argument[0];

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeRunScript;
newActionArray[4]  = scriptId;

newActionArray[5]  = argument_count - 1;
if argument_count >= 2 newActionArray[6] = argument[1];
if argument_count >= 3 newActionArray[7] = argument[2];
if argument_count >= 4 newActionArray[8] = argument[3];
if argument_count >= 5 newActionArray[9] = argument[4];
if argument_count >= 6 newActionArray[10] = argument[5];
if argument_count >= 7 newActionArray[11] = argument[6];
if argument_count >= 8 newActionArray[16] = argument[7];
if argument_count >= 9 newActionArray[17] = argument[8];

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionRunUserEvent
/// @description Create an action that runs the given user event.
/// @arg eventNumber

var eventNumber = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeRunUserEvent;
newActionArray[4]  = eventNumber;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionPlaySound
/// @description Create an action that plays the given sound using the given parameters.
/// @arg soundId
/// @arg priority
/// @arg loops

var soundId = argument0;
var priority = argument1;
var loops = argument2;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypePlaySound;
newActionArray[4]  = soundId;
newActionArray[6]  = priority;
newActionArray[7]  = loops;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStopSound
/// @description Create an action that stops the given sound.
/// @arg soundId

var soundId = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeStopSound;
newActionArray[4]  = soundId;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStopAllSounds
/// @description Create an action that stops all sounds currently playing.

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeStopAllSounds;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionHide
/// @description Create an action that makes the object invisble.

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeHide;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionUnhide
/// @description Create an action that makes the object visble.

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeUnhide;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSpriteIndex
/// @description Create an action that changes the sprite index and/or the image index.  (Pass noone if no change desired.)
/// @arg spriteIndex
/// @arg imageIndex

var spriteIndex = argument0;
var imageIndex = argument1;

if spriteIndex < 0 spriteIndex = noone;
if imageIndex < 0 imageIndex = noone;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeSpriteIndex;
newActionArray[6]  = spriteIndex;
newActionArray[7]  = imageIndex;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionDepthTo
/// @description Create an action that changes the object's depth to the given value.
/// @arg depthTo

var depthTo = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeDepthTo;
newActionArray[5]  = 1;
newActionArray[8]  = depthTo;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionDepthBy
/// @description Create an action that changes the object's depth by the given value.
/// @arg depthBy

var depthBy = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeDepthBy;
newActionArray[5]  = 1;
newActionArray[8]  = depthBy;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionChangeLayer
/// @description Create an action that changes the object's layer.
/// @arg layerName

var layerName = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeChangeLayer;
newActionArray[4]  = layerName;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionPlayAction
/// @description Create an action that triggers another action to play in the context of the given object.
/// @arg obj
/// @arg action

var obj = argument0;
var action = argument1;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypePlayAction;
newActionArray[4]  = obj;
newActionArray[18] = action;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStopAction
/// @description Create an action that stops an object's playing action matching the given slotIndex or name.
/// @arg obj
/// @arg slotIndexOrName

var obj = argument0;
var slotIndexOrName = argument1;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeStopAction;
newActionArray[4]  = obj;
newActionArray[18] = slotIndexOrName;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionStopAllAction
/// @description Create an action that stops all of an object's playing actions.
/// @arg obj

var obj = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeStopAllAction;
newActionArray[4]  = obj;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionDestroyObject
/// @description Create an action that will destroy the object.
/// @arg obj

var obj = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeDestroyObject;
newActionArray[4]  = obj;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionGotoRoom
/// @description Create an action that will run the given room.
/// @arg room

var obj = argument0;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeGotoRoom;
newActionArray[4]  = obj;

return newActionArray;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionSetVar
/// @description Create an action that instantly sets an object's variable to the given value.
/// @arg variableName
/// @arg value

var variableName = argument0;
var value = argument1;

// New array to keep track of values.
var newActionArray = _PRActionCreateBlankAction(noone, 0);
newActionArray[1]  = PRActionTypeSetVar;
newActionArray[4]  = variableName;
newActionArray[5]  = 1;
newActionArray[8]  = value;

return newActionArray;










// **********************************************************************************************
// COMPOUND ACTION CREATION FUNCTIONS
// **********************************************************************************************

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQFloat
/// @description Create a compound action that simulates a floating motion.
/// @arg hTravel
/// @arg hDurationSecs
/// @arg vTravel
/// @arg vDurationSecs

var hTravel = argument0;
var hDurationSecs = argument1;
var vTravel = argument2;
var vDurationSecs = argument3;

var hFloat = noone;
var vFloat = noone;

if hTravel != 0 {
	var h1 = PRActionMoveBy(-(hTravel/2), 0, PRActionEaseIdSinusoidalInOut, (hDurationSecs / 2));
	var h2 = PRActionMoveBy(hTravel, 0, PRActionEaseIdSinusoidalInOut, hDurationSecs);
	var h3 = PRActionMoveBy(-hTravel, 0, PRActionEaseIdSinusoidalInOut, hDurationSecs);
	var hSeq = PRActionSequence(h2, h3);
	var hSeqRep = PRActionRepeatForever(hSeq);
	hFloat = PRActionSequence(h1, hSeqRep);
}

if vTravel != 0 {
	var v1 = PRActionMoveBy(0, -(vTravel/2), PRActionEaseIdSinusoidalInOut, (vDurationSecs / 2));
	var v2 = PRActionMoveBy(0, vTravel, PRActionEaseIdSinusoidalInOut, vDurationSecs);
	var v3 = PRActionMoveBy(0, -vTravel, PRActionEaseIdSinusoidalInOut, vDurationSecs);
	var vSeq = PRActionSequence(v2, v3);
	var vSeqRep = PRActionRepeatForever(vSeq);
	vFloat = PRActionSequence(v1, vSeqRep);
}

if hFloat != noone and vFloat != noone
	return PRActionGroup(hFloat, vFloat);
else if hFloat != noone
	return hFloat;
else if vFloat != noone
	return vFloat;

return noone;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQShake
/// @description Create a compound action that simulates horizontal or vertical shaking.
/// @arg isHorz
/// @arg travel
/// @arg shakeCount
/// @arg durationPerShakeSecs

var isHorz = argument0;
var travel = argument1;
var shakeCount = argument2;
var durationPerShakeSecs = argument3;

if durationPerShakeSecs <= 0 durationPerShakeSecs = 0.15;

var shake = noone;
if isHorz {
	var h1 = PRActionMoveBy(-(travel/2), 0, PRActionEaseIdQuadraticIn, (durationPerShakeSecs / 4));
	var h2 = PRActionMoveBy(travel, 0, PRActionEaseIdCubicInOut, (durationPerShakeSecs / 2));
	var h3 = PRActionMoveBy(-travel, 0, PRActionEaseIdCubicInOut, (durationPerShakeSecs / 2));
	var h4 = PRActionMoveBy(-(travel/2), 0, PRActionEaseIdQuadraticOut, (durationPerShakeSecs / 4));
	var hSeq = PRActionSequence(h2, h3);

	var hSeqRep = noone;
	if shakeCount <= 0 {
		hSeqRep = PRActionRepeatForever(hSeq);
		return PRActionSequence(h1, hSeqRep);
	}
	else {
		hSeqRep = PRActionRepeat(hSeq, shakeCount - 1);
		return PRActionSequence(h1, hSeqRep, h2, h4);
	}
}
else {
	var v1 = PRActionMoveBy(0, -(travel/2), PRActionEaseIdQuadraticIn, (durationPerShakeSecs / 4));
	var v2 = PRActionMoveBy(0, travel, PRActionEaseIdCubicInOut, (durationPerShakeSecs / 2));
	var v3 = PRActionMoveBy(0, -travel, PRActionEaseIdCubicInOut, (durationPerShakeSecs / 2));
	var vSeq = PRActionSequence(v2, v3);

	var vSeqRep = noone;
	if shakeCount <= 0 {
		vSeqRep = PRActionRepeatForever(vSeq);
		return PRActionSequence(v1, vSeqRep);
	}
	else {
		var v4 = PRActionMoveBy(0, -(travel/2), PRActionEaseIdQuadraticOut, (durationPerShakeSecs / 4));
		vSeqRep = PRActionRepeat(vSeq, shakeCount - 1);
		return PRActionSequence(v1, vSeqRep, v2, v4);
	}
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQSlideFade
/// @description Create a compound action that moves an object by the given amount while fading it in or out.
/// @arg moveXby
/// @arg moveYby
/// @arg alphaTo
/// @arg easeId
/// @arg durationSecs

var moveXby = argument0;
var moveYby = argument1;
var alphaTo = argument2;
var easeId = argument3;
var durationSecs = argument4;

var slideAction = PRActionMoveBy(moveXby, moveYby, easeId, durationSecs)
var fadeAction = PRActionAlphaTo(alphaTo, easeId, durationSecs)
var slideFadeAction = PRActionGroup(slideAction, fadeAction)
return slideFadeAction

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQBlink
/// @description Create a compound action that alternates between visible and invisible.
/// @arg startVisible
/// @arg visibleDurationSecs
/// @arg invisibleDurationSecs

var startVisible = argument0;
var visibleDurationSecs = argument1;
var invisibleDurationSecs = argument2;

var visibleAction = PRActionUnhide();
var invisibleAction = PRActionHide();
var visibleWait = PRActionWait(visibleDurationSecs);
var invisibleWait = PRActionWait(invisibleDurationSecs);

var seq = noone;
if startVisible
	seq = PRActionSequence(visibleAction, visibleWait, invisibleAction, invisibleWait);
else
	seq = PRActionSequence(invisibleAction, invisibleWait, visibleAction, visibleWait);

return PRActionRepeatForever(seq);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQAlphaFlash
/// @description Create a compound action that fades the object in and out in succession.
/// @arg startVisible
/// @arg fadeOutDurationSecs
/// @arg fadeOutDelaySecs
/// @arg fadeInDurationSecs
/// @arg fadeInDelaySecs
/// @arg easeId

var startVisible = argument0;
var fadeOutDurationSecs = argument1;
var fadeOutDelaySecs = argument2;
var fadeInDurationSecs = argument3;
var fadeInDelaySecs = argument4;
var easeId = argument5;

var fadeOutAction = PRActionAlphaTo(0, easeId, fadeOutDurationSecs);
var fadeOutDelayAction = PRActionWait(fadeOutDelaySecs);
var fadeInAction = PRActionAlphaTo(1, easeId, fadeInDurationSecs);
var fadeInDelayAction = PRActionWait(fadeInDelaySecs);

var seq = noone;
if startVisible
	seq = PRActionSequence(fadeOutAction, fadeOutDelayAction, fadeInAction, fadeInDelayAction);
else
	seq = PRActionSequence(fadeInAction, fadeInDelayAction, fadeOutAction, fadeOutDelayAction);

return PRActionRepeatForever(seq);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQBlendFlash
/// @description Create a compound action that transitions the image blend from one color to another in succession.
/// @arg color1
/// @arg color2
/// @arg fade1DurationSecs
/// @arg fade1DelaySecs
/// @arg fade2DurationSecs
/// @arg fade2DelaySecs
/// @arg easeId

var color1 = argument0;
var color2 = argument1;
var fade1DurationSecs = argument2;
var fade1DelaySecs = argument3;
var fade2DurationSecs = argument4;
var fade2DelaySecs = argument5;
var easeId = argument6;

var setColor1 = PRActionBlendTo(color1, easeId, 0);
var fade1 = PRActionBlendTo(color2, easeId, fade1DurationSecs);
var fade1DelayAction = PRActionWait(fade1DelaySecs);
var fade2 = PRActionBlendTo(color1, easeId, fade2DurationSecs);
var fade2DelayAction = PRActionWait(fade2DelaySecs);

var seq = PRActionSequence(fade1, fade1DelayAction, fade2, fade2DelayAction);
return PRActionSequence(setColor1, PRActionRepeatForever(seq));

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQFlipXY
/// @description Create a compound action that scales the object along the X and/or Y axes from 1 to -1 and back to simulate flipping.
/// @arg xFlipDurationSecs
/// @arg yFlipDurationSecs
/// @arg repeatCount
/// @arg easeId

var xFlipDurationSecs = argument0;
var yFlipDurationSecs = argument1;
var repeatCount = argument2;
var easeId = argument3;

var xFlipAction = noone;
var yFlipAction = noone;

if xFlipDurationSecs > 0 {
	var duration1 = xFlipDurationSecs / 2;
	var duration2 = xFlipDurationSecs - duration1;
	var scaleDown = PRActionScaleXTo(-1, easeId, duration1);
	var scaleUp = PRActionScaleXTo(1, easeId, duration2);

	if repeatCount <= 0
		xFlipAction = PRActionRepeatForever(PRActionSequence(scaleDown, scaleUp));
	else
		xFlipAction = PRActionRepeat(PRActionSequence(scaleDown, scaleUp), repeatCount);
}

if yFlipDurationSecs > 0 {
	var duration1 = yFlipDurationSecs / 2;
	var duration2 = yFlipDurationSecs - duration1;
	var scaleDown = PRActionScaleYTo(-1, easeId, duration1);
	var scaleUp = PRActionScaleYTo(1, easeId, duration2);

	if repeatCount <= 0
		yFlipAction = PRActionRepeatForever(PRActionSequence(scaleDown, scaleUp));
	else
		yFlipAction = PRActionRepeat(PRActionSequence(scaleDown, scaleUp), repeatCount);
}

if xFlipAction == noone and yFlipAction == noone return noone;
if xFlipAction != noone and yFlipAction == noone return xFlipAction;
if xFlipAction == noone and yFlipAction != noone return yFlipAction;
if xFlipAction != noone and yFlipAction != noone return PRActionGroup(xFlipAction, yFlipAction);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQWobble
/// @description Create a compound action that wobbles the object using back and forth rotation.
/// @arg travelDegrees
/// @arg repeatCount
/// @arg easeId
/// @arg durationPerWobbleSecs

var travelDegrees = argument0;
var repeatCount = argument1;
var easeId = argument2;
var durationPerWobbleSecs = argument3;

var w1 = PRActionRotateBy((travelDegrees/2), easeId, (durationPerWobbleSecs / 4));
var w2 = PRActionRotateBy(-travelDegrees, easeId, (durationPerWobbleSecs / 2));
var w3 = PRActionRotateBy(+travelDegrees, easeId, (durationPerWobbleSecs / 2));
var wSeq = PRActionSequence(w2, w3);

var wSeqRep = noone;
if (repeatCount <= 0) {
	wSeqRep = PRActionRepeatForever(wSeq);
	return PRActionSequence(w1, wSeqRep);
}
else {
	var w4 = PRActionRotateBy(-(travelDegrees/2), easeId, (durationPerWobbleSecs / 4));
	wSeqRep = PRActionRepeat(wSeq, repeatCount - 1);
	return PRActionSequence(w1, wSeqRep, w2, w4);
}

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQBreathe
/// @description Create a compound action that simulates an object "breathing."
/// @arg sizeBy
/// @arg repeatCount
/// @arg easeId
/// @arg durationPerBreathSecs
/// @arg delaySecs

var sizeBy = argument0;
var repeatCount = argument1;
var easeId = argument2;
var durationPerBreathSecs = argument3;
var delaySecs = argument4;

var breathInDur = durationPerBreathSecs * 0.65;
var breathHoldDur = durationPerBreathSecs * 0.1;
var breathOutDur = durationPerBreathSecs - breathInDur - breathHoldDur;
var breathYDelay = durationPerBreathSecs * 0.1;

var scaleUpX = PRActionScaleXBy(sizeBy, easeId, breathInDur * .7);
var scaleDownX = PRActionScaleXBy(-sizeBy, easeId, breathOutDur * .7);
var scaleUpY = PRActionScaleYBy(sizeBy, easeId, breathInDur * 1.3);
var scaleDownY = PRActionScaleYBy(-sizeBy, easeId, breathOutDur * 1.3);

var breathInGroup = PRActionGroup(scaleUpX, scaleUpY);
var breathOutGroup = PRActionGroup(scaleDownX, scaleDownY);
var breathSeq = PRActionSequence(breathInGroup, PRActionWait(breathHoldDur), breathOutGroup, PRActionWait(delaySecs));

if repeatCount <= 0
	return PRActionRepeatForever(breathSeq);
else
	return PRActionRepeat(breathSeq, repeatCount);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQHeartbeat
/// @description Create a compound action that simulates a heartbeat (bump-bump).
/// @arg sizeBy
/// @arg repeatCount
/// @arg easeId
/// @arg durationPerBeatSecs
/// @arg delaySecs

var sizeBy = argument0;
var repeatCount = argument1;
var easeId = argument2;
var durationPerBeatSecs = argument3;
var delaySecs = argument4;

var scaleUp1 = PRActionScaleBy(sizeBy * 0.6, easeId, durationPerBeatSecs * 0.2);
var scaleDown1 = PRActionScaleBy(sizeBy * -0.2, easeId, durationPerBeatSecs * 0.05);
var scaleUp2 = PRActionScaleBy(sizeBy * 0.6, easeId, durationPerBeatSecs * 0.2);
var scaleDown2 = PRActionScaleBy(sizeBy * -1, easeId, durationPerBeatSecs * 0.55);

var beatSeq = PRActionSequence(scaleUp1, scaleDown1, scaleUp2, scaleDown2, PRActionWait(delaySecs));
if repeatCount <= 0
	return PRActionRepeatForever(beatSeq);
else
	return PRActionRepeat(beatSeq, repeatCount);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQBounce
/// @arg travel
/// @arg travelAngle
/// @arg repeatCount
/// @arg easeUpId
/// @arg easeDownId
/// @arg jumpDurationSecs

var travel = argument0;
var travelAngle = argument1;
var repeatCount = argument2;
var easeUpId = argument3;
var easeDownId = argument4;
var jumpDurationSecs = argument5;

var travelX = lengthdir_x(travel, travelAngle);
var travelY = lengthdir_y(travel, travelAngle);

var jumpUp = PRActionMoveBy(travelX, travelY, easeUpId, jumpDurationSecs / 2);
var jumpDown = PRActionMoveBy(-travelX, -travelY, easeDownId, jumpDurationSecs / 2);
var seq = PRActionSequence(jumpUp, jumpDown);

if repeatCount <= 0
	return PRActionRepeatForever(seq);
else
	return PRActionRepeat(seq, repeatCount);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQJumpBounce
/// @description Create a compound action that causes object to jump from current position at the given angle and come back down to a bouncing stop.
/// @arg travel
/// @arg travelAngle
/// @arg bounceLoss
/// @arg repeatCount
/// @arg easeUpId
/// @arg easeDownId
/// @arg jumpDurationSecs
/// @arg delaySecs

var travel = argument0;
var travelAngle = argument1;
var bounceLoss = abs(argument2);
var repeatCount = argument3;
var easeUpId = argument4;
var easeDownId = argument5;
var jumpDurationSecs = argument6;
var delaySecs = argument7;

if bounceLoss <= 0 or bounceLoss > 1 bounceLoss = 1;

var seqArr = array_create(1, noone);
var i = 0;
while (travel / argument0 > 0.1) {
	var travelX = lengthdir_x(travel, travelAngle);
	var travelY = lengthdir_y(travel, travelAngle);
	seqArr[i++] = PRActionMoveBy(travelX , travelY, easeUpId, jumpDurationSecs / 2);
	seqArr[i++] = PRActionMoveBy(-travelX , -travelY, easeDownId, jumpDurationSecs / 2);
	travel *= bounceLoss;
	jumpDurationSecs *= bounceLoss;
}
seqArr[i++] = PRActionWait(delaySecs);

var seq = PRActionSequenceArr(seqArr);
if repeatCount <= 0
	return PRActionRepeatForever(seq);
else
	return PRActionRepeat(seq, repeatCount);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQPopIn
/// @description Create a compound action that causes object to scale up to the given max from 0 before settling at normal size.
/// @arg sizeToMax
/// @arg sizeToNormal
/// @arg easeId
/// @arg durationSecs

var sizeToMax = argument0;
var sizeToNormal = argument1;
var easeId = argument2;
var durationSecs = argument3;

var scaleZero = PRActionScaleTo(0, easeId, 0);
var scaleUp = PRActionScaleTo(sizeToMax, easeId, durationSecs * 0.7);
var scaleDown = PRActionScaleTo(sizeToNormal, PRActionEaseIdCubicOut, durationSecs * 0.3);
return PRActionSequence(scaleZero, scaleUp, scaleDown);

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionQPopOut
/// @description Create a compound action that causes object to grow briefly and then disappear into the distance.
/// @arg sizeUpTo
/// @arg easeId
/// @arg durationSecs

var sizeUpTo = argument0;
var easeId = argument1;
var durationSecs = argument2;

var scaleUp = PRActionScaleTo(sizeUpTo, PRActionEaseIdCubicIn, durationSecs * 0.3);
var scaleDown = PRActionScaleTo(0, easeId, durationSecs * 0.7);
return PRActionSequence(scaleUp, scaleDown);










// **********************************************************************************************
// EASING EQUATION FUNCTIONS
// **********************************************************************************************

/* ============================================================
 * GML Easing Equations
 *
 * Open source under the BSD License.
 * Original coding by Robert Penner.  (Terms of use at end of this file.)
 * Translated to GML by Nelson Santos.
 *
 * Copyright © 2018 Prismatic Realms, Inc.
 * All rights reserved.
 * ========================================================
 */

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseLinear
/// @description Ease function - Linear
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return deltaValue * (currentTime / duration) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuadraticIn
/// @description Ease function - Quadratic In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return deltaValue * currentTime * currentTime + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuadraticOut
/// @description Ease function - Quadratic Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return -deltaValue * currentTime * (currentTime - 2) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuadraticInOut
/// @description Ease function - Quadratic In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if (currentTime < 1)
	return (deltaValue / 2) * currentTime * currentTime + startValue;

currentTime--;
return (-deltaValue / 2) * (currentTime * (currentTime - 2) - 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCubicIn
/// @description Ease function - Cubic In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return deltaValue * currentTime * currentTime * currentTime + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCubicOut
/// @description Ease function - Cubic Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
currentTime--;
return deltaValue * (currentTime * currentTime * currentTime + 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCubicInOut
/// @description Ease function - Cubic In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if (currentTime < 1)
	return (deltaValue / 2) * currentTime * currentTime * currentTime + startValue;

currentTime -= 2;
return (deltaValue / 2) * (currentTime * currentTime * currentTime + 2) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuarticIn
/// @description Ease function - Quartic In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return deltaValue * currentTime * currentTime * currentTime * currentTime + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuarticOut
/// @description Ease function - Quartic Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
currentTime--;
return -deltaValue * (currentTime * currentTime * currentTime * currentTime - 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuarticInOut
/// @description Ease function - Quartic In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if (currentTime < 1)
	return (deltaValue / 2) * currentTime * currentTime * currentTime * currentTime + startValue;

currentTime -= 2;
return (-deltaValue / 2) * (currentTime * currentTime * currentTime * currentTime - 2) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuinticIn
/// @description Ease function - Quintic In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return deltaValue * currentTime * currentTime * currentTime * currentTime * currentTime + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuinticOut
/// @description Ease function - Quintic Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
currentTime--;
return deltaValue * (currentTime * currentTime * currentTime * currentTime * currentTime + 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseQuinticInOut
/// @description Ease function - Quintic In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if (currentTime < 1)
	return (deltaValue / 2) * currentTime * currentTime * currentTime * currentTime * currentTime + startValue;

currentTime -= 2;
return (deltaValue / 2) * (currentTime * currentTime * currentTime * currentTime * currentTime + 2) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseSinusoidalIn
/// @description Ease function - Sinusoidal In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return -deltaValue * cos((currentTime / duration) * (pi / 2)) + deltaValue + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseSinusoidalOut
/// @description Ease function - Sinusoidal Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return deltaValue * sin((currentTime / duration) * (pi / 2)) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseSinusoidalInOut
/// @description Ease function - Sinusoidal In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return (-deltaValue / 2) * (cos(pi * currentTime / duration) - 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseExponentialIn
/// @description Ease function - Exponential In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return deltaValue * power(2, (10 * (currentTime / duration - 1))) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseExponentialOut
/// @description Ease function - Exponential Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

return deltaValue * (-power(2, (-10 * currentTime / duration)) + 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseExponentialInOut
/// @description Ease function - Exponential In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if currentTime < 1 { return (deltaValue / 2) * power(2, (10 * (currentTime - 1))) + startValue; }

currentTime--;
return (deltaValue / 2) * (-power(2, (-10 * currentTime)) + 2) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCircularIn
/// @description Ease function - Circular In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
return -deltaValue * (sqrt(1 - currentTime * currentTime) - 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCircularOut
/// @description Ease function - Circular Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= duration;
currentTime--;
return deltaValue * sqrt(1 - currentTime * currentTime) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseCircularInOut
/// @description Ease function - Circular In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var data1 = argument4;

currentTime /= (duration / 2);
if currentTime < 1 { return (-deltaValue / 2) * (sqrt(1 - currentTime * currentTime) - 1) + startValue; }

currentTime -= 2;
return (deltaValue / 2) * (sqrt(1 - currentTime * currentTime) + 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseBackIn
/// @description Ease function - Back In
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var multiplier = argument4;

var backAmount = 1.70158 * multiplier;

currentTime /= duration;
return deltaValue * currentTime * currentTime * ((backAmount + 1) * currentTime - backAmount) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseBackOut
/// @description Ease function - Back Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var multiplier = argument4;

var backAmount = 1.70158 * multiplier;

currentTime = currentTime / duration - 1;
return deltaValue * (currentTime * currentTime * ((backAmount + 1) * currentTime + backAmount) + 1) + startValue;

// ---------------------------------------------------------------------------------------------------------------------
#define PRActionEaseBackInOut
/// @description Ease function - Back In/Out
/// @arg currentTime
/// @arg startValue
/// @arg deltaValue
/// @arg duration
/// @arg data1

var currentTime = argument0;
var startValue = argument1;
var deltaValue = argument2;
var duration = argument3;
var multiplier = argument4;

var backAmount = 1.70158 * multiplier;

currentTime /= (duration / 2);
if currentTime < 1 { return  (deltaValue / 2) * (currentTime * currentTime * ((backAmount + 1) * currentTime - backAmount)) + startValue; }

currentTime -= 2;
return (deltaValue / 2) * (currentTime * currentTime * ((backAmount + 1) * currentTime + backAmount) + 2) + startValue;


// ---------------------------------------------------------------------------------------------------------------------
/* TERMS OF USE - EASING EQUATIONS
 *
 * Open source under the BSD License.
 *
 * Copyright © 2001 Robert Penner
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 *
 * Neither the name of the author nor the names of contributors may be used to endorse
 * or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
// ---------------------------------------------------------------------------------------------------------------------
