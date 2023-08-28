# TODO: support multiple ports
function ssmpf --description "Start SSM session and forward specified ports."
    argparse 'p/aws_profile=' 'i/instance_id=' 's/source_port=' 'd/destination_port=' -- $argv

    # TODO: try to get profile from AWS_PROFILE
    if not set -q _flag_aws_profile
        echo "--aws_profile required."
        return
    end

    if not set -q _flag_instance_id
        echo "--instance_id required."
        return
    end

    if not set -q _flag_source_port
        echo "--source_port required."
        return
    end

    if not set -q _flag_destination_port
        echo "--destination_port required."
        return
    end


    set -f port_config ( \
        jq \
            --null-input \
            --arg src "$_flag_source_port" \
            --arg dest "$_flag_destination_port" \
            '{"portNumber": [$src], "localPortNumber": [$dest]}')

    aws \
        --profile $_flag_aws_profile \
        ssm \
            start-session \
            --target $_flag_instance_id \
            --document-name AWS-StartPortForwardingSession \
            --parameters "$port_config"
end
