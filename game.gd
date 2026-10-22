extends Node2D

const PLAYER_SPEED := 250.0
const WORLD_SIZE := Vector2(1800, 1000)
const PLAYER_RADIUS := 22.0

var player_pos := Vector2(140, 150)
var collectibles: Array[Vector2] = []
var collected := 0
var total_collectibles := 8
var obstacle_rects: Array[Rect2] = []
var goal_rect := Rect2(1580, 790, 110, 110)
var camera_offset := Vector2.ZERO
var game_won := false
var message := "Collect all 8 teddy bears, then reach the green exit!"
var touch_direction := Vector2.ZERO

func _ready() -> void:
    _make_world()
    queue_redraw()

func _make_world() -> void:
    collectibles.clear()
    collectibles.append_array([
        Vector2(340, 130), Vector2(590, 310), Vector2(890, 150),
        Vector2(1120, 390), Vector2(420, 650), Vector2(800, 790),
        Vector2(1320, 650), Vector2(1510, 280)
    ])
    obstacle_rects = [
        Rect2(240, 230, 180, 65),
        Rect2(500, 100, 75, 210),
        Rect2(700, 260, 210, 70),
        Rect2(1000, 120, 70, 220),
        Rect2(1180, 500, 230, 70),
        Rect2(250, 470, 70, 200),
        Rect2(570, 570, 210, 65),
        Rect2(970, 690, 75, 190),
        Rect2(1430, 450, 70, 180)
    ]

func _process(delta: float) -> void:
    if game_won:
        queue_redraw()
        return

    var direction := Vector2.ZERO
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        direction.x -= 1
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        direction.x += 1
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        direction.y -= 1
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        direction.y += 1

    direction += touch_direction
    if direction.length() > 1.0:
        direction = direction.normalized()

    var candidate := player_pos + direction * PLAYER_SPEED * delta
    candidate.x = clampf(candidate.x, PLAYER_RADIUS, WORLD_SIZE.x - PLAYER_RADIUS)
    candidate.y = clampf(candidate.y, PLAYER_RADIUS, WORLD_SIZE.y - PLAYER_RADIUS)
    if not _hits_obstacle(candidate):
        player_pos = candidate
    elif not _hits_obstacle(Vector2(candidate.x, player_pos.y)):
        player_pos.x = candidate.x
    elif not _hits_obstacle(Vector2(player_pos.x, candidate.y)):
        player_pos.y = candidate.y

    for i in range(collectibles.size() - 1, -1, -1):
        if player_pos.distance_to(collectibles[i]) < 38:
            collectibles.remove_at(i)
            collected += 1
            message = "Nice! Teddy bears: %d/%d" % [collected, total_collectibles]

    if collected >= total_collectibles and goal_rect.has_point(player_pos):
        game_won = true
        message = "You win! Mr Bean found every teddy bear!"

    queue_redraw()

func _hits_obstacle(pos: Vector2) -> bool:
    var player_box := Rect2(pos - Vector2(PLAYER_RADIUS, PLAYER_RADIUS), Vector2(PLAYER_RADIUS * 2, PLAYER_RADIUS * 2))
    for rect in obstacle_rects:
        if player_box.intersects(rect):
            return true
    return false

func _draw() -> void:
    # Camera-like viewport centered on the player.
    var view := get_viewport_rect().size
    camera_offset = player_pos - view / 2.0
    camera_offset.x = clampf(camera_offset.x, 0, WORLD_SIZE.x - view.x)
    camera_offset.y = clampf(camera_offset.y, 0, WORLD_SIZE.y - view.y)

    draw_rect(Rect2(Vector2.ZERO, view), Color("#8acb78"), true)
    # Lawn stripes
    for x in range(0, int(WORLD_SIZE.x), 100):
        for y in range(0, int(WORLD_SIZE.y), 100):
            var p := Vector2(x, y) - camera_offset
            if p.x > -100 and p.y > -100 and p.x < view.x and p.y < view.y:
                if ((x / 100) + (y / 100)) % 2 == 0:
                    draw_rect(Rect2(p, Vector2(100, 100)), Color(0.45, 0.72, 0.38, 0.28), true)

    # Paths
    draw_rect(Rect2(Vector2(0, 420) - camera_offset, Vector2(WORLD_SIZE.x, 90)), Color("#d8c39a"), true)
    draw_rect(Rect2(Vector2(650, 0) - camera_offset, Vector2(90, WORLD_SIZE.y)), Color("#d8c39a"), true)

    # Obstacles: bushes/benches
    for r in obstacle_rects:
        var screen_r := Rect2(r.position - camera_offset, r.size)
        draw_rect(screen_r, Color("#466b39"), true)
        draw_rect(Rect2(screen_r.position + Vector2(5, 5), screen_r.size - Vector2(10, 10)), Color("#5f914a"), true)

    # Exit
    var exit_screen := Rect2(goal_rect.position - camera_offset, goal_rect.size)
    draw_rect(exit_screen, Color("#2f9e58") if collected >= total_collectibles else Color("#666666"), true)
    draw_rect(Rect2(exit_screen.position + Vector2(12, 12), exit_screen.size - Vector2(24, 24)), Color("#b8f3a6"), false, 4)
    _draw_centered_text("EXIT", exit_screen.position + Vector2(exit_screen.size.x / 2, exit_screen.size.y / 2 + 8), 22, Color("#153d24"))

    # Teddy bear collectibles
    for item in collectibles:
        var p := item - camera_offset
        draw_circle(p + Vector2(-9, -10), 7, Color("#8a542f"))
        draw_circle(p + Vector2(9, -10), 7, Color("#8a542f"))
        draw_circle(p, 15, Color("#b77a45"))
        draw_circle(p + Vector2(-5, -2), 2, Color.BLACK)
        draw_circle(p + Vector2(5, -2), 2, Color.BLACK)
        draw_circle(p + Vector2(0, 5), 4, Color("#e8c79d"))

    # Player shadow and simple cartoon character (original simple shapes)
    var pp := player_pos - camera_offset
    draw_ellipse(pp + Vector2(0, 23), Vector2(17, 7), Color(0, 0, 0, 0.18))
    # legs
    draw_rect(Rect2(pp + Vector2(-11, 8), Vector2(8, 17)), Color("#242c46"), true)
    draw_rect(Rect2(pp + Vector2(3, 8), Vector2(8, 17)), Color("#242c46"), true)
    # brown jacket
    draw_colored_polygon(PackedVector2Array([
        pp + Vector2(-16, -6), pp + Vector2(16, -6), pp + Vector2(13, 13), pp + Vector2(-13, 13)
    ]), Color("#79503b"))
    # shirt and tie
    draw_colored_polygon(PackedVector2Array([
        pp + Vector2(-7, -7), pp + Vector2(7, -7), pp + Vector2(2, 10), pp + Vector2(-2, 10)
    ]), Color("#f4eee0"))
    draw_colored_polygon(PackedVector2Array([
        pp + Vector2(-2, -3), pp + Vector2(2, -3), pp + Vector2(4, 8), pp + Vector2(0, 12), pp + Vector2(-3, 8)
    ]), Color("#b92e2e"))
    # head, ears, hair
    draw_circle(pp + Vector2(-16, -18), 5, Color("#e8b88b"))
    draw_circle(pp + Vector2(16, -18), 5, Color("#e8b88b"))
    draw_circle(pp + Vector2(0, -20), 16, Color("#efc49b"))
    draw_arc(pp + Vector2(0, -25), 15, PI, TAU, 16, Color("#3b2924"), 7)
    draw_circle(pp + Vector2(-5, -20), 2, Color("#24201f"))
    draw_circle(pp + Vector2(5, -20), 2, Color("#24201f"))
    draw_line(pp + Vector2(-5, -12), pp + Vector2(5, -12), Color("#6d332b"), 2)

    # HUD
    draw_rect(Rect2(Vector2(12, 12), Vector2(view.x - 24, 72)), Color(0.05, 0.08, 0.07, 0.82), true)
    _draw_centered_text("MR BEAN 2D ADVENTURE", Vector2(view.x / 2, 38), 24, Color.WHITE)
    _draw_centered_text("Teddy bears: %d/%d   •   %s" % [collected, total_collectibles, message], Vector2(view.x / 2, 65), 15, Color("#f4f4e8"))

    if game_won:
        draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, 0.55), true)
        _draw_centered_text("YOU WIN!", view / 2 - Vector2(0, 25), 46, Color("#ffe58a"))
        _draw_centered_text("All teddy bears collected!", view / 2 + Vector2(0, 20), 22, Color.WHITE)
        _draw_centered_text("Close and reopen the game to play again.", view / 2 + Vector2(0, 55), 16, Color.WHITE)

func _draw_centered_text(text_value: String, center: Vector2, font_size: int, color: Color) -> void:
    var font := ThemeDB.fallback_font
    var width := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    draw_string(font, Vector2(center.x - width / 2, center.y), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_colored_polygon(points, color)

func _input(event: InputEvent) -> void:
    # Keyboard support. Touch controls are included as on-screen buttons via the UI overlay below.
    if event is InputEventScreenTouch:
        if event.pressed:
            var pos := event.position
            var view := get_viewport_rect().size
            if pos.x < view.x * 0.38:
                if pos.y > view.y * 0.58:
                    touch_direction = Vector2(-1, 0)
                elif pos.y > view.y * 0.40:
                    touch_direction = Vector2(0, 1)
            elif pos.x > view.x * 0.62:
                if pos.y > view.y * 0.58:
                    touch_direction = Vector2(1, 0)
                else:
                    touch_direction = Vector2(0, -1)
        else:
            touch_direction = Vector2.ZERO
