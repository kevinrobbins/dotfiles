# navigate to git repository
# Looks for the following values in order:
#    -r/--repo-root argument
#    REPO_ROOT environment variable
#    ~/git/ default

function gitcd --argument-names repo_name repo_root --description "Navigate to specified git repository"
    argparse --max-args 1 'r/repo_root=' -- $argv

    set repo $argv
    set max_depth 6
    if set -q _flag_repo_root
        set repo_root $_flag_repo_root
    else if set -q REPO_ROOT
        set repo_root $REPO_ROOT
    else
        set repo_root ~/git/
    end

    if ! test -n "$argv"
        cd $repo_root
        return 0
    end

    cd (find $repo_root -maxdepth $max_depth -name $repo -exec test -d {}/.git \; -print -prune -quit)
end
