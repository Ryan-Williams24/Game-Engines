if (game_over) {
    var button_left = room_width / 2 - 110;
    var button_top = room_height / 2 + 35;
    var button_right = room_width / 2 + 110;
    var button_bottom = room_height / 2 + 85;

    var clicked_restart = mouse_check_button_pressed(mb_left)
        && point_in_rectangle(mouse_x, mouse_y, button_left, button_top, button_right, button_bottom);

    if (clicked_restart || keyboard_check_pressed(ord("R"))) {
        room_restart();
    }
    exit;
}

// WASD movement, normalized so diagonal movement is not faster.
var move_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var move_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));

if (move_x != 0 || move_y != 0) {
    var move_length = point_distance(0, 0, move_x, move_y);
    x += (move_x / move_length) * move_speed;
    y += (move_y / move_length) * move_speed;
}

x = clamp(x, sprite_width / 2, room_width - sprite_width / 2);
y = clamp(y, sprite_height / 2, room_height - sprite_height / 2);

// Enemies chase the player, but remain much slower.
for (var i = 0; i < enemy_count; i++) {
    var enemy_direction = point_direction(enemy_x[i], enemy_y[i], x, y);
    enemy_x[i] += lengthdir_x(enemy_speed[i], enemy_direction);
    enemy_y[i] += lengthdir_y(enemy_speed[i], enemy_direction);
    enemy_x[i] = clamp(enemy_x[i], 14, room_width - 14);
    enemy_y[i] = clamp(enemy_y[i], 14, room_height - 14);
}

if (damage_cooldown > 0) damage_cooldown--;

// A hit removes one point, gives 1.5 seconds of safety, and pushes the enemy away.
for (var i = 0; i < enemy_count; i++) {
    if (damage_cooldown <= 0 && point_distance(x, y, enemy_x[i], enemy_y[i]) < 31) {
        life_points--;
        damage_cooldown = 90;
        audio_play_sound(hit_tone.sound_id, 1, false);

        enemy_x[i] = (x < room_width / 2) ? room_width - 50 : 50;
        enemy_y[i] = irandom_range(60, room_height - 60);
        break;
    }
}

// Coins heal two life points and always respawn in a safer location.
if (point_distance(x, y, coin_x, coin_y) < 25) {
    life_points = min(max_life, life_points + 2);
    coins_collected++;
    audio_play_sound(coin_tone.sound_id, 1, false);

    if (coins_collected >= 10) {
        room_goto(RoomVictory);
        exit;
    }

    spawn_coin();
}

if (life_points <= 0) {
    life_points = 0;
    game_over = true;
    audio_play_sound(game_over_tone.sound_id, 2, false);
}
