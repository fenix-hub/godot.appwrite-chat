extends Control

var user: Dictionary = {
	id = "",
	email = "",
	session = ""
}

onready var message_scene:PackedScene = load("res://scn/message/message.tscn")
onready var my_message_scene:PackedScene = load("res://scn/my_message/my_message.tscn")

onready var email_txt: LineEdit = $Auth/PanelContainer/VBoxContainer/VBoxContainer3/VBoxContainer/Email
onready var name_txt: LineEdit = $Auth/PanelContainer/VBoxContainer/VBoxContainer3/VBoxContainer3/Name
onready var pwd_txt: LineEdit = $Auth/PanelContainer/VBoxContainer/VBoxContainer3/VBoxContainer2/Password

onready var msg_text: LineEdit = $Chat/PanelContainer/VBoxContainer/HBoxContainer/Text

onready var messages_container: VBoxContainer = $Chat/PanelContainer/VBoxContainer/Chat/Messages

var messages_collection: String = "617ddb5017842"

# Called when the node enters the scene tree for the first time.
func _ready():
	Appwrite.set_project("617d236ac3a98").set_endpoint("http://localhost:7000/v1")
	Appwrite.database.connect("listed_documents", self, "_on_listed_messages")
	Appwrite.database.connect("created_document", self, "_on_added_message")
	
	$Platform.set_text($Platform.get_text()%OS.get_name())
	$Chat.hide()
	$Auth.show()
	$COVER.hide()


func _on_Button_pressed():
	hide_error()
	$COVER.show()
	var create: TaskResponse = yield(Appwrite.account.create(email_txt.get_text(), pwd_txt.get_text()), "completed")
	var login: TaskResponse = yield(Appwrite.account.create_session(email_txt.get_text(), pwd_txt.get_text()), "completed")
	if not login.error.empty():
		show_error(login.error.message)
		return
	user.id = login.response.userId
	user.email = login.response.providerUid
	user.session = login.response["$id"]
	show_chat()


func show_chat():
	$Auth.hide()
	$Chat.show()
	Appwrite.realtime.connect("subscribed", self, "_on_subscribed")
	Appwrite.realtime.connect("received_updates", self, "_on_message_received")
	Appwrite.realtime.subscribe(["collections."+messages_collection+".documents"])
	Appwrite.database.list_documents(messages_collection)

func _on_subscribed():
	print("subscribed!")

func add_message(message: Dictionary):
	if message.user == user.email:
		var msg: MyMessage = my_message_scene.instance()
		msg.build(message.user, message.content)
		messages_container.add_child(msg)
	else:
		var msg: Message = message_scene.instance()
		msg.build(message.user, message.content)
		messages_container.add_child(msg)
	yield(get_tree(), "idle_frame")
	messages_container.get_parent().scroll_vertical = messages_container.rect_size.y

func _on_listed_messages(messages: Dictionary):
	$COVER.hide()
	print(messages)
	if not messages.has("documents"): return
	for message in messages.documents:
		add_message(message)


func _on_message_received(message: Dictionary):
	print(message)
	if message.type == "connected": return
	if message.data.event != "database.documents.create": return
	add_message(message.data.payload)

func show_error(error: String):
	$COVER.hide()
	$Auth/PanelContainer/VBoxContainer/VBoxContainer3/Error.set_text(error)
	$Auth/PanelContainer/VBoxContainer/VBoxContainer3/Error.show()

func hide_error():
	$Auth/PanelContainer/VBoxContainer/VBoxContainer3/Error.hide()

func _on_added_message(message: Dictionary):
	print("added message :", message)
#	var msg: MyMessage = my_message_scene.instance()
#	msg.build(message.user, message.content)
#	messages_container.add_child(msg)

func _on_SendBtn_pressed():
	var msg_data: Dictionary = { user = user.email, content = msg_text.get_text() }
	msg_text.clear()
	var add_message: TaskResponse = yield(Appwrite.database.create_document(messages_collection, msg_data), "completed")
	print(add_message.error)

func _pprint(message: String):
	print("****\n\n [DEBUG]\n"+message+"\n****\n")
