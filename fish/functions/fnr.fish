function fnr --description 'Find and replace text in the given file'
    argparse 't/target_text=' 'r/replacement_text=' -- $argv

    # TODO: write a function to parse an argument list and do this in a loop
    if not set -q _flag_target_text
        echo "No value for --target_text"
        return 1
    end

    if not set -q _flag_replacement_text
        echo "No value for --replacement_text"
        return 1
    end

    if test (count $argv) -lt 1
        echo "No search location given"
        return 1
    end

    set -l target_file $argv[-1]

    gsed -i "s/$_flag_target_text/$_flag_replacement_text/g" $target_file
end
