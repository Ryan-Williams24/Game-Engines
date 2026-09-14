draw_set_halign(fa_center);
draw_set_valign(fa_middle);

draw_set_color(c_lime);
draw_text(room_width / 2, room_height / 2 - 90, "VICTORY!");
draw_set_color(c_white);
draw_text(room_width / 2, room_height / 2 - 45, "You collected all 10 coins!");

var button_left = room_width / 2 - 110;
var button_top = room_height / 2 + 55;
var button_right = room_width / 2 + 110;
var button_bottom = room_height / 2 + 105;
var button_hovered = point_in_rectangle(mouse_x, mouse_y, button_left, button_top, button_right, button_bottom);

draw_set_color(button_hovered ? c_aqua : c_green);
draw_rectangle(button_left, button_top, button_right, button_bottom, false);
draw_set_color(c_white);
draw_text(room_width / 2, room_height / 2 + 80, "PLAY AGAIN");
draw_text(room_width / 2, room_height / 2 + 130, "Click Play Again or press R");

draw_set_halign(fa_left);
draw_set_valign(fa_top);
