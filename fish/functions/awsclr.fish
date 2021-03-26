function awsclr
    set env_vars \
        AWS_DEFAULT_REGION \
        AWS_ACCESS_KEY_ID \
        AWS_SECRET_ACCESS_KEY \
        AWS_SESSION_TOKEN

    for env_var in $env_vars
        if env | grep $env_var > /dev/null 2>&1
            set -e $env_var
            echo "Cleared: $env_var"
        else
            echo "Not set: $env_var"
        end
    end
end
