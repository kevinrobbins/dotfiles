function mkvirtualenv --description "Create a virtualenv"
    argparse --ignore-unknown 'n/name=?' 'l/local' 'i/inactive' -- $argv

    # i/inactive will not activate the environment after creation

    # Set venv_name
    if set -ql _flag_name
        # Provided name always has precedence
        set -f venv_name $_flag_name
    else if set -ql _flag_local
        # requested local venv, but no name provided
        set -f venv_name ".venv"
    else
        # Fall back to default
        set -f venv_name (basename (pwd))
    end

    # Set location
    if set -ql _flag_local
        set -f location "."
    else
        # Fall back to default
        set -f location ~/.virtual_envs
    end

    # Attempt to create virtual environment
    if python -m venv $argv $location/$venv_name
        echo "Created virtual environment at $location/$venv_name"
    else
        echo "Failed to create virtual environment at $location/$venv_name"
        return 1
    end

    # Attempt to activate the venv if --inactive is not passed
    if not set -q _flag_inactive
        return (activate_venv $venv_name)
    end
end
