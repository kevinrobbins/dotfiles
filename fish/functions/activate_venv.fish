function activate_venv --description "Activate virtualenv"
    if test -n "$argv[1]"
        source $argv[1]/bin/activate.fish &> /dev/null; and return
        source ~/.virtualenvs/$argv[1]/bin/activate.fish &> /dev/null; and return
        echo "No virtual environment named $argv[1] found."
    else
        # Try a few places. Give precedence to closer venvs
        source .venv/bin/activate.fish &> /dev/null; and return
        source venv/bin/activate.fish &> /dev/null; and return
        source ~/.virtualenvs/(basename (pwd))/bin/activate.fish &> /dev/null; and return
        echo "No virtual environment found."
        return 1
    end
end
