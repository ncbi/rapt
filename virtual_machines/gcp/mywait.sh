function mywait()
{
    #
    #   wait loop  by process ids, so we fail if any of fasta2cache fails.
    #
    pids="$1"; shift
    for pid in $(cat $pids); do
        set +e
        wait $pid
        exitcode=$?
        case $exitcode in
            127|0) # 127=we are fine: the quick process was quick and finished before we started this loop
                true;
                ;;
            *)
                exit $exitcode;
                ;;
        esac
        set -e
        
    done
    rm -f "$pids"
}    
