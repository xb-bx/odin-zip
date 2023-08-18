# odin-zip is a binding to [zip](https://github.com/kuba--/zip) library

## Building

On windows:
```
    build.bat
```
On Linux:
```
    ./build.sh
```

## Example

You can see example application in src/zfm


## How to use
1. Clone this repo to your project.
2. Run build.sh or build.bat to build c library
3. To your odin build add "-collection:zip=odin-zip/src" and "-collection:libzip=odin-zip/libzip"
4. import zip library in your code:
```odin
import "zip:zip"
```
