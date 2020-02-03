# restore the specified site
function rsite
    make -C $HOME/git/nimbis/sysop/ansible restore SITE=$argv
end