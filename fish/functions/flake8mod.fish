function flake8mod
    # Will return any flake8 errors for any file modified in the given range of
    # commits
    if not test (count $argv) -eq 2
        echo "Requires two commit ids" 1>&2
        return 1
    end

    pip show flake8 --no-python-version-warning > /dev/null
    if not test $status -eq 0
        echo "flake8 is not installed." 1>&2
        return 1
    end

    set com "git diff --name-only $argv[1] $argv[2]"
    set files (eval $com ^&1) #(git diff --name-only $argv[1] $argv[2])
    if not test $status -eq 0
        echo "
An error occurred while executing the following command:

$com

See below for the error message:

$files
        " 1>&2
        return 1
    end

    if test (count files) -eq 0
        echo "There are no differences between the provided commits."
        return 0
    end

    flake8 $files
end