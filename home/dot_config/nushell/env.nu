# ~/.config/nushell/env.nu
# ============================================================================
# NUSHELL ENVIRONMENT
# Environment variables and tool initialization
# ============================================================================

# 1. PATH CONFIGURATION
$env.PATH = ($env.PATH | split row (char esep) | prepend [
    ($env.HOME | path join ".local/bin")
    ($env.HOME | path join "bin")
    ($env.HOME | path join ".cargo/bin")
])

# 2. EDITOR
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.PAGER = "bat"

# 3. STARSHIP INTEGRATION
mkdir ~/.cache/starship
starship init nu | save -f ~/.cache/starship/init.nu

# 4. ZOXIDE INTEGRATION
zoxide init nushell | save -f ~/.zoxide.nu

# 5. CARAPACE INTEGRATION
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir ~/.cache/carapace
carapace _carapace nushell | save --force ~/.cache/carapace/init.nu

# 6. ATUIN INTEGRATION
atuin init nu | save -f ~/.local/share/atuin/init.nu
