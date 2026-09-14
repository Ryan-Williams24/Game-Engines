randomize();

// Balanced player settings.
move_speed = 4.5;
max_life = 8;
life_points = 5;
coins_collected = 0;
damage_cooldown = 0;
game_over = false;

// Two enemies are much slower than the player and begin far apart.
enemy_count = 2;
enemy_x = [64, room_width - 64];
enemy_y = [64, room_height - 64];
enemy_speed = [0.85, 1.05];

// Pick a coin position away from the player and enemies.
spawn_coin = function() {
    repeat (100) {
        coin_x = irandom_range(40, room_width - 40);
        coin_y = irandom_range(70, room_height - 40);

        var safe_position = point_distance(x, y, coin_x, coin_y) > 120;
        for (var i = 0; i < enemy_count; i++) {
            if (point_distance(enemy_x[i], enemy_y[i], coin_x, coin_y) < 100) {
                safe_position = false;
            }
        }

        if (safe_position) break;
    }
};

// Build a short fading tone entirely in code.
make_tone = function(_frequency, _seconds, _volume) {
    var _rate = 22050;
    var _sample_count = round(_rate * _seconds);
    var _buffer = buffer_create(_sample_count, buffer_fixed, 1);
    buffer_seek(_buffer, buffer_seek_start, 0);

    for (var i = 0; i < _sample_count; i++) {
        var _fade = 1 - (i / _sample_count);
        var _sample = 128 + sin((i / _rate) * _frequency * pi * 2) * 127 * _volume * _fade;
        buffer_write(_buffer, buffer_u8, clamp(round(_sample), 0, 255));
    }

    var _sound = audio_create_buffer_sound(_buffer, buffer_u8, _rate, 0, _sample_count, audio_mono);
    return { sound_id: _sound, data_buffer: _buffer };
};

coin_tone = make_tone(880, 0.12, 0.45);
hit_tone = make_tone(180, 0.20, 0.60);
game_over_tone = make_tone(95, 0.65, 0.70);

spawn_coin();
