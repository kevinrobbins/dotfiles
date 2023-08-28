function okta-signin --description "Sign in to Okta by getting password from 1password. All arguments are passed directly to okta-awscli."
    # Verify okta-awscli is available
    if not which okta-awscli > /dev/null
        echo "okta-awscli is not available."
        exit 10
    end

    set -l okta_password (op read 'op://Nimbis/Okta/password')
    okta-awscli --password $okta_password $argv
end
