# Path to your oh-my-zsh installation.
export ZSH="/home/mashy/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="simple"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=3

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# zsh history
HIST_STAMPS="dd/mm/yyyy"
# Removes duplicates form history
setopt  HIST_IGNORE_ALL_DUPS

# Which plugins would you like to load?
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
autoload -U compinit && compinit
_comp_options+=(globaldots);

source $ZSH/oh-my-zsh.sh
source $ZSH/aliases.sh
source $ZSH/mount_aliases.sh

# Exports:
# Manpage locatio
export MANPATH="/usr/local/man:$MANPATH"
# Preferred editor
export EDITOR='emacs'
# Preferred browser
export BROWSER='/usr/bin/firefox'
# Paths
export PATH=/usr/sbin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH/usr/lib64:/usr/lib64/mpi/gcc/openmpi4/lib64
# Local binraries
export PATH=$PATH:/home/mashy/.local/bin
# Doom emacs
export PATH=$PATH:/home/mashy/.config/emacs/bin
# Rust / cargo binraries
export PATH=$PATH:/home/mashy/.cargo/bin
# Paraview
export PARAVIEW=/opt/ParaView-5.9.0-RC4-osmesa-MPI-Linux-Python3.8-64bit
export PYTHONPATH=/opt/ParaView-5.9.0-RC4-osmesa-MPI-Linux-Python3.8-64bit/lib/python3.8/site-packages
# Nvidia-hpc-sdk
export NVARCH=`uname -s`_`uname -m`
export NVCOMPILERS=/opt/nvidia/hpc_sdk
export MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.5/compilers/man
export PATH=$PATH:$NVCOMPILERS/$NVARCH/23.5/compilers/bin
export PATH=$PATH:$NVCOMPILERS/$NVARCH/23.5/comm_libs/mpi/bin
export MANPATH=$MANPATH:$NVCOMPILERS/$NVARCH/23.5/comm_libs/mpi/man

# User configurations
# Functions:
# Functions for identifying distribution
function on-classic-linux() {
    if [[ -f "/etc/os-release" ]] ; then
        if [[ `cat /etc/os-release | grep \^NAME` == *"$1"* ]] ; then
            return 0
        else
            return 1
        fi
    else
        echo "/etc/os-release not found. This is not classic GNU/Linux."
        return 1
    fi
}
function on-tumbleweed() {
    on-classic-linux "openSUSE Tumbleweed"
}
function on-leap() {
    on-classic-linux "openSUSE Leap"
}
function on-manjaro() {
    on-classic-linux "Manjaro Linux"
}
function on-fedora() {
    on-classic-linux "Fedora"
}
function on-debian() {
    on-classic-linux "Debian GNU/Linux"
}
# Function for distribution updates
function update-distro() {
    OPTION=$1
    SESSION=UPDATE
    if on-classic-linux ; then
        if on-tumbleweed ; then
            if [[ $OPTION == "fast" ]] ; then
                UPDATE_CMD="sudo zypper dup --allow-vendor-change"
            else
                UPDATE_CMD="sudo zypper refresh && sudo zypper dup --allow-vendor-change"
            fi
        elif on-leap ; then
            UPDATE_CMD="sudo zypper up"
        elif on-manjaro ; then
            UPDATE_CMD="sudo pacman -Syyuu"
        elif on-fedora ; then
            if [[ $OPTION == "fast" ]] ; then
                UPDATE_CMD="sudo dnf upgrade"
            else
                UPDATE_CMD="sudo dnf upgrade --refresh"
            fi
        elif on-debian ; then
            UPDATE_CMD="sudo apt update && sudo apt upgrade"
        else
            echo -e "\n\tCommand not set for the distribution in use.\n"
        fi
    fi
    tmux new-session -d -s $SESSION
    tmux send-keys "$UPDATE_CMD" C-m
    tmux attach-session -t $SESSION
}

# fzf and bat
eval "$(fzf --zsh)"
# Get the colors in the opened man page itself
export MANPAGER="sh -c 'col -bx | bat -l man -p --paging always'"

# Use fd instead of fzf
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'lsd --tree --color=always {} | head -200'"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source /home/mashy/Downloads/installs/fzf-git.sh/fzf-git.sh

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'lsd --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

fman() {
    man -k . | fzf -q "$1" --prompt='man> '  --preview $'echo {} | tr -d \'()\' |   \
        awk \'{printf "%s ", $2} {print $1}\' | xargs -r man | col -bx | bat -l man \
        -p --color always' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}
