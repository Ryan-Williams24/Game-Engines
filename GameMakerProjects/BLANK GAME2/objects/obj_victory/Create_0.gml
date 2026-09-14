// Generate a bright victory tone in code.
var rate = 22050;
var sample_count = round(rate * 0.8);
victory_buffer = buffer_create(sample_count, buffer_fixed, 1);
buffer_seek(victory_buffer, buffer_seek_start, 0);

for (var i = 0; i < sample_count; i++) {
    var progress = i / sample_count;
    var frequency = (progress < 0.33) ? 523 : ((progress < 0.66) ? 659 : 784);
    var sample = 128 + sin((i / rate) * frequency * pi * 2) * 70 * (1 - progress * 0.35);
    buffer_write(victory_buffer, buffer_u8, clamp(round(sample), 0, 255));
}

victory_sound = audio_create_buffer_sound(victory_buffer, buffer_u8, rate, 0, sample_count, audio_mono);
audio_play_sound(victory_sound, 3, false);
