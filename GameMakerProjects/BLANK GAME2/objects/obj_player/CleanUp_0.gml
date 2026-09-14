// Release the generated sounds and their buffers when the room restarts or closes.
audio_free_buffer_sound(coin_tone.sound_id);
audio_free_buffer_sound(hit_tone.sound_id);
audio_free_buffer_sound(game_over_tone.sound_id);
buffer_delete(coin_tone.data_buffer);
buffer_delete(hit_tone.data_buffer);
buffer_delete(game_over_tone.data_buffer);
