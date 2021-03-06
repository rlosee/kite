#-----------------------------------------------------------------------
# TITLE:
#   tool_install.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite: "install" tool
#
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# tool::INSTALL

tool define install {
    usage       {0 - "?app|lib? ?<name>...?"}
    description "Build and install applications to ~/bin."
    needstree      yes
} {
    The "install" tool installs build products into the local file
    system for general use.

    Applications are installed into ~/bin, e.g., myapp.kit is installed 
    as ~/bin/myapp.  Libraries are installed in the default teapot, and  
    are then accessible to other applications on the same host.

    kite install
        Installs all libraries and applications.

    kite install app ?<name>...?
        Installs all applications, or optionally all named applications.

    kite install lib ?<name>...?
        Installs all libraries, or optionally all named libraries.
} {
    #-------------------------------------------------------------------
    # Execution

    # execute argv
    #
    # Installs the desired build targets.

    typemethod execute {argv} {
        # FIRST, get the arguments.
        set kind [lshift argv]

        if {$kind ni {"" lib app}} {
            throw FATAL "Invalid install type: \"$kind\"."
        }

        # NEXT, install any teapot packages.
        if {$kind in {lib ""}} {
            if {[llength $argv] > 0} {
                InstallProvidedLibraries $argv
            } else {
                InstallProvidedLibraries [project provide names]                
            }
        }

        # NEXT, install any applications.
        if {$kind in {app ""}} {
            if {[llength $argv] > 0} {
                set names $argv
            } else {
                set names [project app names]
            }

            foreach app $names {
                if {$app ni [project app names]} {
                    puts "WARNING, Unknown application: \"$app\""
                    continue
                }
                InstallApp $app
            }
        }
    }

    #-------------------------------------------------------------------
    # Installing Teapot Libraries
    
    # InstallProvidedLibraries names
    #
    # names  - Names of the libraries to install.
    #
    # Installs exported libraries into the local teaput.

    proc InstallProvidedLibraries {names} {
        # FIRST, make sure there's a local teapot to install them 
        # into.
        if {[teapot state] ne "ok"} {
            puts [outdent {
                WARNING: Kite cannot install project libraries,
                because the local teapot has not been set up.
                Please execute 'kite teapot' for more information.
            }]
            puts ""

            return
        }

        # NEXT, for each library, see if it has a package; and if so,
        # install it.
        foreach lib $names {
            if {$lib ni [project provide names]} {
                puts "WARNING, Unknown library: \"$lib\""
                continue
            }
            InstallLib $lib
        }
    }

    # InstallLib lib
    #
    # lib  - A lib name
    #
    # Verifies that lib has a teapot package, and installs it if so.

    proc InstallLib {lib} {
        set ver [project version]

        set basename [project provide zipfile $lib]
        set fullname [file join [project zippath] $basename]

        # FIRST, is there a package?
        if {![file isfile $fullname]} {
            puts [outdent "
                WARNING: Kite cannot install lib \"$lib\", because
                it has not been built yet.  Try 'kite build'.
            "]

            return
        }

        # NEXT, add it.
        try {
            puts "Installing lib \"$lib $ver\" into the local teapot."
            if {[deps has $lib $ver]} {
                teacup remove $lib $ver
            }

            teacup installfile $fullname
        } on error {result} {
            throw FATAL "Error installing lib \"$lib\": $result"
        }
    }


    #-------------------------------------------------------------------
    # Installing Applications
    
    # InstallApp app
    #
    # app  - The named application
    #
    # Installs the application to ~/bin.

    proc InstallApp {app} {
        try {
            # FIRST, make sure that ~/bin exists.
            file mkdir [file join ~ bin]

            # NEXT, get source and target
            set source [project root bin [project app binfile $app]]

            set target1 [file join ~ bin [project app binfile $app]]
            set target2 [file join ~ bin [project app installfile $app]]

            if {$app eq "kite" &&
                [file normalize $target2] eq 
                [file normalize [info nameofexecutable]]
            } {
                throw FATAL [outdent {
                    The ~/bin/kite executable cannot overwrite itself.
                    Use kite.tcl to install the new executable.
                }]
            }

            if {![file exists $source]} {
                puts [outdent "
                    WARNING: Application \"$app\" has not yet been built.
                "]
                return
            }

            puts "Installing $app to '$target1'"
            file copy -force -- $source $target1

            puts "Installing $app to '$target2'"
            file copy -force -- $source $target2
        } on error {result} {
            throw FATAL $result
        }
    }    
}






