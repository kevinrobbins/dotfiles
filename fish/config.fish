## Abbreviations ##

# Virtual Environments
abbr --add pvn mkvirtualenv
abbr --add pvd deactivate
abbr --add pva activate_venv

# Git
abbr --add gits git status
abbr --add gita git add
abbr --add gitc git commit
abbr --add gitcv git commit --verbose
abbr --add gitco git checkout
abbr --add gitpu git pull
abbr --add gitps git push
abbr --add gitrb git rebase
abbr --add gitrbi git rebase --interactive
abbr --add gitdu git diff @{u}
abbr --add gitg git log --graph --oneline --all
abbr --add gitlo git log --oneline
abbr --add gitcp git cherry-pick

# Docker compose
abbr --add dc docker compose
abbr --add dcp docker compose --profile

# ls
abbr --add ls ls -al

# aws
abbr --add ssm aws ssm start-session --target

## Config ##

# make vim the default editor
if not set -q EDITOR
    export EDITOR="vim"
end

##### start up #####

# start tmux, but not if the terminal is started from vscode.  If started from
# vscode, it will attach to the same session which causes issues.  I could
# start a different session for vscode, but rarely use the vscode terminal.
# This is mostly so debugging doesn't hijack my tmux session.
if [ -n (which tmux) ]
	if [ "$RUNNING_ON_GK" = "true" ] # For GitKraken, start a new session
		set SESSION_NAME gk
		begin
			not set -q TMUX
			and tmux new-session -As $SESSION_NAME
		end
	else if [ "$TERM_PROGRAM" != "vscode" ]
		set SESSION_NAME default
		begin
			not set -q TMUX
			and tmux new-session -As $SESSION_NAME
		end
	end
end

# Pyenv
if [ -n (which pyenv) ]
	set -x PYENV_ROOT $HOME/.pyenv
	fish_add_path --prepend $PYENV_ROOT
	pyenv init - | source
end

# export secrets. Done this way to avoid committing secrets to source control.
source ~/secrets

# initialize starship
# https://github.com/starship/starship
if [ -n (which starship) ]
	starship init fish | source
end

# Initialize zoxide
# https://github.com/ajeetdsouza/zoxide
if [ -n (which zoxide) ]
	zoxide init fish | source
end
