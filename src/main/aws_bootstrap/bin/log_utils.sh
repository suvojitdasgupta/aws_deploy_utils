function log {
        local MSG=$(date +"%c $1")
        echo -e $MSG
}

function msg {
        local LOG="$1"
        echo -e $LOG
}

function failed {
        msg
        msg
        msg "FAILURE $1"
        msg "=== PROCESS ABORTING, FAILED ==="
        exit 1
}