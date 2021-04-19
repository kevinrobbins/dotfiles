function vfreset
    if set -q VIRTUAL_ENV; and  test $VIRTUAL_ENV = '/home/krobbins/.virtualenvs/'$argv
        vf deactivate
    end

    vf rm $argv

    if test $status -eq 1
        return 1
    end

    vf new $argv
end
