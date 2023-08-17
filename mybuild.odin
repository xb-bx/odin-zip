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
            run("cmake", ".")
            run("cmake", "--build", ".")
        }
        else {
            run("cl", "/c", "src/zip.c")
            run("lib", "zip.obj")
        }
        cd("..")
    }
    run("odin", "build", "src/zfm", "-out:" + ZFM, "-collection:zip=src", "-collection:libzip=libzip")
}
