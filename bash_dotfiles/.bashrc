# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

#==============================================================================
# Environment Variables & Exports
#==============================================================================
export PATH=$HOME/.local/bin:$PATH
export EDITOR=nvim
export AGNOSTICD_HOME=${HOME}/demos_deployer/agnosticd
export AGNOSTICV_HOME=${HOME}/demos_deployer/agnosticv
export DEPLOY_CONFIGS_HOME=${HOME}/demos_deployer/hpfeffer_configs

#==============================================================================
# Aliases
#==============================================================================
alias vim=nvim
alias ls='ls --color=auto'
alias ll='ls -l'
alias la='ls -la'
alias tf='terraform'
alias tfa='terraform apply'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfd='terraform destroy'
alias gen-guid='echo $(uuidgen | cut -d - -f 2 | tr '[:upper:]' '[:lower:]')'
alias rhel-start="virsh start rhel8.10"


#==============================================================================
# Cursor Terminal workaround
#==============================================================================
cursor() {
    # Create the log directory if it doesn't exist
    mkdir -p "$HOME/.cursor_logs"

    # Get the current date and time for the log filename
    log_file="$HOME/.cursor_logs/$(date '+%Y-%m-%d_%H-%M-%S').log"

    # Run the AppImage and redirect output to the log file
    (/opt/cursor.appimage "$@" >"$log_file" 2>&1 &)
}

#==============================================================================
# vless - open a file in VS Code with the cursor terminal workaround
#==============================================================================
vless() {
  tmpfile=$(mktemp /tmp/vless.XXXXXX)
  if [ -t 0 ]; then
    # No piped input, use arguments (files)
    cat "$@" > "$tmpfile"
  else
    # Piped input
    cat > "$tmpfile"
  fi
  cursor --reuse-window "$tmpfile"
}

#==============================================================================
# oh-my-posh Configuration
#==============================================================================
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh-themes/hupfer01.omp.json)"


#==============================================================================
# Shell-GPT integration BASH v0.2
#==============================================================================
_sgpt_bash() {
if [[ -n "$READLINE_LINE" ]]; then
    READLINE_LINE=$(sgpt --shell <<< "$READLINE_LINE" --no-interaction)
    READLINE_POINT=${#READLINE_LINE}
fi
}
bind -x '"\C-l": _sgpt_bash'

#==============================================================================
# Instantly run previous command with sudo using Alt+S
#==============================================================================
sudo_last_command() {
    READLINE_LINE="sudo $(history -p !!)"
    READLINE_POINT=${#READLINE_LINE}
}
bind -x '"\es": sudo_last_command'
