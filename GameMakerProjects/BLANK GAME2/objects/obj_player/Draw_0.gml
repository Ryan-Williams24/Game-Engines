draw_self();

// Draw the coin.
draw_set_color(c_yellow);
draw_circle(coin_x, coin_y, 10, false);
draw_set_color(c_orange);
draw_circle(coin_x, coin_y, 5, false);

// Draw the enemies.
for (var i = 0; i < enemy_count; i++) {
    draw_set_color(c_red);
    draw_circle(enemy_x[i], enemy_y[i], 14, false);
    draw_set_color(c_black);
    draw_circle(enemy_x[i], enemy_y[i], 5, false);
}

// Flash the screen after damage so the safety period is easy to notice.
if (damage_cooldown > 0 && !game_over) {
    draw_set_alpha(0.18);
    draw_set_color(c_red);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);
}

draw_set_color(c_white);
draw_text(16, 16, "Life: " + string(life_points) + " / " + string(max_life));
draw_text(16, 36, "Coins: " + string(coins_collected) + " / 10");
draw_text(16, 56, "Collect 10 coins to win");

if (game_over) {
    draw_set_alpha(0.80);
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    draw_text(room_width / 2, room_height / 2 - 45, "GAME OVER");
    draw_set_color(c_white);
    draw_text(room_width / 2, room_height / 2 - 10, "Coins collected: " + string(coins_collected));

    var button_left = room_width / 2 - 110;
    var button_top = room_height / 2 + 35;
    var button_right = room_width / 2 + 110;
    var button_bottom = room_height / 2 + 85;
    var button_hovered = point_in_rectangle(mouse_x, mouse_y, button_left, button_top, button_right, button_bottom);

    draw_set_color(button_hovered ? c_aqua : c_blue);
    draw_rectangle(button_left, button_top, button_right, button_bottom, false);
    draw_set_color(c_white);
    draw_text(room_width / 2, room_height / 2 + 60, "RESTART");
    draw_text(room_width / 2, room_height / 2 + 110, "Click Restart or press R");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
