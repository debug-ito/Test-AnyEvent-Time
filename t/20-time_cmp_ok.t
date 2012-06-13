
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More;

BEGIN {
    use_ok('Test::AnyEvent::Time');
}

sub timer {
    my ($time) = @_;
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

sub check_ok {
    my ($got_time, $op, $ref_time, $timeout, $desc) = @_;
    my $exp_desc = defined($desc) ? $desc : "";
    test_out "ok 1 - $exp_desc";
    if(defined($timeout)) {
        $timeout = undef if $timeout eq 'undef';
        time_cmp_ok $op, $ref_time, $timeout, timer($got_time), $desc;
    }else {
        time_cmp_ok $op, $ref_time, timer($got_time), $desc;
    }
    test_test(": $exp_desc");
}

check_ok 0.2, "<", 0.4, undef, "<, no timeout";
check_ok 1, ">=", 0.4, undef, ">=, no timeout";

test_out "not ok 1 - hoge";
test_fail(+4);
test_err qr!# +'[^']+' *\n!;
test_err qr!# +> *\n!;
test_err qr!# +'5' *\n?!;
time_cmp_ok ">", 5, timer(0.5), "hoge";
test_test("too short");

done_testing();
