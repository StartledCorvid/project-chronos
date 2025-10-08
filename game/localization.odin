package game

import "core:encoding/json"
import "core:log"
import "vfiles"


/*
# Overview
Handles localization of game text.
*/


// Contains information for the mapping of a language.
Language_Mapping :: struct {
    name: string,
    mappings: map[string]string,
}


@(private)
loaded_language: Language_Mapping


// Sets the current language that is being used.
set_language :: proc(language_file: string) {
    if len(loaded_language.mappings) > 0 {
        delete(loaded_language.name)
        delete(loaded_language.mappings)
    }

    data, read_err := vfiles.read_file_bytes(&game.fs, language_file)
    if read_err != nil {
        log.errorf("Error opening language file: %v", read_err)
        return
    }
    defer delete(data)
    json.unmarshal(data, &loaded_language)
}


// Gets a phrase with the given bindings. Returns error message if it is not found.
get_phrase :: proc(binding: string) -> (string, bool) #optional_ok {
    if binding in loaded_language.mappings {
        return loaded_language.mappings[binding], true
    }

    log.errorf("Language binding not found: '%v'", binding)
    return binding, false
}

// TODO: f_get_phrase?