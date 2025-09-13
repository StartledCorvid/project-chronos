package vfiles 


import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:log"


@(private)
Context :: struct {
    root_path: string,
}


// The current instance's resource Context. `init` must be called first.
@(private)
ctx: Context


// Initializes the resource system, setting the root path to the given path.
init :: proc(root: string, loc := #caller_location) {
    assert(ctx.root_path == "", "Virtual file system already initialized.", loc)

    current_dir := os.get_current_directory()
    defer delete(current_dir)

    clean_path := absolute_path(root, current_dir)
    defer delete(clean_path)

    ctx.root_path = strings.clone(clean_path) 
    log.infof("Initialized virtual file system. Root path = %v.", ctx.root_path)
}


// Deinitializes the virtual file system.
deinit :: proc(loc := #caller_location) {
    assert(ctx.root_path != "", "Virtual file system not initialized.", loc)

    delete(ctx.root_path)
    log.info("Deinitialized virtual file system.")
}


// Loads an entire file and returns it as a slice of bytes.
load_file_bytes :: proc(v_path: string, allocator := context.allocator, loc := #caller_location) -> []byte {
    path := absolute_path(v_path)
    defer delete(path)

    assert(os.exists(path), "File path does not exist.", loc)

    data, ok := os.read_entire_file(path, allocator, loc)
    assert(ok, "Problem loading file.", loc)

    return data
}


// Writes a given array of bytes to the given file.
write_file_bytes :: proc(v_path: string, data: []byte) -> bool {
    assert(ctx.root_path != "", "Virtual file system not initialized.")

    a_path := absolute_path(v_path)
    defer delete(a_path)

    if !is_rooted(ctx.root_path, a_path) {
        log.errorf("Path travels outside of virtual file system root: %v", a_path)
        return false
    }

    ok := os.write_entire_file(a_path, data)
    if !ok {
        log.error("Could not write to file: %v", a_path)
        return false
    }

    return true
}


// Frees the given file data from memory.
free_file_bytes :: proc(data: []byte, allocator := context.allocator, loc := #caller_location) {
    assert(data != nil, "Nil data.", loc)
    delete(data, allocator, loc)
}


// Loads an entire file and returns it as a string.
load_file_string :: proc(v_path: string, allocator := context.allocator, loc := #caller_location) -> string {
    assert(exists(v_path), "File path does not exist.", loc)

    data := load_file_bytes(v_path)
    defer free_file_bytes(data)

    data_string := strings.clone(string(data), allocator, loc)
    return data_string 
}


// Frees the given file string from memory.
free_file_string :: proc(file_string: string, allocator := context.allocator, loc := #caller_location) {
    delete(file_string, allocator, loc)
}


// Takes a path relative to the search path and converts it to an absolute system path. Must
// deallocate the resulting string.
get_path :: proc(v_path: string, allocator := context.allocator, loc := #caller_location) -> string {
    assert(ctx.root_path != "", "Virtual file system not initialized.")

    path := absolute_path(v_path, allocator = allocator)
    defer delete(path, allocator)

    return strings.clone(path, allocator, loc)
}


// Deletes the given file on the search path.
remove_file :: proc(v_path: string, loc := #caller_location) {
    assert(ctx.root_path != "", "Virtual file system not initialized.", loc)
    assert(exists(v_path), "File does not exist.", loc)

    absolute_path := absolute_path(v_path)
    defer delete(absolute_path)

    err := os.remove(absolute_path)
    if err != nil {
        log.errorf("Problem deleting file: %v", os.error_string(err))
    }
}


// Returns true if the given path exists on the search path.
exists :: proc(v_path: string, loc := #caller_location) -> bool {
    assert(ctx.root_path != "", "Virtual file system not initialized.", loc)

    absolute_path := get_path(v_path)
    defer delete(absolute_path)

    if !os.exists(absolute_path) {
        log.errorf("Given path '%v' does not exist.", absolute_path)
        return false
    }

    return is_rooted(ctx.root_path, absolute_path)
}


// Returns true if root is part of the root of path. Assumes that both are absolute paths that
// have been cleaned.
@(private)
is_rooted :: proc(root, path: string) -> bool {
    // If the root path is longer than the target path, then it cannot be inside of it.
    if len(root) > len(path) {
        return false 
    }

    root_components, _ := strings.split(root, filepath.SEPARATOR_STRING)
    defer delete(root_components)

    path_components, _ := strings.split(path, filepath.SEPARATOR_STRING)
    defer delete(path_components)

    if len(root_components) > len(path_components) {
        return false
    }

    for root_comp, i in root_components {
        path_comp := path_components[i]

        if !strings.equal_fold(root_comp, path_comp) {
            return false
        }
    }

    return true
}


// Get the absolute path of a given path relative to the root.
@(private)
absolute_path :: proc(path: string, root := ctx.root_path, allocator := context.allocator, loc := #caller_location) -> string {
    new_path := strings.clone(path, allocator)
    defer delete(new_path, allocator)

    joined_path := filepath.join({root, new_path}, allocator)
    defer delete(joined_path, allocator)

    clean_path := filepath.clean(joined_path, allocator)
    defer delete(clean_path, allocator)

    return strings.clone(clean_path, allocator, loc)
}