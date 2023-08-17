package nobuild
import "core:os"

main :: proc() {
    if !os.exists("zip") {
        run("git", "clone", "https://github.com/kuba--/zip", "libzip")
    }
    cd("libzip")
    run("cmake", ".")
    run("cmake", "--build", ".")
    cd("..")
    run("odin", "build", "src/zfm", "-out:zfm", "-collection:zip=src", "-collection:libzip=libzip")
}
