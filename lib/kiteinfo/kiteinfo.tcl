#-----------------------------------------------------------------------
# TITLE:
#   kiteinfo.tcl
#
# AUTHOR:
#   Will Duquette
#
# DESCRIPTION:
#   Kite: kiteinfo(n) Package
#
#   This package was auto-generated by Kite to provide the 
#   project athena-kite's code with access to the contents of its 
#   project.kite file at runtime.
#
#   Generated by Kite
#-----------------------------------------------------------------------

namespace eval ::kiteinfo:: {
    variable kiteInfo
    array set kiteInfo {description {Athena/Kite Development Tool} appkit kite name athena-kite libs {} version 0.0a3 includes {}}

    namespace export get
    namespace ensemble create
}

#-----------------------------------------------------------------------
# Commands

# get ?parm?
#
# parm  - The name of a element in the kiteInfo array
#
# Returns the value of the given parm.  It's an error if the parm
# doesn't exist.  Without a parm, returns a dictionary of the whole
# set of data.

proc ::kiteinfo::get {{parm ""}} {
    variable kiteInfo

    if {$parm eq ""} {
        return [array get kiteInfo]
    }

    if {![info exists kiteInfo($parm)]} {
        error "unknown kiteinfo parameter: \'$parm\'"
    }
    
    return $kiteInfo($parm)
}

