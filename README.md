# cordova-plugin-file-md5
Cordova MD5 checksum plugin for Android and iOS.
The plugin reads large files in chunks and builds the md5sum incrementally.
It can handle large files.

## install
```
yourAppDir$ cordova plugin add https://github.com/lifecareimaging/cordova-plugin-file-md5.git
```

## usage
``fileEntry`` is a ``org.apache.cordova.file.FileEntry``
```
function win(md5sum){
    console.log("MD5SUM: " + md5sum);
}
function fail(error){
    console.log("Error-Message: " + error);
}
md5chksum.file(fileEntry, win, fail);
```
