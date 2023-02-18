# Appdirs

*Appdirs finds the dirs for you to app in.*

## Authors

Original library is written by [MrJohz](https://github.com/MrJohz).
It has been updated for latest Nim by [Kyle Coffey](https://github.com/Phytolizer).

Original README follows.

Appdirs is a Nim port of my JS [AppDirectory](https://github.com/MrJohz/appdirectory) module, which itself is a port of the Python [appdirs](https://github.com/ActiveState/appdirs) module.  It's fairly basic, and has roughly the same API as the JS version.  The official docs can be found in the docs directory of this repo.

## Usage:

```nim
import appdirs
let app = application("AppName", "AuthorName", "version", roaming=false)

echo user_data(app)
# -> /home/user/.local/share/AppName/version

echo user_config(app, platform="windows")
# -> C:\Users\<censored>\AppData\Local\AuthorName\AppName\version
```

There are functions for the user data folder, the user config folder, the logs folder and the cache folder.  The platform can be any of the string that nim's hostOS variable can resolve to, although Appdirs only checks for "macosx" and "windows", and assumes all of the other platforms to be UNIX-y.  If this is not the case, and you have a platform that can provide sensible data, config, logs, and cache folders, fork and send me a pull request.

Documentation files are available at [http://mrjohz.github.io/appdirs/](http://mrjohz.github.io/appdirs/). More specifically you will want to read the [appdirs API](http://mrjohz.github.io/appdirs/docs/master/appdirs.html).

## To Do List:

- Add site* functions
- Get round to adding tests
