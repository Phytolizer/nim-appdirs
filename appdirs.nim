from std/os import `/`
import std/options
import std/strutils

## Appdirs is a small module that finds the dirs for you to app in.
##
## More specifically, appdirs contains a number of functions that will return the
## correct directory for the platform you are on.  (All functions also allow you
## to override the platform.)  Note that these directories are simply strings
## naming possible directories.  You will need to ensure that the directory you
## wish to use is available yourself.
##
## There are generally three procs for each type of directory.  The first will
## return the base directory, whilst the other two will return the specific
## directory for a given application.  Of the more specialised procs, one takes
## a `TAppl` object (initialised using the `application()` proc) and the other
## takes all the arguments required to create a `TAppl` object, creates and
## initialises one under the hood, and then uses that in this function.  It is
## generally recommended to use the `TAppl` proc in most circumstances.
##
## This module assumes that the available OSs are either Windows or Mac OSX, or
## otherwise a "UNIX-y" variant.  This should cover most operating systems.
## There are no checks in place for systems that don't fall into the standard
## range of operating systems, but if you're in that situation you probably
## don't need this module.



type
    TAppl* = object of RootObj
        name*: string
        author*: string
        version*: Option[string]
        useRoaming*: bool

# USEFUL PROCS

proc getPlatform(platform: Option[string] = none[string]()): string {.inline noSideEffect.} =
    platform.get(hostOS)

proc emptyExists(name: string): bool {.inline.} =
    os.existsEnv(name) and os.getEnv(name).strip != ""


# TAPPL CONSTRUCTOR

proc application*(
    name: string, 
    author: Option[string] = none[string](), 
    version: Option[string] = none[string](), 
    roaming: bool = false
): TAppl  = 
    ## Constructs a TAppl object with given args.
    ##
    ## The only required arg is `name`.  If `author` is not given, it defaults to `name`.  This is only
    ## used on Windows machines, in which case the application directory will sit inside the author
    ## directory.  On other platforms, `author` is ignored.
    ##
    ## If `version` is given, it is appended to any resultant directory.  This allows an application to
    ## have multiple versions installed on one computer.
    ##
    ## The `roaming` arg is also for Windows systems only, and decides if the directory can be shared
    ## on any computer in a Windows network (roaming=true) or if it will be kept locally
    ## (roaming=false).  Note that the cache and logs directory will always be kept locally.

    let auth = author.get(name)

    result = TAppl(
        name: name, 
        author: auth, 
        version: version,
        useRoaming: roaming
    )


# USER DATA

proc userData*(roaming: bool = false, platform: Option[string] = none[string]()): string =
    ## Returns the generic user data directory for a given platform.
    ## The platform defaults to the current platform.

    let plat = getPlatform(platform)

    case plat
    of "macosx":
        return os.getEnv("HOME") / "Library" / "Application Support"
    of "windows":
        if (not roaming) and os.existsEnv("LOCALAPPDATA"):
            return os.getEnv("APPDATA")
        else:
            return os.getEnv("LOCALAPPDATA")
    else:
        if emptyExists("XDG_DATA_HOME"):
            return os.getEnv("XDG_DATA_HOME")
        else:
            return os.getEnv("HOME") / ".local" / "share"

proc userData*(appl: TAppl, platform: Option[string] = none[string]()): string =
    ## Returns the user data directory for a given app for a given platform.
    ## The platform defaults to the current platform.

    var path = userData(appl.useRoaming, platform)

    if getPlatform(platform) == "windows":
        path = path / appl.author / appl.name
    else:
        path = path / appl.name

    if appl.version.isSome:
        path = path / appl.version.get

    return path

proc userData*(
    name: string, 
    author: Option[string] = none[string](), 
    version: Option[string] = none[string](), 
    roaming: bool = false, 
    platform: Option[string] = none[string]()
): string  = 
    ## Gets the data directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userData(TAppl)` proc.
    return application(name, author, version, roaming).userData(platform)


# USER CONFIG

proc userConfig*(roaming: bool = false, platform: Option[string] = none[string]()): string =
    ## Returns the generic user config directory for a given platform.
    ## The platform defaults to the current platform.

    let plat = getPlatform(platform)

    if plat == "macosx" or plat == "windows":
        return userData(roaming, some(plat))
    else:
        if emptyExists("XDG_CONFIG_HOME"):
            return os.getEnv("XDG_CONFIG_HOME")
        else:
            return os.getEnv("HOME") / ".config"

proc userConfig*(appl: TAppl, platform: Option[string] = none[string]()): string =
    ## Returns the user config directory for a given app for a given platform.
    ## The platform defaults to the current platform.

    var path = userConfig(appl.useRoaming, platform)

    if getPlatform(platform) == "windows":
        path = path / appl.author / appl.name
    else:
        path = path / appl.name

    if appl.version.isSome:
        path = path / appl.version.get

    return path

proc userConfig*(
    name: string, 
    author: Option[string] = none[string](), 
    version: Option[string] = none[string](), 
    roaming: bool = false, 
    platform: Option[string] = none[string]()
): string  = 
    ## Gets the config directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userConfig(TAppl)` proc.
    return application(name, author, version, roaming).userConfig(platform)


# USER CACHE

proc genericUserCache(platform: Option[string] = none[string]()): string =
    ## Gets the local users' cache directory.
    ##
    ## Note, on Windows there is no "official" cache directory, so instead this procedure
    ## returns the users's Application Data folder.    Use the `userCache(TAppl)` version
    ## to with `forceCache = true` to add an artifical `Cache` directory inside your
    ## main appdata directory.
    ##
    ## On all other platforms, there is a cache directory to use.

    var plat = getPlatform(platform)

    case plat
    of "windows":
        return userData(false, platform)
    of "macosx":
        return os.getEnv("HOME") / "Library" / "Caches"
    else:
        if emptyExists("XDG_CACHE_HOME"):
            return os.getEnv("XDG_CACHE_HOME")
        else:
            return os.getEnv("HOME") / ".cache"

proc userCache*(
    appl: TAppl, 
    forceCache: bool = true, 
    platform: Option[string] = none[string]()
): string =
    ## Gets the cache directory for a given application.
    ##
    ## Note, on Windows there is no "official" cache directory, so instead this procedure
    ## returns this application's Application Data folder.  If `forceCache = true` (the
    ## default) this procedure will add an artificial `Cache` directory inside the app's
    ## appdata folder.  Otherwise, this just returns the user's app data directory.
    ##
    ## On all other platforms, there is a cache directory to use.

    result = genericUserCache(platform)

    if getPlatform(platform) == "windows":
        result = result / appl.author / appl.name

        if forceCache:  # Be assertive, give windows users a real cache dir
            result = result / "Cache"
    else:
        result = result / appl.name

    if appl.version.isSome:
        result = result / appl.version.get

proc userCache*(
    name: string, 
    author: Option[string] = none[string](), 
    version: Option[string] = none[string](), 
    roaming: bool = false,
    forceCache: bool = true, 
    platform: Option[string] = none[string]()
): string = 
    ## Gets the cache directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userCache(TAppl)` proc.

    return application(name, author, version, roaming).userCache(forceCache, platform)


# USER LOGS

proc genericUserLogs(platform: Option[string] = none[string]()): string =
    ## Gets the logs directory for a given platform.
    ##
    ## Note that the only platform for which there is an official user logs directory
    ## is macosx.  On Windows, this proc returns the non-roaming user data directory,
    ## while for UNIX-y platforms this proc returns the cache directory.  See the
    ## `TAppl` version of this proc for more details.
    let plat = getPlatform(platform)

    case plat 
    of "windows":
        return userData(false, some(plat))
    of "macosx":
        return os.getEnv("HOME") / "Library" / "Logs"
    else:
        return userCache(plat)

proc userLogs*(appl: TAppl, forceLogs: bool = true, platform: Option[string] = none[string]()): string =
    ## Gets the logs directory for a platform given application details.
    ##
    ## Note that the only platform for which there is an official user logs directory
    ## is macosx.  Otherwise, this returns the user data directory (for Windows) or the
    ## user cache directory (UNIX-y platforms), with a "logs" directory appended.
    ##
    ## If forceLogs is passed in and evaluates to false, this proc does not append
    ## the extra "logs" directory.

    result = genericUserLogs(platform)

    if getPlatform(platform) == "windows":
        result = result / appl.author / appl.name

        if forceLogs:
            result = result / "Logs"
    else:
        result = result / appl.name

        if getPlatform(platform) != "macosx" and forceLogs:
            result = result / "logs"

    if appl.version.isSome:
        result = result / appl.version.get

proc userLogs*(
    name: string, 
    author: Option[string] = none[string](), 
    version: Option[string] = none[string](), 
    roaming: bool = false,
    forceLogs: bool = true, 
    platform: Option[string] = none[string]()
): string =
    ## Gets the logs directory given the details of an application.
    ## This proc creates an application from the arguments, and uses it to call the
    ## `userLogs(TAppl)` proc.

    return application(name, author, version, roaming).userLogs(forceLogs, platform)
