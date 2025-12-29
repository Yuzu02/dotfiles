# ~/.config/nushell/config.nu
# ============================================================================
# NUSHELL CONFIGURATION
# Modern shell with structured data
# ============================================================================

# 1. VISUAL SETTINGS
$env.config = {    
    table: {
        mode: rounded
        index_mode: always
        show_empty: true
        padding: { left: 1, right: 1 }
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
        }
    }

    # 2. BEHAVIOR
    ls: { use_ls_colors: true }
    rm: { always_trash: true }

    # 3. COMPLETIONS & HISTORY
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite" 
    }
    
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }

    # 4. KEYBINDINGS
    edit_mode: vi
}

# ============================================================================
# ALIASES
# ============================================================================
alias ll = ls -l
alias la = ls -a
alias cat = bat
alias find = fd
alias grep = rg
alias ps = procs
alias git = ^git
alias lg = lazygit
alias y = yazi
alias vim = nvim

# ============================================================================
# CUSTOM COMMANDS
# ============================================================================

# git-stat: View commit history as a structured table
def git-stat [] {
    git log --pretty=%h»¦«%aN»¦«%s»¦«%aD 
    | lines 
    | split column "»¦«" sha1 author desc date 
    | first 20
}

# view-json: Interactive JSON viewer
def view-json [file: path] {
    open $file | explore
}

# weather: Fetch weather data
def weather [city: string = "Santo_Domingo"] {
    http get $"https://wttr.in/($city)?format=j1" 
    | get current_condition 
    | select temp_C humidity weatherDesc 
    | update weatherDesc { |row| $row.weatherDesc.0.value }
}

# docker-nuke: Clean all containers
def docker-nuke [] {
    ^docker ps -q | lines | each { |id| ^docker stop $id }
    ^docker system prune -af
}

# mkcd: Make directory and cd into it
def --env mkcd [dir: string] {
    mkdir $dir
    cd $dir
}

# ============================================================================
# STARSHIP & TOOLS INTEGRATION
# ============================================================================
source ~/.cache/starship/init.nu
source ~/.zoxide.nu
source ~/.cache/carapace/init.nu
source ~/.local/share/atuin/init.nu
