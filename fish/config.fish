# make vim the default editor
if not set -q EDITOR
    export EDITOR="vim"
end

##### start up #####

# start tmux, but not if the terminal is started from vscode.  If started from
# vscode, it will attach to the same session which causes issues.  I could
# start a different session for vscode, but rarely use the vscode terminal.
# This is mostly so debugging doesn't hijack my tmux session.

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

# export secrets. Done this way to avoid committing secrets to source control.
source ~/secrets

# initialize starship
# https://github.com/starship/starship
starship init fish | source
