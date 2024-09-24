# navigate to git repository
# Looks for the following values in order:
#    -r/--repo-root argument
#    GITCD_REPO_ROOT environment variable
#    ~/git default

function gitcd --argument-names repo_name repo_root --description "Navigate to specified git repository"
    argparse --max-args 1 'r/repo_root=' -- $argv

    set -f repo $argv
    set -f max_depth 1
    if set -q _flag_repo_root
        set -f repo_root $_flag_repo_root
    else
        set -f repo_root (load_config --name gitcd_repo_root --default ~/git)
        if test -z "$repo_root"
            echo "repo_root not found"
        end
    end

    if test -z "$argv"
        cd $repo_root
        return
    end

    set -f dir (find $repo_root -maxdepth $max_depth -name $repo -exec /bin/test -d {}/.git \; -print -prune -quit)
    if test -n "$dir"
        cd $dir
        return
    end

    echo "$repo not found in $repo_root"
    return 1
end
