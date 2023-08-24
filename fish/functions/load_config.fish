# Resolve configuration values. Given a configuration setting name, resolve it in the following order:
# 1. CLI argument
# 2. Environment variable
# 3. Config file

function load_config --argument-names name config_file default
    argparse 'n/name=' 'c/config_file=' 'd/default=' -- $argv

    if set -q _flag_name
        # Environment Variable
        set -l env_var (string upper $_flag_name)
        if set -q $env_var
            echo $$env_var
            return
        end

        # Config File
        if set -q _flag_config_file
            set -l config_var (string lower $_flag_name)
            set -l config_var_value (awk -v config_var=$config_var '$0~pat{print $3}' $_flag_config_file)
            if set -q $config_var_value
                echo $config_var_value
                return
            end
        end
    end

    # Return default value if provided
    if set -q _flag_default
        echo $_flag_default
        return
    end

    return 1
end
