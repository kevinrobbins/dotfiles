# backup the specified site
function bsite
    make -C $HOME/git/nimbis/sysop/ansible backup SITE=$argv
end