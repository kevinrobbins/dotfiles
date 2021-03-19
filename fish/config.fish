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

# Enable sites virtual environment by default
if not set -q VIRTUAL_ENV
   vf activate sites
end

# Add packer to the PATH
export PATH="/home/krobbins/packer:$PATH"

# Add sysop scripts to the PATH
export PATH="/home/krobbins/git/nimbis/sysop/bin:$PATH"
