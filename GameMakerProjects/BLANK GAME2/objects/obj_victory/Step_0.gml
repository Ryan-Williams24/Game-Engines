var button_left = room_width / 2 - 110;
var button_top = room_height / 2 + 55;
var button_right = room_width / 2 + 110;
var button_bottom = room_height / 2 + 105;

var clicked_restart = mouse_check_button_pressed(mb_left)
    && point_in_rectangle(mouse_x, mouse_y, button_left, button_top, button_right, button_bottom);

if (clicked_restart || keyboard_check_pressed(ord("R"))) {
    room_goto(Room1);
}
