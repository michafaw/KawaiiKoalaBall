/// @description Insert description here
// You can write your code in this editor

event_inherited();

acceleration = 0.5
maxSpeed = 5

sandCloudOffset = [49, -7];
sandCloudInstance = instance_create_layer(0, 0, "Foreground_Instances", objSandCloud);
sandCloudInstance.visible = false;