extends Node


func _ready() -> void:
	pass

func Stringify(obj) -> String:
	return str(obj) + "(" + type_string(typeof(obj)) + ")"

func GetIsScriptOfTypeRecursive(script : Script, classRef : Object):
	if script == classRef:
		return true
	elif script:
		var baseScript = script.get_base_script()
		if baseScript:
			return GetIsScriptOfTypeRecursive(baseScript, classRef)
		else:
			return false
	else:
		return false

func CompareScriptClass(node : Node, classRef : Object) -> bool:
	var nodeScript : Script = node.get_script()
	return GetIsScriptOfTypeRecursive(nodeScript, classRef) #nodeScript == classRef

func FindParentScriptOfClass(child : Node, classRef : Object) -> Node:
	var parent = child.get_parent()
	if (not parent): return null
	#print(Stringify(parent), ", ", Stringify(classRef), ": ", CompareScriptClass(parent, classRef))
	if (CompareScriptClass(parent, classRef)): return parent
	return FindParentScriptOfClass(parent, classRef)

func FindChildScriptOfClass(
		parent : Node,
		classRef : Object,
		includeInternal : bool = false
		#recursive : bool = false,
	) -> Node:
	
	for child in parent.get_children(includeInternal):
		if CompareScriptClass(child, classRef): return child
	
	return null
