# run the specified site

function runsite
    # if there's a virtual environment set when this is run, save the name of
    # it so we can re-activate it when we're done.
    if set -q VIRTUAL_ENV
        set orig_venv (string split "/" -- $VIRTUAL_ENV)[-1]
    end

    # activate sites venv
    vf activate sites

    # run the run site command against the provided site
    make -C $HOME/git/nimbis/sites run SITE=$argv

    # reactivate original venv if there was one
    if set -q orig_venv
        vf activate $orig_venv
    else
        vf deactivate sites
    end
end