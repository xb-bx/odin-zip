package nobuild
import "core:os"


when ODIN_OS == .Windows {
    ZFM :: "zfm.exe"
    LIBZIP :: "zip.lib"
} else {
    ZFM :: "zfm"
    LIBZIP :: "libzip.a"
}


main :: proc() {
    if !os.exists("libzip") {
        run("git", "clone", "https://github.com/kuba--/zip", "libzip")
    }
    if !os.exists("libzip/" + LIBZIP){
        cd("libzip")
        when ODIN_OS == .Linux {
            run("gcc", "-c",  "src/zip.c", "-o", "zip.o")
            run("ar", "rcs", "libzip.a", "zip.o")
        }
        else {
            run("cl", "/c", "src/zip.c")
            run("lib", "zip.obj")
        }
        cd("..")
    }
    odin_build("src/zfm", collections = { "zip" = "src", "libzip" = "libzip" }, output = ZFM)
}
