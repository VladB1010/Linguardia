extends Node

const RES_PATH: String  = "res://custom_words.txt"
const USER_PATH: String = "user://custom_words.txt"

const _MIN_SENTENCE_LEN: int = 3

var custom_attack: Array  = []
var custom_special: Array = []
var custom_defend: Array  = []

var last_import_summary: String = ""

func _ready() -> void:
	print("[CustomWordList] Folder utilizator: ", OS.get_user_data_dir())
	reload()

func reload() -> void:
	if FileAccess.file_exists(RES_PATH):
		import_from_path(RES_PATH)
	elif FileAccess.file_exists(USER_PATH):
		import_from_path(USER_PATH)
	else:
		_clear()
		last_import_summary = "Niciun custom_words.txt găsit — folosesc listele normale."
		print("[CustomWordList] ", last_import_summary)

func import_from_path(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		last_import_summary = "Nu pot citi " + path
		push_error("[CustomWordList] " + last_import_summary)
		return false
	var text: String = file.get_as_text()
	file.close()
	import_from_text(text)
	last_import_summary += "  (sursă: " + path + ")"
	print("[CustomWordList] ", last_import_summary)
	return true

func import_from_text(text: String) -> void:
	_clear()
	text = clean_rtf(text)

	text = text.replace("\r\n", "\n")
	var lower_text := text.to_lower()
	var has_sections := false
	for key in ["-attack:", "-special:", "-defend:"]:
		if lower_text.contains(key):
			has_sections = true
			break

	if has_sections:
		var sections: Dictionary = _split_sections(text)
		if sections.has("attack"):
			custom_attack = _parse_pairs(sections["attack"])
			_attach_attack_options(custom_attack)
		if sections.has("defend"):
			custom_defend = _parse_defend(sections["defend"])
		if sections.has("special"):
			custom_special = _parse_sentences(sections["special"])
	else:
		_parse_auto_detected_format(text)

	last_import_summary = (
		"Import: " + str(custom_attack.size()) + " attack, "
		+ str(custom_defend.size()) + " defend, "
		+ str(custom_special.size()) + " special"
	)

func _parse_auto_detected_format(text: String) -> void:
	var lines := text.split("\n")
	var vocab_pairs: Array = []
	var special_accumulated := ""

	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed == "":
			continue

		if trimmed.contains("-"):
			var parts := trimmed.split("-", true, 1)
			if parts.size() == 2:
				var left := parts[0].strip_edges()
				var right := parts[1].strip_edges()
				if left != "" and right != "":
					vocab_pairs.append({"left": left, "right": right})
		else:
			if special_accumulated != "":
				special_accumulated += " "
			special_accumulated += trimmed

	var all_lefts: Array = []
	for p in vocab_pairs:
		all_lefts.append(p["left"])

	for p in vocab_pairs:
		var correct: String = p["left"]
		var word: String = p["right"]

		var pool := all_lefts.duplicate()
		pool.erase(correct)
		pool.shuffle()

		var decoys: Array = []
		for c in pool:
			if decoys.size() >= 3:
				break
			if not decoys.has(c):
				decoys.append(c)

		var filler_idx := 1
		while decoys.size() < 3:
			decoys.append("(fara raspuns " + str(filler_idx) + ")")
			filler_idx += 1

		var options := decoys.duplicate()
		options.append(correct)
		options.shuffle()

		custom_attack.append({
			"word": word,
			"correct": correct,
			"options": options
		})

	if special_accumulated != "":
		var raw_sentences := special_accumulated.split(".")
		for s in raw_sentences:
			var sentence := s.strip_edges()
			if sentence.length() >= _MIN_SENTENCE_LEN:
				custom_special.append({"sentence": sentence})

func _clear() -> void:
	custom_attack.clear()
	custom_special.clear()
	custom_defend.clear()

func show_toast(text: String, duration: float = 2.5) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100

	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -60
	label.modulate = Color(1, 1, 1, 0)
	layer.add_child(label)

	get_tree().root.add_child(layer)

	var tween: Tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	await tween.finished

	layer.queue_free()

func _split_sections(text: String) -> Dictionary:
	var lower: String = text.to_lower()
	var found: Array = []

	for key in ["attack", "special", "defend"]:
		var marker: String = "-" + key + ":"
		var search_from: int = 0
		while true:
			var idx: int = lower.find(marker, search_from)
			if idx == -1:
				break
			found.append({
				"key": key,
				"marker_start": idx,
				"content_start": idx + marker.length(),
			})
			search_from = idx + marker.length()

	if found.is_empty():
		return {}

	found.sort_custom(func(a, b): return a["marker_start"] < b["marker_start"])

	var result: Dictionary = {}
	for i in found.size():
		var start: int = found[i]["content_start"]
		var end: int = text.length()
		if i + 1 < found.size():
			end = found[i + 1]["marker_start"]
		var content: String = text.substr(start, end - start).strip_edges()
		var key: String = found[i]["key"]
		if result.has(key):
			result[key] += "\n" + content
		else:
			result[key] = content

	return result

func _parse_pairs(section_text: String) -> Array:
	var lines: Array = []
	for raw_line in section_text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line != "":
			lines.append(line)

	if lines.size() > 1:
		return _pairs_from_lines(lines)
	if lines.size() == 1:
		return _pairs_from_run_on(lines[0])
	return []

func _pairs_from_lines(lines: Array) -> Array:
	var out: Array = []
	for line in lines:
		var sp: int = line.find(" ")
		if sp == -1:
			continue
		var word: String = line.substr(0, sp).strip_edges()
		var rest: String = line.substr(sp + 1).strip_edges()
		if word != "" and rest != "":
			out.append({"word": word, "correct": rest})
	return out

func _pairs_from_run_on(text: String) -> Array:
	var starts: Array = []
	var n: int = text.length()
	for i in n:
		if _is_upper_ascii(text[i]) and (i == 0 or text[i - 1] == " " or text[i - 1] == "\t"):
			starts.append(i)

	if starts.is_empty():
		return []

	var out: Array = []
	for i in starts.size():
		var start: int = starts[i]
		var end: int = n
		if i + 1 < starts.size():
			end = starts[i + 1]
		var chunk: String = text.substr(start, end - start).strip_edges()
		var sp: int = chunk.find(" ")
		if sp == -1:
			continue
		var word: String = chunk.substr(0, sp).strip_edges()
		var rest: String = chunk.substr(sp + 1).strip_edges()
		while rest.ends_with(","):
			rest = rest.substr(0, rest.length() - 1).strip_edges()
		if word != "" and rest != "":
			out.append({"word": word, "correct": rest})
	return out

func _is_upper_ascii(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code: int = ch.unicode_at(0)
	return code >= 65 and code <= 90

func _attach_attack_options(entries: Array) -> void:
	var all_corrects: Array = []
	for e in entries:
		all_corrects.append(e["correct"])

	for i in entries.size():
		var correct: String = entries[i]["correct"]
		var pool: Array = all_corrects.duplicate()
		pool.erase(correct)
		pool.shuffle()

		var decoys: Array = []
		for c in pool:
			if decoys.size() >= 3:
				break
			if not decoys.has(c):
				decoys.append(c)

		var filler_idx: int = 1
		while decoys.size() < 3:
			decoys.append("(fără răspuns " + str(filler_idx) + ")")
			filler_idx += 1

		var options: Array = decoys.duplicate()
		options.append(correct)
		entries[i]["options"] = options

func _parse_defend(section_text: String) -> Array:
	var pairs: Array = _parse_pairs(section_text)
	var out: Array = []
	for p in pairs:
		out.append({
			"word": p["word"],
			"correct": p["correct"],
			"acceptable": [p["correct"]],
		})
	return out

func _parse_sentences(section_text: String) -> Array:
	var lines: Array = []
	for raw_line in section_text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line != "":
			lines.append(line)

	var raw_sentences: Array = []
	if lines.size() > 1:
		raw_sentences = lines
	elif lines.size() == 1:
		raw_sentences = _split_into_sentences(lines[0])

	var out: Array = []
	for s in raw_sentences:
		var sentence: String = (s as String).strip_edges()
		if sentence.length() >= _MIN_SENTENCE_LEN:
			out.append({"sentence": sentence})
	return out

func _split_into_sentences(text: String) -> Array:
	var out: Array = []
	var current: String = ""
	for i in text.length():
		var ch: String = text[i]
		current += ch
		if ch == "." or ch == "!" or ch == "?":
			var trimmed: String = current.strip_edges()
			if trimmed != "":
				out.append(trimmed)
			current = ""
	var tail: String = current.strip_edges()
	if tail != "":
		out.append(tail)
	return out

static func clean_rtf(rtf: String) -> String:
	var stripped := rtf.strip_edges()
	if not stripped.begins_with("{\\rtf"):
		return rtf

	var result: String = ""
	var i: int = 0
	var n: int = rtf.length()
	var stack: Array = []
	var ignore_current_group: bool = false

	while i < n:
		var ch: String = rtf[i]
		if ch == "{":
			stack.append(ignore_current_group)
			i += 1
			if i < n and rtf[i] == "\\":
				var start_peek: int = i + 1
				var end_peek: int = start_peek
				while end_peek < n:
					var peek_ch := rtf[end_peek]
					if (peek_ch >= "a" and peek_ch <= "z") or (peek_ch >= "A" and peek_ch <= "Z"):
						end_peek += 1
					else:
						break
				var word: String = rtf.substr(start_peek, end_peek - start_peek).to_lower()
				if word in ["fonttbl", "colortbl", "stylesheet", "info", "generator", "listtext"] or rtf.substr(i, 2) == "\\*":
					ignore_current_group = true
		elif ch == "}":
			if not stack.is_empty():
				ignore_current_group = stack.pop_back()
			i += 1
		elif ch == "\\":
			i += 1
			if i >= n:
				break
			var next_ch: String = rtf[i]
			if next_ch == "\\" or next_ch == "{" or next_ch == "}":
				if not ignore_current_group:
					result += next_ch
				i += 1
			elif next_ch == "u":
				i += 1
				var num_str: String = ""
				while i < n and rtf[i] >= "0" and rtf[i] <= "9":
					num_str += rtf[i]
					i += 1
				var code: int = num_str.to_int()
				if i < n and (rtf[i] == " " or rtf[i] == "?"):
					i += 1

				if not ignore_current_group:
					if code == 8232 or code == 8233:
						result += "\n"
					else:
						result += char(code)
			elif (next_ch >= "a" and next_ch <= "z") or (next_ch >= "A" and next_ch <= "Z"):
				var start_word: int = i
				while i < n and ((rtf[i] >= "a" and rtf[i] <= "z") or (rtf[i] >= "A" and rtf[i] <= "Z")):
					i += 1
				var word: String = rtf.substr(start_word, i - start_word).to_lower()
				if i < n and (rtf[i] == "-" or (rtf[i] >= "0" and rtf[i] <= "9")):
					i += 1
					while i < n and rtf[i] >= "0" and rtf[i] <= "9":
						i += 1
				if i < n and rtf[i] == " ":
					i += 1

				if not ignore_current_group:
					if word == "par" or word == "line":
						result += "\n"
					elif word == "tab":
						result += "\t"
			else:
				if next_ch == "'":
					i += 1
					if i + 2 <= n:
						var hex: String = rtf.substr(i, 2)
						var code: int = ("0x" + hex).to_int()
						if not ignore_current_group:
							result += char(code)
						i += 2
				else:
					i += 1
		else:
			if not ignore_current_group:
				result += ch
			i += 1

	return result
