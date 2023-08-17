package zfm
import "core:fmt"
import "core:os"
import "zip:zip"
import "core:strings"
import "core:mem"
import "core:slice"
import "core:runtime"
import "core:c"


print_usage :: proc() {
    fmt.println("usage: zfm <command> <zip file> [args]")
    fmt.println("commands:")
    fmt.println("   list    <zip file>                   : list all files in zip archive")
    fmt.println("   add     <zip file> <file1, file2 ...>: add files to archive")
    fmt.println("   remove  <zip file> <file1, file2 ...>: remove files from archive")
    fmt.println("   create  <zip file> <file1, file2 ...>: create archive with files")
    fmt.println("   extract <zip file> <output directory>: extracts file from archive")
}    
list_files :: proc(args: []string) {
    if len(args) < 1 {
        print_usage()
        return
    }
    zip_file := zip.open(args[0], 0, zip.OpenMode.Read)
    if zip_file == nil {
        fmt.println("Cannot open file")
        return
    }
    total, error := zip.entries_total(zip_file)
    if error != .ENONE {
        fmt.println(zip.strerror(error))
        return
    }
    for i in 0..<total {
        zip.entry_open_by_index(zip_file, i)
        name := zip.entry_name(zip_file)
        defer delete(name)
        fmt.println(name)
    }
}
add_files :: proc(args: []string) {
    if len(args) < 2 {
        print_usage()
        return
    }
    zip_file := zip.open(args[0], 0, zip.OpenMode.Append)
    if zip_file == nil {
        fmt.println("Cannot open file")
        return
    }
    for arg in args[1:] {
        err := zip.entry_open(zip_file, arg, false)
        if err != .ENONE {
            fmt.println(zip.strerror(err))
            return
        }
        err = zip.compress_file_to_entry(zip_file, arg)
        if err != .ENONE {
            fmt.println(zip.strerror(err))
            return
        }
        err = zip.entry_close(zip_file)
        if err != .ENONE {
            fmt.println(zip.strerror(err))
            return
        }
    }
    zip.close(zip_file)    
    
}
remove_files :: proc(args: []string) {
    if len(args) < 2 {
        print_usage()
        return
    }
    zip_file := zip.open(args[0], 0, zip.OpenMode.Append)
    if zip_file == nil {
        fmt.println("Cannot open file")
        return
    }
    deleted, error := zip.entries_delete(zip_file, args[1:])
    if error != .ENONE {
        fmt.println(zip.strerror(error))
        return
    }
    fmt.println("Deleted", deleted, "entries")
    zip.close(zip_file)
}
create :: proc(args: []string) {
    if len(args) < 2 {
        print_usage()
        return
    }
    err := zip.create(args[0], args[1:])  
    if err != .ENONE {
        fmt.println(zip.strerror(err))
    }
}
print_file :: proc "c" (name: cstring, arg: rawptr) -> c.int {
    context = (transmute(^runtime.Context)arg)^
    fmt.println(name)
    return 0
}
extract :: proc(args: []string) {
    if len(args) < 2 {
        print_usage()
        return
    }
    ctx := context
    err := zip.extract(args[0], args[1], print_file, &ctx)
    if err != .ENONE {
        fmt.println(zip.strerror(err))
    }
}
main :: proc() {
    if len(os.args) == 1 {
        print_usage()
        return
    }
    args := os.args[1:]
    switch args[0] {
        case "list": 
            list_files(args[1:])
        case "add":
            add_files(args[1:])
        case "remove":
            remove_files(args[1:])
        case "create":
            create(args[1:])
        case "extract":
            extract(args[1:])
    }
}
