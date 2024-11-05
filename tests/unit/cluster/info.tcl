# Check cluster info stats

start_cluster 2 0 {tags {external:skip cluster}} {

test "Cluster should start ok" {
    wait_for_cluster_state ok
}

set primary1 [srv 0 "client"]
set primary2 [srv -1 "client"]

proc cmdstat {instance cmd} {
    return [cmdrstat $cmd $instance]
}

proc errorstat {instance cmd} {
    return [errorrstat $cmd $instance]
}

test "errorstats: rejected call due to MOVED Redirection" {
    $primary1 config resetstat
    $primary2 config resetstat
    assert_match {} [errorstat $primary1 MOVED]
    assert_match {} [errorstat $primary2 MOVED]
    # we know that one will have a MOVED reply and one will succeed
    catch {$primary1 set key b} replyP1
    catch {$primary2 set key b} replyP2
    # sort servers so we know which one failed
    if {$replyP1 eq {OK}} {
        assert_match {MOVED*} $replyP2
        set pok $primary1
        set perr $primary2
    } else {
        assert_match {MOVED*} $replyP1
        set pok $primary2
        set perr $primary1
    }
    assert_match {} [errorstat $pok MOVED]
    assert_match {*count=1*} [errorstat $perr MOVED]
    assert_match {*calls=0,*,rejected_calls=1,failed_calls=0} [cmdstat $perr set]
}

} ;# start_cluster
