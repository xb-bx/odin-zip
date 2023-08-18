package zip

import "core:c"
import "core:strings"
import "core:mem"
import "core:slice"
import "core:fmt"
when ODIN_OS == .Windows {
    foreign import libzip "libzip:zip.lib"
} else when ODIN_OS == .Linux {
    foreign import libzip "libzip:libzip.a"
}
foreign libzip {
    zip_strerror :: proc(err: ZipError) -> cstring ---
    zip_open :: proc(zipname: cstring, level: c.int, mode: c.char) -> ^Zip ---
    zip_close :: proc(zip: ^Zip) ---
    zip_entry_open :: proc(zip: ^Zip, entry: cstring) -> ZipError ---
    zip_entry_close :: proc(zip: ^Zip) -> ZipError ---
    zip_entry_opencasesensitive :: proc(zip: ^Zip, entry: cstring) -> ZipError ---
    zip_entries_total :: proc(zip: ^Zip) -> c.long ---
    zip_entry_name :: proc(zip: ^Zip) -> cstring ---
    zip_entry_openbyindex :: proc(zip: ^Zip, index: c.size_t) -> ZipError ---
    zip_entries_delete :: proc(zip: ^Zip, entries: [^]cstring, len: c.size_t) -> c.size_t ---
    zip_is64 :: proc(zip: ^Zip) -> c.bool ---
    zip_entry_index :: proc(zip: ^Zip) -> c.int ---
    zip_entry_isdir :: proc(zip: ^Zip) -> c.bool ---
    zip_entry_comp_size :: proc(zip: ^Zip) -> c.ulonglong ---
    zip_entry_uncomp_size :: proc(zip: ^Zip) -> c.ulonglong ---
    zip_entry_crc32 :: proc(zip: ^Zip) -> c.uint ---
    zip_entry_write :: proc(zip: ^Zip, buf: [^]u8, size: c.size_t) -> ZipError ---
    zip_entry_fwrite :: proc(zip: ^Zip, filename: cstring) -> ZipError ---
    zip_entry_read :: proc(zip: ^Zip, buf: ^[^]u8, buf_size: ^c.size_t) -> ZipError --- 
    zip_entry_noallocread :: proc(zip: ^Zip, buf: [^]u8, buf_size: c.size_t) -> ZipError --- 
    zip_entry_fread :: proc(zip: ^Zip, filename: cstring) -> ZipError ---
    zip_create :: proc(zipname: cstring, filenames: ^cstring, len: c.size_t) -> ZipError ---
    zip_extract :: proc(zipname: cstring, dir: cstring, callback: proc "c" (cstring, rawptr) -> c.int, arg: rawptr) -> ZipError --- 
    
}
ZipError :: enum c.int {
    ENONE = 0,
    ENOINIT = -1,      // not initialized
    EINVENTNAME = -2,  // invalid entry name
    ENOENT = -3,       // entry not found
    EINVMODE = -4,     // invalid zip mode
    EINVLVL = -5,      // invalid compression level
    ENOSUP64 = -6,     // no zip 64 support
    EMEMSET = -7,      // memset error
    EWRTENT = -8,      // cannot write data to entry
    ETDEFLINIT = -9,   // cannot initialize tdefl compressor
    EINVIDX = -10,     // invalid index
    ENOHDR = -11,      // header not found
    ETDEFLBUF = -12,   // cannot flush tdefl buffer
    ECRTHDR = -13,     // cannot create entry header
    EWRTHDR = -14,     // cannot write entry header
    EWRTDIR = -15,     // cannot write to central dir
    EOPNFILE = -16,    // cannot open file
    EINVENTTYPE = -17, // invalid entry type
    EMEMNOALLOC = -18, // extracting data using no memory allocation
    ENOFILE = -19,     // file not found
    ENOPERM = -20,     // no permission
    EOOMEM = -21,      // out of memory
    EINVZIPNAME = -22, // invalid zip archive name
    EMKDIR = -23,      // make dir error
    ESYMLINK = -24,    // symlink error
    ECLSZIP = -25,     // close archive error
    ECAPSIZE = -26,    // capacity size too small
    EFSEEK = -27,      // fseek error
    EFREAD = -28,      // fread error
    EFWRITE = -29,     // fwrite error
}

Zip :: struct {}
OpenMode :: enum {
    Read = 'r',
    Create = 'w',
    Append = 'a',
}
entry_write_to_file :: proc(zip: ^Zip, filename: string) -> ZipError {
    name := strings.clone_to_cstring(filename)
    defer delete(name)
    return zip_entry_fread(zip, name)
}
entry_write :: proc(zip: ^Zip, buf: []u8) -> ZipError {
    return zip_entry_write(zip, slice.as_ptr(buf), len(buf))
}
compress_file_to_entry :: proc(zip: ^Zip, file: string) -> ZipError {
    name := strings.clone_to_cstring(file)
    defer delete(name)
    return zip_entry_fwrite(zip, name)
}

is_64 :: proc(zip: ^Zip) -> (bool, ZipError) {
    res := int(zip_is64(zip))
    if res >= 0 {
        return bool(res), ZipError.ENONE
    }
    else {
        return false, ZipError(res)
    }
    
}
is_dir :: proc(zip: ^Zip) -> (bool, ZipError) {
    res := int(zip_entry_isdir(zip))
    if res >= 0 {
        return bool(res), ZipError.ENONE
    }
    else {
        return false, ZipError(res)
    }
    
}
entry_read_to :: proc(zip: ^Zip, buf: []u8) -> (int, ZipError) {
    res := zip_entry_noallocread(zip, slice.as_ptr(buf), len(buf))
    if int(res) < 0 {
        return 0, res
    } else {
        return int(res), ZipError.ENONE
    }
}
entry_read :: proc(zip: ^Zip) -> ([]u8, ZipError) {
    size := entry_uncompressed_size(zip)
    buf := make([]u8, size) 
    read, err := entry_read_to(zip, buf)
    if err != .ENONE {
        delete(buf)
        return nil, err
    } else {
        return buf[:read], ZipError.ENONE
    }
    
}
entry_crc32 :: proc(zip: ^Zip) -> uint {
    return uint(zip_entry_crc32(zip))
}
entry_uncompressed_size :: proc(zip: ^Zip) -> uint {
    return uint(zip_entry_uncomp_size(zip))
}
entry_compressed_size :: proc(zip: ^Zip) -> uint {
    return uint(zip_entry_comp_size(zip))
}
strerror :: proc(err: ZipError) -> string {
    return strings.clone_from_cstring(zip_strerror(err))    
}
open :: proc(zip_name: string, level: int, mode: OpenMode) -> ^Zip {
    name := strings.clone_to_cstring(zip_name)
    defer delete(name)
    return zip_open(name, c.int(level), u8(mode))
}
entry_open :: proc(zip: ^Zip, entry: string, case_sensitive: bool = false) -> ZipError {
    entry_name := strings.clone_to_cstring(entry)
    defer delete(entry_name)
    if case_sensitive {
        return zip_entry_opencasesensitive(zip, entry_name)
    }
    else {
        return zip_entry_open(zip, entry_name)
    }
    
}
entry_index :: proc(zip: ^Zip) -> (int, ZipError) {
    res := int(zip_entry_index(zip))
    if res >= 0 {
        return int(res), ZipError.ENONE
    }
    else {
        return 0, ZipError(res)
    }
}
entries_total :: proc(zip: ^Zip) -> (int, ZipError) {
    res := int(zip_entries_total(zip))
    if res >= 0 {
        return int(res), ZipError.ENONE
    }
    else {
        return 0, ZipError(res)
    }
}
entry_name :: proc(zip: ^Zip) -> string {
    name := zip_entry_name(zip)
    return strings.clone_from_cstring(name)
}
entry_close :: proc(zip: ^Zip) -> ZipError {
    return zip_entry_close(zip)
}
entry_open_by_index :: proc(zip: ^Zip, index: int) -> ZipError {
    return zip_entry_openbyindex(zip, c.size_t(index))
}
alloc :: proc (size: int) -> rawptr {
    when ODIN_OS == .Windows {
        bytes, ok := mem.alloc(size)
        if ok != .None {
            panic("failed to allocate memory")
        }
        return bytes
    }
    else {
        return mem.alloc(size)
    }
}
create :: proc(zip_name: string, files: []string) -> ZipError {
    zipname := strings.clone_to_cstring(zip_name)
    defer delete(zipname)
    c_entries := transmute([^]cstring)alloc(len(files) * 8);
    for file, i in files {
        c_entries[i] = strings.clone_to_cstring(file)
    }
    defer {
        for c_entry in 0..<len(files) { 
            delete(c_entries[c_entry])
        }
        mem.free(c_entries)
    }
    return zip_create(zipname, c_entries, len(files))
}
entries_delete :: proc(zip: ^Zip, entries: []string) -> (int, ZipError) {
    c_entries := transmute([^]cstring)alloc(len(entries) * 8);
    for entry, i in entries {
        c_entries[i] = strings.clone_to_cstring(entry)
    }
    defer {
        for c_entry in 0..<len(entries) { 
            delete(c_entries[c_entry])
        }
        mem.free(c_entries)
    }
    res := zip_entries_delete(zip, c_entries, len(entries))
    if res >= 0 {
        return int(res), ZipError.ENONE
    }
    else {
        return 0, ZipError(res)
    }
}
close :: proc(zip: ^Zip) {
    zip_close(zip)
}
extract :: proc(zip_name: string, dir: string, callback: proc "c" (cstring, rawptr) -> c.int, callback_arg: rawptr) -> ZipError {
    name := strings.clone_to_cstring(zip_name)
    dir := strings.clone_to_cstring(dir)
    defer {
        delete(name)
        delete(dir)
    }
    return zip_extract(name, dir, callback, callback_arg)
}
