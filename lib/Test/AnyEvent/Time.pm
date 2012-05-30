package Test::AnyEvent::Time;

use warnings;
use strict;

use base ('Exporter');

use AnyEvent;
use Carp;
use Test::More;

our @EXPORT = qw(within_ok time_cmp_ok time_around_ok elapsed_time);

=head1 NAME

Test::AnyEvent::Time - The great new Test::AnyEvent::Time!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Test::AnyEvent::Time;

    my $foo = Test::AnyEvent::Time->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub elapsed_time {
    my ($timeout, $cb) = @_;
    if(!defined($cb)) {
        $cb = $timeout;
        undef $timeout;
    }
    my $cv = AE::cv;
    my $w;
    my $timed_out = 0;
    if(defined($timeout)) {
        $w = AE::timer $timeout, 0, sub {
            undef $w;
            $timed_out = 1;
            $cv->send();
        };
    }
    my $before = AE::now;
    $cb->($cv);
    $cv->recv();
    if($timed_out) {
        return undef;
    }
    return (AE::now - $before);
}

sub _arrange_args {
    my ($timeout, $cb, $desc) = @_;
    if(ref($timeout) eq 'CODE') {
        $desc = $cb;
        $cb = $timeout;
        undef $timeout;
    }
    if(!defined($desc)) {
        $desc = '';
    }
    return ($timeout, $cb, $desc);
}

sub time_cmp_ok {
    my $op = shift;
    my $cmp_time = shift;
    my ($timeout, $cb, $desc) = _arrange_args(@_);
    my $time = elapsed_time $timeout, $cb;
    if(defined($time)) {
        cmp_ok($time, $op, $cmp_time, $desc);
    }else {
        fail($desc);
        diag("Operation timeout ($timeout sec)");
    }
}

sub time_around_ok {
    my $center_time = shift;
    my $margin_time = shift;
    my ($timeout, $cb, $desc) = _arrange_args(@_);
    my $time = elapsed_time $timeout, $cb;
    if(defined($time)) {
        cmp_ok($time, '>=', $center_time - $margin_time, $desc);
        cmp_ok($time, '<=', $center_time + $margin_time, $desc);
    }else {
        fail($desc);
        diag("Operation timeout ($timeout sec)");
    }
}

sub within_ok {
    my ($time, $cb, $desc) = @_;
    time_cmp_ok('<=', $time, $time, $cb, $desc);
}

=head1 AUTHOR

Toshio Ito, C<< <debug.ito at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-anyevent-time at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-AnyEvent-Time>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::AnyEvent::Time


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-AnyEvent-Time>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-AnyEvent-Time>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-AnyEvent-Time>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-AnyEvent-Time/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::AnyEvent::Time
