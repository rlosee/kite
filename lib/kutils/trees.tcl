#-----------------------------------------------------------------------
# TITLE:
#   trees.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite: kutils(n) module for creating project trees.  This module
#   uses template files from kutils/templates and the [generate]
#   command to generate the trees.
#
#   The commands in this file build a project tree given the root
#   directory name.  They assume that the root directory does not
#   exist, and will happily overwrite anything there.  In other words,
#   it is the job of the "kite new" tool to check for problems.
#
#   TODO: Ultimately, we'd want a plugin mechanism for adding new
#   kinds of project trees.
#
#-----------------------------------------------------------------------

namespace eval ::kutils:: {
    namespace export trees
}

#-----------------------------------------------------------------------
# Help for the project trees.

set ::khelp(appkit) {
    The "appkit" project template is for pure-tcl applications that
    will be deployed as "starkit" files.  Appkits run against the 
    installed version of Tcl, and so are primarily useful for 
    developer tools.

    The template takes one optional argument, the root name of the 
    ".kit" file; this name defaults to the project name.  For example,

        $ kite new appkit my-project

    produces the appkit "<root>/bin/my-project.kit".  However,

        $ kite new appkit my-project mytool

    products the appkit "<root>/bin/mytool.kit".

    A project can contain at most one application, defined as an 
    "app" or an "appkit" in the project.kite file.  The application 
    requires a "main" script in <root>/bin/<kitname>.tcl.  For example, 
    "mytool.kit" executes the file "<root>/bin/mytool.tcl".

    This template also creates a Tcl package, app_<kitname>(n), in 
    "<root>/lib/app_<kitname>".  The usual practice is to put most of the
    appkit's code in this package (or in other Tcl packages) and have 
    "<root>/bin/<kitname>.tcl" simply invoke it.
}

set ::khelp(lib) {
    The "lib" project template is for projects that define one or more
    Tcl library packages for use by other projects.  The template 
    creates a project tree for a project with one library package;
    others can be added subsequently.

    The template takes one optional argument, the name of the 
    library package file; this name defaults to the project name.  
    For example,

        $ kite new lib my-project

    produces the package "<root>/lib/my-project", while

        $ kite new lib my-project mylib

    products the package "<root>/lib/mylib".

    A project can define any number of library packages via the 
    "lib" statement in the project.kite file.  These should be
    initialized using "kite new lib" or "kite add lib"; this ensures
    that the package files contain the correct markers so that Kite
    can update their version numbers as the version number changes
    in project.kite.
}


#-----------------------------------------------------------------------
# trees ensemble

snit::type ::kutils::trees {
    # Make it a singleton
    pragma -hasinstances no -hastypedestroy no

    #-------------------------------------------------------------------
    # Type Variables

    typevariable treetypes {
        appkit ".kit application template"
        lib    "Tcl library package template"
    }


    #-------------------------------------------------------------------
    # Public Queries

    # types
    #
    # Returns the list of tree types.

    typemethod types {} {
        return [dict keys $treetypes]
    }

    # description tree
    #
    # tree  - A tree type
    #
    # Returns the description of the tree type.

    typemethod description {tree} {
        return [dict get $treetypes $tree]
    }


    #-------------------------------------------------------------------
    # Project trees
    

    # appkit dirname projname kitname
    #
    # dirname  - The directory in which to create the new tree.
    # projname - The project name, e.g., "athena-mytool"
    # kitname  - The barename of the appkit to make, e.g., "mytool"
    #
    # Builds a default appkit template rooted at the given directory,
    # assuming that there is nothing there.
    #
    # TODO: appkits and apps will share the same structure; the only
    # difference is the entry in the project file.  So we should
    # share the code.

    typemethod appkit {dirname projname kitname} {
        if {$kitname eq ""} {
            set kitname $projname
        }
        
        puts "Making an appkit project tree for project \"$projname.\""
        puts "The application will be called \"$kitname.kit\"."

        # FIRST, create the project directory structure
        set root   [file join $dirname $projname]
        file mkdir $root

        set bin    [file join $root bin]
        set lib    [file join $root lib]
        set docs   [file join $root docs]
        set pkg    app_$kitname

        # NEXT, create the mapping
        dict set mapping %project $projname
        dict set mapping %kitname $kitname
        dict set mapping %kitfile $kitname.kit
        dict set mapping %package $pkg
        dict set mapping %pkgfile app

        # NEXT, create the files.
        generate appkit_project $mapping $root project.kite
        generate project_readme $mapping $root README.md
        generate gitignore      {}       $root .gitignore
        generate appkit_main    $mapping $bin $kitname.tcl
        generate docs_index     $mapping $docs index.ehtml
        generate pkgIndex       $mapping $lib $pkg pkgIndex.tcl
        generate pkgModules     $mapping $lib $pkg pkgModules.tcl
        generate pkgFile        $mapping $lib $pkg app.tcl


        # TODO: Add test tree!

        puts ""
    }

    # lib dirname projname libname
    #
    # dirname  - The directory in which to create the new tree.
    # projname - The project name, e.g., "athena-mylib"
    # libname  - The barename of the library package, e.g., "mylib"
    #
    # Builds a default library template rooted at the given directory,
    # assuming that there is nothing there.

    typemethod lib {dirname projname libname} {
        if {$libname eq ""} {
            set libname $projname
        }

        puts "Making an appkit project tree for project \"$projname.\""
        puts "The library package will be called ${libname}(n)."

        # FIRST, create the project directory structure
        set root   [file join $dirname $projname]
        file mkdir $root

        set lib    [file join $root lib]
        set docs   [file join $root docs]

        # NEXT, create the mapping
        dict set mapping %project $projname
        dict set mapping %package $libname

        # NEXT, create the files.
        generate lib_project    $mapping $root project.kite
        generate project_readme $mapping $root README.md
        generate gitignore      {}       $root .gitignore
        generate docs_index     $mapping $docs index.ehtml
        generate pkgIndex       $mapping $lib $libname pkgIndex.tcl
        generate pkgModules     $mapping $lib $libname pkgModules.tcl
        generate pkgFile        $mapping $lib $libname $libname.tcl


        # TODO: Add test tree!
        # TODO: man page

        puts ""
    }
}



