extends PanelContainer
class_name MyMessage

# Called when the node enters the scene tree for the first time.
func _ready():
				pass # Replace with function body.


func build(user: String, content: String) -> void:
				$Container/User.set_text(user)
				$Container/Content.set_text(content)
