package game

import "core:log"
import "core:strings"
import "core:encoding/ini"
import "core:os"


/*
# Overview
*/

@(private)
PREFERENCES_FILE :: "preferences.ini"


Preferences :: struct {
    language: string,
}


load_preferences :: proc() -> Preferences {
    preferences: Preferences

    if !os.exists(PREFERENCES_FILE) {
        preferences = default_preferences()
        save_preferences(preferences)
    } else {
        data, _ := os.read_entire_file(PREFERENCES_FILE)
        defer delete(data)

        string_data := strings.clone_from_bytes(data)
        defer delete(string_data)

        iterator := ini.iterator_from_string(string_data)
        for key, value in ini.iterate(&iterator) {
            log.infof("KEY: %v; VALUE: %v", key, value)
        }
    }

    return preferences
}


save_preferences :: proc(preferences: Preferences) {
    
}


@(private)
default_preferences :: proc() -> Preferences {
    return {
        language = "en_us",

    }
}