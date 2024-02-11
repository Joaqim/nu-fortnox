#!/usr/bin/env nu

use std log

# https://github.com/FMotalleb/nu_plugin_qr_maker/blob/main/build.nu
def main [package_file: path] {
    let $install_source = $package_file | path dirname
    let $modules_dir = $env.NUPM_HOME | path join "modules"
    let $nupm_pkg_file = (open ($install_source | path join "nupm.nuon"))
    let $package_name = $nupm_pkg_file.name
    let $install_destination = ($modules_dir | path join $package_name)

    ^git clone $install_source $install_destination
    
    try { ^git -C $install_destination submodule update --init --recursive }

    let $v = $nupm_pkg_file.version
    let $n =  ^git -C $install_source describe --tags --abbrev=0 | parse "{v}-{n}-{r}" | into record | get n? | default 0

    let $install_mod = ($install_destination | path join "mod.nu")

    let $last_commit_date = ^git -C $install_source log --pretty=format:%aD -n 1 | into datetime

    let version_cmd = [
         "# see the version of nu-fortnox that is currently installed",
         "#",
         "# # Examples",
         "# ```nushell",
         "# # get the version of nu-fortnox",
         "# fortnox version",
         "# ```",
         "export def \"fortnox version\" []: nothing -> record<version: string, branch: string, commit: string, date: datetime> {",
         "    {",
        $"        version: \"($v)+($n)\",",
        $"        branch: \"(^git -C $install_source branch --show-current)\",",
        $"        commit: \"(^git -C $install_source rev-parse HEAD)\",",
        $"        last_commit_date: \(($last_commit_date | to nuon)\),",
        $"        installation_date: \((date now | to nuon)\),",
         "    }",
         "}",
    ]

    "\n" | save --append $install_mod
    $version_cmd | str join "\n" | save --append $install_mod

    print "nu-fortnox is now installed as a module."
    print "To use:"
    print "\tuse nu-fortnox"
    print "\toverlay use nu-fortnox"
    print "\tfortnox invoices -h"
    null
}
