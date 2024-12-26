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
export AGNOSTICD_HOME=${HOME}/development/agnosticd-dev/agnosticd

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


#==============================================================================
# Cursor Terminal workaround
#==============================================================================
cursor() {
  # Run the cursor command and suppress background process output completely
  (nohup /opt/cursor.appimage "$@" >/dev/null 2>&1 &)
}


#==============================================================================
# oh-my-posh Configuration
#==============================================================================
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh-themes/hupfer01.omp.json)"