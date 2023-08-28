function update_fish_functions --description "Sync state between fish functions defined in this repo with fish functions in ~/.config/fish/functions/."
    set -f repo_function_path "$HOME/git/dotfiles/fish/functions"
    set -f config_functions_path "$HOME/.config/fish/functions"

    # Make sure that all repo_functions are in config_functions
    set repo_functions (find $repo_function_path -name "*.fish" | sort)
    set config_functions (find $config_functions_path -name "*.fish" | sort)

    if [ (count $repo_functions) -eq (count $config_functions) ]
        set -l same true
        for i in (seq 1 (count $repo_functions))
            if [ $repo_functions[$i] != $config_functions[$i] ]
                set same false
                break
            end
        end
        if $same
            echo "No changes detected."
            return 0
        end
    end

    set -f links_to_create
    for rf in $repo_functions
        set -l target_file_path $config_functions_path/(basename $rf)
        if [ ! -e $target_file_path ]
            set -a links_to_create (basename $rf)
        end
    end

    if [ (count $links_to_create) -gt 0 ]
        echo -e "The following functions will be published to $config_functions_path:\n"
        echo -e (string join "\n" $links_to_create)
        echo ""

        read -l -P 'Do you want to continue? [y/N] ' confirm
        switch $confirm
            case Y y
                echo ""
                for link in $links_to_create
                    set -l src $repo_function_path/$link
                    set -l dest $config_functions_path/$link
                    ln -s $src $dest
                    if [ $status -eq 0 ]
                        echo "Added $link"
                    else
                        echo "Unable to create symlink from $src to $dest"
                    end
                end
                echo ""
            case N n
                return 0
        end
    end

    set -f missing_functions
    for cf in $config_functions
        set -l target_file_path $repo_function_path/(basename $cf)
        if [ ! -e $target_file_path ]
            set -a missing_functions (basename $cf)
        end
    end

    if [ (count $missing_functions) -gt 0 ]
        echo -e "The following functions will be deleted from $config_functions_path:\n"
        echo -e (string join "\n" $missing_functions)
        echo ""

        read -l -P 'Do you want to continue? [y/N] ' confirm
        switch $confirm
            case Y y
                echo ""
                for mf in $missing_functions
                    rm -f $config_functions_path/$mf
                end
            case N n
                return 0
        end
    end
end
