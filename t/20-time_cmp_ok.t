
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;

BEGIN {
    use_ok('Test::AnyEvent::Time');
}

sub timer {
    my ($time) = @_;
    return undef if !defined($time);
    return sub {
        my ($cv) = @_;
        my $w; $w = AnyEvent->timer(
            after => $time,
            cb => sub {
                undef $w;
                $cv->send();
            }
        );
    };
}

sub call_time_cmp {
    my ($is_ok, $got_time, $op, $ref_time, $timeout, $desc, $after) = @_;
    my $ret;
    my $exp_desc = defined($desc) ? $desc : "";
    if($is_ok) {
        test_out "ok 1 - $exp_desc";
    }else {
        test_out "not ok 1 - $exp_desc";
    }
    if(defined($timeout)) {
        $timeout = undef if $timeout eq 'undef';
        test_fail(+1) if !$is_ok;
        $ret = time_cmp_ok $op, $ref_time, $timeout, timer($got_time), $desc;
    }else {
        test_fail(+1) if !$is_ok;
        $ret = time_cmp_ok $op, $ref_time, timer($got_time), $desc;
    }
    $after->() if defined($after);
    test_test $exp_desc;
    is($ret, $is_ok, "return value: $is_ok");
}

sub check_ok {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(1, $got_time, $op, $ref_time, $timeout, $desc);
}

sub check_wrong_time {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err qr!# +'[^']+' *\n!;
            test_err qr!# +$op *\n!;
            test_err qr!# +'$ref_time' *\n?!;
        }
    );
}

sub check_timeout {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err qr!# +Timeout \($timeout sec\) *\n!;
        }
    );
}

sub check_invalid {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    call_time_cmp(
        0, $got_time, $op, $ref_time, $timeout, $desc, sub {
            test_err qr!# +Invalid arguments\. *\n!;
        }
    );
}

note("-- OK cases");
check_ok 0.2, "<", 0.4, undef, "<, no timeout";
check_ok 1, ">=", 0.4, undef, ">=, no timeout";
check_ok 0.3, "<=", 1, 2, "<=, timeout(2)";
check_ok 0.7, ">", 0.5, 1, ">, timeout(1)";
check_ok 0.4, "<", 0.6, "undef", "<, timeout(undef)";
check_ok 0.3, ">", 0.1, "undef", ">, timeout(undef)";
check_ok 0.2, ">", 0.1;
check_ok 0.3, "<", 1;

note("-- NOT OK cases");
check_wrong_time 0.2, ">", 0.4, undef, ">, no timeout";
check_wrong_time 1, "<=", 0.4, undef, "<=, no timeout";
check_wrong_time 0.3, ">=", 1, 2, ">=, timeout(2)";
check_wrong_time 0.7, "<", 0.5, 1, "<, timeout(1)";
check_wrong_time 0.4, ">", 0.6, "undef", ">, timeout(undef)";
check_wrong_time 0.3, "<", 0.1, "undef", "<, timeout(undef)";
check_wrong_time 0.2, "<", 0.1;
check_wrong_time 0.3, ">", 1;

note("-- Timeout cases");
check_timeout 0.4, ">=", 0.1, 0.3, ">=";
check_timeout 0.5, ">", 1, 0.2, ">";
check_timeout 0.2, "<", 0.4, 0.1, "<";
check_timeout 1, "<=", 5, 0.3, "<=";

note("-- Invalid arguments");
check_invalid;
check_invalid 1;
check_invalid undef, ">", 0.4;
check_invalid 1, undef, 0.2;
check_invalid 5, "==";
check_invalid undef, "<", 3, 2.5;

done_testing();
