function notify --inherit-variable status --description "Send notification to notification center indicating a job has completed."
    if test $status -eq 0
        echo "1"
        set -f msg "completed successfully"
    else
        echo "2"
        set -f msg "failed"
    end
    osascript -e "display notification \"A job $msg.\" with title \"Job Complete.\""
end
