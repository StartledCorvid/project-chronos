package gen

import "core:slice"
import "core:sort"
import "core:encoding/json"
import "core:path/filepath"
import "core:log"
import "core:os"
import "core:fmt"


/*
# Overview
Handles the generation of the content_fights.odin file
using the json files found in the given directory.
*/


Fight_Info :: struct {
    rating: int,
    composition: []string,
}



// Generate the gen file for Fight types.
gen_fights :: proc(source_dir: string, dest: string) -> bool {
    log.info("Generating Fights")
    defer log.info("Done generating Fights.")

    // == Check if the given source directory is a directory.
    if !os.is_dir(source_dir) {
        log.errorf("'%v' is not a directory.", source_dir)
        return false
    }

    // == Try to open the source directory.
    dir, dir_err := os.open(source_dir)
    if dir_err != os.ERROR_NONE {
        log.errorf("Problem opening directory '%v': %v", source_dir, os.error_string(dir_err))
        return false
    }
    defer os.close(dir)

    // == Try to gather File_Info inside the directory.
    files_info, files_err := os.read_dir(dir, -1)
    if files_err != os.ERROR_NONE {
        log.errorf("Problem reading files in '%v': %v", source_dir, os.error_string(files_err))
        return false
    }
    defer os.file_info_slice_delete(files_info)

    // == Open generated file.
    gen_file, gen_open_err := os.open(dest, os.O_WRONLY | os.O_CREATE)
    if gen_open_err != os.ERROR_NONE {
        log.errorf("Problem opening destination file '%v': %v", dest, os.error_string(gen_open_err))
        return false
    }
    defer os.close(gen_file)

    log.infof("Loading %v files.", len(files_info))

    fight_info := get_fight_info(files_info)
    defer delete(fight_info)

    file_header(gen_file)
    fight_contents(gen_file, fight_info[:])

    return true
}


@(private="file")
get_fight_info :: proc(files: []os.File_Info) -> [dynamic]Fight_Info {
    info: [dynamic]Fight_Info

    for file in files {
        file_contents, read_err := os.read_entire_file_or_err(file.fullpath)
        if read_err != os.ERROR_NONE {
            log.errorf("Could not read file '%v': %v", file.fullpath, os.error_string(read_err))
            continue
        }
        defer delete(file_contents)

        fight_info: Fight_Info
        unmarshal_err := json.unmarshal(file_contents, &fight_info)
        if unmarshal_err != nil {
            log.errorf("Problem unmarshalling JSON from file '%v': %v", file.fullpath, unmarshal_err)
            continue
        }

        append(&info, fight_info)
    }

    slice.sort_by(info[:], proc(a, b: Fight_Info) -> bool {
        return a.rating < b.rating
    })

    return info
}


// Generate gen file header info.
@(private="file")
file_header :: proc(f: os.Handle) {
    fmt.fprintfln(f, "// Generated file")
    fmt.fprintfln(f, "package game")
    fmt.fprintln(f, "")
}


@(private="file")
fight_contents :: proc(f: os.Handle, info: []Fight_Info) {
    fmt.fprintln(f, "@(rodata)")
    fmt.fprintln(f, "FIGHTS := [?]Fight_Info{")

    for info, index in info {
        fmt.fprintln(f, "\t{")
        fmt.fprintfln(f, "\t\trating = %v,", info.rating)
        fmt.fprintln(f, "\t\tcomposition = {")

        for type in info.composition {
            fmt.fprintfln(f, "\t\t\t.%v,", type)
        }

        fmt.fprintln(f, "\t\t},")

        fmt.fprintln(f, "\t},")
    }

    fmt.fprintln(f, "}")
}