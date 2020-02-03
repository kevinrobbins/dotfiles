# run migrations for the specified site
function msite
    make -C $HOME/git/nimbis/sites migrate SITE=$argv
end