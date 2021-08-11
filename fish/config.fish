# powerline
set REPOSITORY_ROOT "/home/krobbins/.local/lib/python2.7/site-packages"
set fish_function_path $fish_function_path "$REPOSITORY_ROOT/powerline/bindings/fish"
#powerline-setup

# make vim the default editor
if not set -q EDITOR
    export EDITOR="vim"
end

# start vim in INSERT mode
alias vim "vim +star"

##### start up #####

# start tmux
set SESSION_NAME default
begin
    not set -q TMUX
    and tmux new-session -As $SESSION_NAME
end

# Add my scripts to the path
export PATH="/home/krobbins/bin:$PATH"
export PATH="/home/krobbins/bin/scripts:$PATH"

# Add packer to the PATH
export PATH="/home/krobbins/packer:$PATH"

# Add sysop scripts to the PATH
export PATH="/home/krobbins/git/nimbis/sysop/bin:$PATH"

# Add ec2_report script to path
export PATH="/home/krobbins/git/nimbis/ec2-reporting:$PATH"

#spacefish config
set SPACEFISH_DOCKER_SHOW false

# Auto-enable pyenv and pyenv-virtualenv
status is-interactive; and pyenv init --path | source
pyenv init - | source
status --is-interactive; and pyenv virtualenv-init - | source
