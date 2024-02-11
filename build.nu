#!/usr/bin/env nu

use std log

# https://github.com/FMotalleb/nu_plugin_qr_maker/blob/main/build.nu
def main [package_file: path] {
    let $install_source = $package_file | path dirname
    let $modules_dir = $env.NUPM_HOME | path join "modules"
    let $nupm_pkg_file = (open ($install_source | path join "nupm.nuon"))
    let $package_name = $nupm_pkg_file.name
    let $install_destination = ($modules_dir | path join $package_name)

    if ($install_destination | path exists) {
        try {
            ^git -C $install_destination checkout HEAD -- mod.nu
            ^git -C $install_destination pull $install_source
        }
    } else {
        ^git clone $install_source $install_destination
        touch ($install_destination | path join ".env.nu")
    }
    
    try { ^git -C $install_destination submodule update --init --recursive }

    let $v = $nupm_pkg_file.version
    let $n =  ^git -C $install_destination describe --tags --abbrev=0 | parse "{v}-{n}-{r}" | into record | get n? | default 0

    let $install_mod = ($install_destination | path join "mod.nu")

    let $last_commit_msg = ^git -C $install_source log --pretty=format:%s -n 1 | lines --skip-empty | str join ";"
    let $last_commit_date = ^git -C $install_source log --pretty=format:%aD -n 1 | into datetime

    let version_cmd = [
         "# see the version of nu-fortnox that is currently installed"
         "#"
         "# # Examples"
         "# ```nushell"
         "# # get the version of nu-fortnox"
         "# fortnox version"
         "# ```"
         "export def \"fortnox version\" []: nothing -> record<version: string, branch: string, commit: record<hash: string, date: datetime>, install_date: datetime> {"
         "    {"
        $"        version: \"($v)+($n)\""
        $"        branch: \"(^git -C $install_destination branch --show-current)\""
        $"        commit: {"
        $"              message: ($last_commit_msg | to nuon)"
        $"              hash: \"(^git -C $install_destination rev-parse HEAD)\""
        $"              date: \(($last_commit_date | to nuon)\)"
         "        }"
        $"        install_date: \((date now | to nuon)\)"
         "    }"
         "}"
    ]

    "\n" | save --append $install_mod
    $version_cmd | str join "\n" | save --append $install_mod

    print $"nu-fortnox ($v)+($n) is now installed as a module."
    print "To use:"
    print "\tuse nu-fortnox"
    print "\toverlay use nu-fortnox"
    print "\tfortnox invoices -h"
    null
}
