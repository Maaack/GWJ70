extends Node3D

@export var second_camera : bool = false :
	set(value):
		second_camera = value
		if second_camera:
			$Camera3D.current = false
			$Camera3D2.current = true
		else:
			$Camera3D.current = true
			$Camera3D2.current = false
