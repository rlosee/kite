#-----------------------------------------------------------------------
# TITLE:
#   project.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite: kiteapp(n) project file reader/writing
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# project ensemble

snit::type project {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Constants
    
    # The project file name.
    typevariable projfile "project.kite"

    #-------------------------------------------------------------------
    # Constants

    # Default src -build and -clean scripts

    typevariable defaultBuild "make clean all"
    typevariable defaultClean "make clean"
    

    #-------------------------------------------------------------------
    # Type variables

    # The project's root directory

    typevariable rootdir ""

    # info - the project info array
    #
    #   name           - The project name
    #   version        - The version number, x.y.z
    #   description    - The project title
    #   poc            - Point-of-contact e-mail address
    #   shell          - Shell initialization script for "kite shell -plain"
    #
    #   apps           - List of project app names, or "" if none.
    #   apptype-$app   - kit or exe
    #   gui-$app       - 1 or 0
    #
    #   provides       - List of provided library package names
    #   binary-$name   - 1 if package is binary, and 0 otherwise.
    #
    #   requires       - Names of required teapot packages
    #   reqver-$name   - Version of required package $name
    #   local-$name    - 1 if this is a local package, and 0 otherwise.
    #
    #   srcs           - Names of "src" targets
    #   build-$src     - Script to build contents of $src
    #   clean-$src     - Script to clean contents of $src
    #
    #   dists          - Names of distribution targets.
    #   distpat-$dist  - List of path patterns for $dist.
    #
    # If values are "", the data has not yet been loaded.

    typevariable info -array {
        name           ""
        version        ""
        description    ""
        poc            ""
        apps           ""
        provides       {}
        requires       {}
        srcs           {}
        dists          {}
        shell          {}
    }

    #-------------------------------------------------------------------
    # File and Directory Queries

    # newroot name
    #
    # name   - A project name
    #
    # Creates a new project root directory with the given name, and 
    # CD's into it.  Does not load or simulate any project metadata.

    typemethod newroot {name} {
        set rootdir [file join [pwd] $name]
        file mkdir $rootdir
    }

    # root ?names...?
    #
    # Find and return the directory containing the project.kite file, which
    # by definition is the top directory for the project.  Cache the
    # name for later.  If "names..." are given, join them to the 
    # dir name and return that.
    #
    # Returns "" if the project directory cannot be found.

    typemethod root {args} {
        if {$rootdir eq ""} {
            # Find the project directory, throwing an error if not found.
            set rootdir [FindProjectDirectory]   
        }

        if {$rootdir eq ""} {
            return ""
        }

        return [file join $rootdir {*}$args]
    }

    # globroot ?patterns...?
    #
    # patterns - A list of path components, possibly containing wildcards.
    #
    # Joins the patterns to the project root directory, and does a 
    # glob -nocomplain, returning the resulting list.

    typemethod globroot {args} {
        glob -nocomplain [$type root {*}$args]
    }

    # globdirs ?patterns...?
    #
    # patterns - A list of path components, possibly containing wildcards.
    #
    # Joins the patterns to the project root directory, and does a 
    # glob -nocomplain, returning the directory names in the resulting
    # list.

    typemethod globdirs {args} {
        set result [list]
        foreach name [$type globroot {*}$args] {
            if {[file isdirectory $name]} {
                lappend result $name
            }
        }

        return $result
    }

    # globfiles ?patterns...?
    #
    # patterns - A list of path components, possibly containing wildcards.
    #
    # Joins the patterns to the project root directory, and does a 
    # glob -nocomplain, returning the names of the normal files 
    # from the resulting list.

    typemethod globfiles {args} {
        set result [list]
        foreach name [$type globroot {*}$args] {
            if {[file isfile $name]} {
                lappend result $name
            }
        }

        return $result
    }

    # FindProjectDirectory
    #
    # Starting from the current working directory, works its way up
    # the tree looking for project.kite; if found it returns the 
    # directory containing project.kite, and "" otherwise.

    proc FindProjectDirectory {} {
        set lastdir ""
        set nextdir [pwd]

        while {$nextdir ne $lastdir} {
            set candidate [file join $nextdir $projfile]

            try {
                if {[file exists $candidate]} {
                    return $nextdir
                }

                set lastdir $nextdir
                set nextdir [file dirname $lastdir]
            } on error {} {
                # Most likely, we got to directory we can't read.
                break
            }
        }

        return ""
    }

    #-------------------------------------------------------------------
    # Metadata Queries

    # getinfo
    #
    # Returns a raw dictionary of all project metadata.  Note that
    # this format can change without notice!

    typemethod getinfo {} {
        return [array get info]
    }

    # name
    #
    # Returns the project name.

    typemethod name {} {
        return $info(name)
    }

    # version
    #
    # Returns the project version string.

    typemethod version {} {
        return $info(version)
    }

    # description
    #
    # Returns the project description.

    typemethod description {} {
        return $info(description)
    }

    # poc
    #
    # Returns the project POC.

    typemethod poc {} {
        return $info(poc)
    }

    # intree
    #
    # Returns 1 if we're in a project tree, and 0 otherwise.

    typemethod intree {} {
        return [expr {$rootdir ne ""}]
    }

    # hasinfo
    #
    # Returns 1 if we've successfully loaded project info, and
    # 0 otherwise.

    typemethod hasinfo {} {
        return [expr {$info(name) ne ""}]
    }

    # app names
    #
    # Returns the list of project app names, if any.

    typemethod {app names} {} {
        return $info(apps)
    }

    # app primary
    #
    # Returns the primary application name, or ""

    typemethod {app primary} {} {
        return [lindex $info(apps) 0]
    }

    # app apptype app
    #
    # app - The application name
    #
    # Returns the apptype, kit|exe

    typemethod {app apptype} {app} {
        return $info(apptype-$app)
    }

    # app gui app
    #
    # app - The application name
    #
    # Returns the app's GUI flag, 1 or 0.

    typemethod {app gui} {app} {
        return $info(gui-$app)
    }


    # app loader app
    #
    # app - The application name
    #
    # Returns the project's application loader script.

    typemethod {app loader} {app} {
        return [project root bin $app.tcl]
    }

    # app exefile app
    #
    # app - The application name
    #
    # Returns the app's executable file, given its app type and
    # the platform.

    typemethod {app exefile} {app} {
        if {[project app apptype $app] eq "kit"} {
            return $app.kit
        } elseif {[project app apptype $app] eq "exe"} {
            return [os exefile $app-[os flavor]]
        } else {
            error "Unknown application type"
        }
    }

    # provide names
    #
    # Returns the list of provide names.

    typemethod {provide names} {} {
        return $info(provides)
    }

    # provide binary name
    #
    # name - Name of the provided library
    #
    # Returns 1 if the library has a binary component, and 0 otherwise.

    typemethod {provide binary} {name} {
        return $info(binary-$name)
    }

    # provide zipfile name
    #
    # name - The name of the library's teapot .zip package on this
    # platform.

    typemethod {provide zipfile} {name} {
        set ver [project version]
        
        if {[project provide binary $name]} {
            set plat [platform::identify]
        } else {
            set plat "tcl"
        }

        return "package-$name-$ver-$plat.zip"
    }

    # require names
    #
    # Returns the list of required package names.

    typemethod {require names} {} {
        return $info(requires)
    }

    # require version name
    #
    # name  - the require name
    #
    # Returns the required package's version.

    typemethod {require version} {name} {
        return $info(reqver-$name)
    }

    # require islocal name
    #
    # name  - the require name
    #
    # Returns 1 if the required package is internally built.

    typemethod {require islocal} {name} {
        return $info(local-$name)
    }

    # src names
    #
    # Returns the list of "src" directory names.

    typemethod {src names} {} {
        return $info(srcs)
    }

    # src build src
    #
    # src  - A src directory name, as returned by [project src names]
    # 
    # Returns the "build" script.

    typemethod {src build} {src} {
        return $info(build-$src)
    }

    # src clean src
    #
    # src  - A src directory name, as returned by [project src names]
    # 
    # Returns the "clean" script.

    typemethod {src clean} {src} {
        return $info(clean-$src)
    }

    # dist names
    #
    # Returns the list of "dist" target names.

    typemethod {dist names} {} {
        return $info(dists)
    }

    # dist patterns dist
    #
    # dist  - A dist target name, as returned by [project dist names]
    # 
    # Returns the list of file patterns.

    typemethod {dist patterns} {dist} {
        return $info(distpat-$dist)
    }

    # shell
    #
    # Returns the shell initialization script.

    typemethod shell {} {
        return $info(shell)
    }

    # libpath
    #
    # Returns a Tcl list of library directories associated with this 
    # project.

    typemethod libpath {} {
        return [list [project root lib]]
    }

    # zippath
    #
    # Returns the path where "kite build" puts teapot .zip packages,
    # creating the directory if needed.

    typemethod zippath {} {
        set path [project root .kite libzips]
        file mkdir $path
        return $path
    }

    

    #-------------------------------------------------------------------
    # Reading the information from the project file.

    # loadinfo
    #
    # Loads the information from the project file.  We must be
    # in a project tree.

    typemethod loadinfo {} {
        # FIRST, set up the safe interpreter
        # TODO: Use a smartinterp(n), once we can claim Mars as an
        # external dependency.
        set safe [interp create -safe]
        $safe alias project [myproc ProjectCmd]
        $safe alias poc     [myproc PocCmd]
        $safe alias app     [myproc AppCmd]
        $safe alias provide [myproc ProvideCmd]
        $safe alias require [myproc RequireCmd]
        $safe alias src     [myproc SrcCmd]
        $safe alias dist    [myproc DistCmd]
        $safe alias shell   [myproc ShellCmd]


        # NEXT, try to load the file
        try {
            $safe eval [readfile [$type root $projfile]]
        } trap INVALID {result} {
            throw FATAL "Error in project.kite: $result"
        } trap SYNTAX {result} {
            throw FATAL "Error in project.kite: $result"
        } trap {TCL WRONGARGS} {result} {
            # Assume this is in the project.kite file
            throw FATAL "Error in project.kite: $result"
        } trap FATAL {result} {
            throw FATAL $result
        } on error {result eopts} {
            # This will result in a stack trace; add cases above
            # for things we find that aren't really project.kite errors.
            return {*}$eopts $result
        } finally {
            interp delete $safe            
        }

        # NEXT, if the project name has not been set, throw an
        # error.

        if {$info(name) eq ""} {
            throw FATAL "No project defined in $projfile"
        }
    }

    # ProjectCmd name version description
    #
    # Implementation of the "project" kite file command.

    proc ProjectCmd {name version description} {
        prepare name        -required -tolower
        prepare version     -required
        prepare description -required

        if {![BaseName? $name]} {
            throw SYNTAX "Invalid project name: \"$name\""
        }

        if {![Version? $version]} {
            throw SYNTAX "Invalid version number: \"$version\""
        }

        set info(name)        $name
        set info(version)     $version
        set info(description) $description
    }
    
    # PocCmd poc
    #
    # Implementation of the "poc" kite file command.

    proc PocCmd {poc} {
        prepare poc -required

        set info(poc)  $poc
    }

    # AppCmd name ?options...?
    #
    # Implementation of the "app" kite file command.

    proc AppCmd {name args} {
        # FIRST, validate the name.
        set name [string trim [string tolower $name]]

        if {![regexp {^[a-z]\w*$} $name]} {
            throw SYNTAX "Invalid app name \"$name\""
        }

        if {$name in $info(apps)} {
            throw SYNTAX "App name \"$name\" appears more than once in project.kite."
        }

        # NEXT, get the options
        set apptype kit
        set gui     0

        foroption opt args -all {
            -apptype {
                set apptype [lshift args]

                if {$apptype ni {kit exe}} {
                    throw SYNTAX \
                        "Invalid -apptype: \"$apptype\""
                }
            }
            -gui {
                set gui 1
            }
        }


        lappend info(apps)          $name
        set     info(apptype-$name) $apptype
        set     info(gui-$name)     $gui
    }

    # add app name ?options?
    #
    # name    - The app name
    # Options - As for AppCmd
    #
    # Adds another app to the existing project info.

    typemethod {add app} {name args} {
        try {
            AppCmd $name {*}$args
        } trap SYNTAX {result} {
            throw FATAL $result
        }
    }

    # ProvideCmd name args
    #
    # name   - The name of the library package and its directory.
    #          E.g., "kiteutils".
    #
    # Options:
    #
    #    -binary    - The package isn't pure-Tcl.
    #
    # Implementation of the "lib" kite file command.  

    proc ProvideCmd {name args} {
        # FIRST, get the name.
        set name [string trim $name]

        if {![regexp {^[a-zA-Z]\w*$} $name]} {
            throw SYNTAX "Invalid lib name \"$name\""
        }

        if {$name in $info(provides)} {
            throw SYNTAX "Duplicate lib name \"$name\""
        }

        # NEXT, get the options
        set binary 0

        foroption opt args -all {
            -binary { set binary 1 }
        }


        lappend info(provides)     $name
        set     info(binary-$name) $binary
    }

    # add lib name ?options?
    #
    # name    - The lib name
    # Options - As for ProvideCmd
    #
    # Adds another lib to the existing project info.

    typemethod {add lib} {name args} {
        try {
            ProvideCmd $name {*}$args
        } trap SYNTAX {result} {
            throw FATAL $result
        }
    }

    # RequireCmd name version ?options?
    #
    # name      - The name of the teapot package
    # version   - The version number of the teapot package
    # options   - Any options.
    #
    # Options:
    #    -local   - If so, the project is locally built, and cannot
    #               be retrieved from the ActiveState teapot.
    #
    # States that the project depends on the given package from 
    # a teapot repository.

    proc RequireCmd {name version args} {
        if {$name in $info(requires)} {
            throw SYNTAX "Duplicate require name: \"$name\""
        }

        set local 0

        foroption opt args {
            -local { set local 1 }
        }

        ladd info(requires)    $name
        set info(reqver-$name) $version
        set info(local-$name)  $local
    }

    # SrcCmd name ?options...?
    #
    # name   - The name of the src/* directory
    #
    # Options:
    #
    #   -build script  - Shell script to build contents.
    #   -clean script  - Shell script to clean contents.
    #
    # Implementation of the "src" kite file command.  Specifies the
    # name of a src/<name> directory.  Kite assumes the directory contains
    # a Makefile; however, the project can customize the build and clean
    # scripts.

    proc SrcCmd {name args} {
        # FIRST, get the name.
        set name [string trim $name]

        if {![regexp {^[a-zA-Z]\w*$} $name]} {
            throw SYNTAX "Invalid src directory name \"$name\""
        }

        if {$name in $info(srcs)} {
            throw SYNTAX "Duplicate src directory \"$dir\""
        }

        # NEXT, get the options
        set info(build-$name) "make clean all"
        set info(clean-$name) "make clean"

        foroption opt args {
            -build { set info(build-$name) [lshift args] }
            -clean { set info(clean-$name) [lshift args] }
        }

        lappend info(srcs) $name
    }

    # DistCmd name patterns
    #
    # name     - The name of the distribution target, e.g., "install".
    # patterns - List of path patterns for files to include.
    #
    # Implementation of the "dist" kite file command.  

    proc DistCmd {name patterns} {
        # FIRST, get the name.
        set name [string trim $name]

        if {![regexp {^[a-zA-Z]\w*$} $name]} {
            throw SYNTAX "Invalid distribution name \"$name\""
        }

        if {$name in $info(dists)} {
            throw SYNTAX "Duplicate distribution name \"$name\""
        }

        lappend info(dists)         $name
        set     info(distpat-$name) $patterns
    }


    # ShellCmd script
    #
    # Implementation of the "shell" kite file command.

    proc ShellCmd {script} {
        set info(shell) $script
    }

    # BaseName? name
    #
    # name   - A base file name, e.g., <base>.kit.
    #
    # Validates the name; it may contain letters, numbers, underscores,
    # and hyphens, and should begin with a letter.

    proc BaseName? {name} {
        return [regexp {^[a-z][[:alnum:]_-]*$} $name]
    }

    # Version? ver
    #
    # ver   - A Tcl version number, e.g, 1.2.3 or 1.2.3b2
    #
    # Validates the version, which must be a valid Tcl package 
    # version number.

    proc Version? {ver} {
        return [regexp {^(\d[.])*\d[.ab]\d$} $ver]
    }

    #-------------------------------------------------------------------
    # Saving project.kite with current metadata.

    typemethod save {} {
        # FIRST, build up the contents.
        set script [list]

        lappend script \
            "# project.kite" \
            [list project $info(name) $info(version) $info(description)]

        if {$info(poc) ne ""} {
            lappend script [list poc $info(poc)]
        }
            
        
        if {[llength $info(apps)] > 0} {
            lappend script "" "# Applications"

            foreach name $info(apps) {
                set item [list app $name -apptype $info(apptype-$name)]

                if {$info(gui-$name)} {
                    lappend item -gui
                }

                lappend script $item
            }
        }

        if {[llength $info(provides)] > 0} {
            lappend script "" "# Provided Libraries"

            foreach name $info(provides) {
                set item [list provide $name]

                if {$info(binary-$name)} {
                    lappend item -binary
                }

                lappend script $item
            }
        }

        if {[llength $info(srcs)] > 0} {
            lappend script "" "# Compiled Directories"

            foreach name $info(srcs) {
                set item [list src $name]

                if {$info(build-$name) ne $defaultBuild} {
                    lappend item -build $info(build-$name)
                }

                if {$info(clean-$name) ne $defaultClean} {
                    lappend item -clean $info(clean-$name)
                }

                lappend script $item
            }
        }

        if {[llength $info(requires)] > 0} {
            lappend script "" "# External Dependencies"

            foreach name $info(requires) {
                set item [list require $name $info(reqver-$name)]

                if {$info(local-$name)} {
                    lappend item -local
                }

                lappend script $item
            }
        }

        if {$info(dists) ne ""} {
            lappend script "" "# Distribution Targets"
            foreach name $info(dists) {
                lappend script [list dist $name $info(distpat-$name)]
            }
        }

        if {$info(shell) ne ""} {
            lappend script "" "# Shell Initialization"
            lappend script [list shell $info(shell)]
        }

        lappend script ""

        # NEXT, write it all out.
        try {
            file copy -force \
                [project root project.kite] \
                [project root project.bak]
            writefile [project root project.kite] [join $script \n]
        } on error {result} {
            throw FATAL "Could not save new project.kite:\n$result"
        }
    }
}





