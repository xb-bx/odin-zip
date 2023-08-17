package nobuild
import "core:os"

main :: proc() {
    if !os.exists("libzip") {
        run("git", "clone", "https://github.com/kuba--/zip", "libzip")
    }
    if !os.exists("libzip/libzip.a") {
        cd("libzip")
        run("cmake", ".")
        run("cmake", "--build", ".")
        cd("..")
    }
    run("odin", "build", "src/zfm", "-out:zfm", "-collection:zip=src", "-collection:libzip=libzip")
}
