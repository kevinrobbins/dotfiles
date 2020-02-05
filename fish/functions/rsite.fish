# restore the specified site
function rsite
    # if there's a virtual environment set when this is run, save the name of
    # it so we can re-activate it when we're done.
    if set -q VIRTUAL_ENV
        set orig_venv (string split "/" -- $VIRTUAL_ENV)[-1]
    end

    # activate sysop venv
    vf activate sysop

    # run restore command against the provided site
    make -C $HOME/git/nimbis/sysop/ansible restore SITE=$argv

    # reactivate original venv if there was one
    if set -q orig_venv
        vf activate $orig_venv
    else
        vf deactivate sysop
    end
end