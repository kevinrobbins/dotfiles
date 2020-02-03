# backup and restore the specified site
function brsite
    make -C $HOME/git/nimbis/sysop/ansible backup SITE=$argv
    make -C $HOME/git/nimbis/sysop/ansible restore SITE=$argv
end