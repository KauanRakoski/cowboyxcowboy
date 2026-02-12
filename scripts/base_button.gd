extends Button
class_name BtnEffect # <--- ISSO É O SEGREDO!

# Configurações
const COR_NORMAL = Color(1, 1, 1, 1)      # Cor original
const COR_HOVER = Color(0.6, 0.6, 0.6, 1) # Cinza escuro (Escurecer)
const COR_DISABLED = Color(1, 1, 1, 0.5)  # Meio transparente (Desbotado)

func _ready():

	pivot_offset = size / 2
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)


func _process(_delta):
	if disabled:
		modulate = COR_DISABLED
		
	else:
		if not is_hovered():
			modulate = COR_NORMAL

func _on_hover():
	if disabled: return
	
	# 1. Escurece (Tinge de cinza)
	modulate = COR_HOVER
	
	# 2. Cresce um pouquinho (Tween para ser suave)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_exit():
	if disabled: return
	
	# 1. Volta a cor normal
	modulate = COR_NORMAL
	
	# 2. Volta ao tamanho normal
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
