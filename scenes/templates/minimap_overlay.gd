extends Control

func _draw() -> void:
	var center := size * 0.5
	var radius := size.x * 0.5 - 8.0
	# Thick dark outline and purple rim echo the reference image.
	draw_arc(center, radius + 2.0, 0.0, TAU, 128, Color("221b2a"), 9.0, true)
	draw_arc(center, radius, 0.0, TAU, 128, Color("b86acb"), 6.0, true)
	var north: Vector2 = get_parent().north_screen
	var marker := center + north * radius
	draw_circle(marker, 18.0, Color("17171c"))
	draw_arc(marker, 18.0, 0.0, TAU, 48, Color("e7ddec"), 2.0, true)
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size("N", HORIZONTAL_ALIGNMENT_LEFT, -1, 23)
	draw_string(font, marker + Vector2(-text_size.x * 0.5, text_size.y * 0.32), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
	var arrow := PackedVector2Array([center + Vector2(0, -13), center + Vector2(10, 10), center + Vector2(0, 6), center + Vector2(-10, 10)])
	draw_colored_polygon(arrow, Color("15151b"))
	var inner := PackedVector2Array([center + Vector2(0, -9), center + Vector2(6, 6), center + Vector2(0, 3), center + Vector2(-6, 6)])
	draw_colored_polygon(inner, Color.WHITE)
