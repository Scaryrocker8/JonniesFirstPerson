@tool
@icon("res://addons/jonnies_first_person/resources/FootstepsBody3D.svg")
extends StaticBody3D
class_name FootstepsBody3D

# Add this script to any StaticBody3D to give it a footsteps name property!

var footsteps_type: String

func _ready() -> void:
	name = "FootstepsBody3D"
	editor_description = "Grab FootstepsResource name property from Player's footsteps_user_library"

func _set(property, value):
	if property == "footsteps_type":
		footsteps_type = value
		return true
	return false

func _get(property):
	if property == "footsteps_type":
		return footsteps_type
	return null

func _get_property_list():
	var properties: Array[Dictionary] = []
	var name_list: Array[String] = []
	
	var scene_root = EditorInterface.get_edited_scene_root()
	var player_node = _find_player_in_tree(scene_root)
	
	if player_node and "footsteps_user_library" in player_node:
		for resource in player_node.footsteps_user_library:
			if resource and resource.footsteps_name != "":
				name_list.append(resource.footsteps_name)
	
	var enum_string = ",".join(name_list)

	properties.append({
		"name": "footsteps_type",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": enum_string
	})
	
	return properties

func _find_player_in_tree(node: Node) -> Node:
	if not node: return null

	if node is Player: 
		return node
			
	for child in node.get_children():
		var found = _find_player_in_tree(child)
		if found: return found

	return null
