#!/usr/bin/env nu

use std log

#let current_dir = ($env.CURRENT_FILE | path dirname)

def main [package_file: path] {
    let repo_root = $package_file | path dirname
    let install_root = $env.NUPM_HOME | path join "modules"

    try { git submodule update --init --recursive }

    log info "Experimental"

    null
}
