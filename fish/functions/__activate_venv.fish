function __activate_venv --on-variable PWD --description 'Activate virtual
    environment when changing directories if a .venv directory exists in the
    new directory'

    status --is-command-substitution; and return

    activate_venv &> /dev/null; and return

    # If no venv could be activated, deactivate the active venv
    deactivate
end
