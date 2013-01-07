package Fix::DateTime; # it is a good name?

use strict;
use warnings;
use English qw(-no_match_vars); # to use @ARG and $ARG instead @_ and $_
use List::Util qw(first);

our $VERSION       = '0.02';
our $DEFAULT_VALUE = 'EST';
our $ENABLE        = 1;

BEGIN {
	my @SUBS    = qw(new now today last_day_of_month from_epoch);
	my @methods = map { 'DateTime::' . $ARG } @SUBS;
	
	foreach my $method (@methods) {
		## no critic (ProhibitNoStrict, ProhibitProlongedStrictureOverride)
		no strict 'refs';      
		no warnings 'redefine';            ## no critic (ProhibitNoWarnings)

		my $original = *{$method}{CODE};
		
		*{$method} = sub {                # wrap to add time_zone => $DEFAULT_VALUE in arguments
			if($ENABLE && ! first { $_ eq 'time_zone' } @ARG) {
				push @ARG, time_zone => $DEFAULT_VALUE 
			}

			goto $original                # jump to original sub
		}
	}
}

## no critic (RequireFinalReturn)
sub enable {
	$ENABLE = 1;
}

sub disable {
	$ENABLE = 0;
}

## no critic (ProhibitSubroutinePrototypes)
sub set_default_value($) {
	my ($new_default_value)   = @ARG;
	(my $old, $DEFAULT_VALUE) = ($DEFAULT_VALUE, $new_default_value);

	{
		old => $old,
		new => $DEFAULT_VALUE
	}
}

1;
__END__
=head1 NAME

Fix::DateTime - Perl extension for fix the default time_zone in DateTime objects

=head1 SYNOPSIS

  use Fix::DateTime; 

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This module will apply a monkey patch in five methods of DateTime (new, now, today, last_day_of_month and from_epoch) 
to add a default argument 'time_zone' with value 'EST'. 

If the DateTime->method already has a time_zone argument, we don't change anything.

=head1 SUBROUTINES/METHODS

=head2 EXPORT

None by default.

=head2 set_default_value

Change the value of the default time_zone value (it is global, be careful). 

	Fix::DateTime::set_default_value 'WET'; # or...
	my $result = Fix::DateTime::set_default_value 'UTC';

Return a hash ref with the old and new values.

=head2 enable 

	Fix::DateTime::enable;
 
Enable the monkey patch, it is global. See disable method.

=head2 disable 

	Fix::DateTime::disable;
 
Disable the monkey patch, it is global. All methods will ignore if there is time_zone in the argument list.
Affect all objects. See example below:
	
	use DateTime;
	use Fix::DateTime;         # default time zone is EST
	
	my $t1 = DateTime->today;  # time zone is EST
	
	Fix::DateTime::disable;
	
	my $t2 = DateTime->Today;  # time zone is UTC
	
	$t1->time_zone_short_name; # still returns EST
	$t2->time_zone_short_name; # returns UTC
	

methods new, now, today, last_day_of_month and from_epoch can add or not the default time zone based on (enable/disable) feature.

This feature does not change the subroutine! it is just a flag. If disable, all methods has the same old behavior. Be careful!	

=head1 CONSIDERATIONS

The main objective of this module is solve this:

	Background
	-----------------
	We found a bug in our code-base such that automated tests would fail
	when they would run in the evening, but they would pass during the work
	day. We traced the issue to our use of the DateTime module and its
	default time zone handling. Our servers and our database operate in the
	Eastern Time Zone, and we needed DateTime to behave in that time
	zone as well.

	We use the following class methods used to construct DateTime objects.

	  new();
	  now();
	  today();
	  from_epoch();
	  last_day_of_month();


	Exercise
	------------
	Demonstrate a solution that can easily be used (and re-used) throughout
	a code-base in place of default calls to create DateTime objects to solve this
	time zone issue. Please also include automated tests to cover the code you
	write, and thorough documentation explaining your solution.

There are many ways to solve this. For example

0 Change our application to use default time zones
1 Create a subclass of DateTime who fix it
2 Monkey Patch the DateTime (used here)
3 Apply an official Patch in DateTime to be able to work with default time zones
4 Use some IOC framework to build a DateTime with a default time_zone

Option 0 can be great but if we have one or more systems in production it can be hard to consider this.

Options 1 and 4 can be good and clean but we need change our application to do this. And imagine an external library:

    my $datetime = Other::Library->do_something; # will return something in UTC

Option 3 can be interesting but do not solve our problem right now.

Option 2 is very common in the ruby community and it is very dangerous. I'm changing globally 5 methods and it can be
terrible if I do some mistake. That's why I develop this using tests and add a small configuration do enable/disable.

To be easily re-used I add the capability of change the default time zone.

There are many ways to wrap a subroutine like

=over 8

=item L<Sub::Prepend>

=item L<Hook::WrapSub>

=item L<Hook::PrePostCall>

=item L<Hook::LexWrap>

=item L<Sub::WrapPackages>

=item L<Sub::Monkey>

=item L<Monkey::Patch>

=item L<ex-monkeypatched>

=item L<Aspect::Advice::Before>

=back

BTW, with Aspects we can do this

	use Aspect;
	
	before {
		return unless $enable;
		$_->args($_->args, time_zone => $default_time_zone) unless grep { /time_zone/ } $_->args;
	} call 'DateTime::today'
	| call 'DateTime::new'
	| call 'DateTime::from_epoch'
	| call 'DateTime::last_day_of_month'
	| call 'DateTime::now';

And it is beautiful <3 <3 <3

...but I have no experience with this module in production. It can be a disaster! And my module uses only subroutine
redefinitions using pure perl, there is no aditional module. I think it is a better choice, a good perl programmer can
understand the code and change/fix if necessary. If I add something like Aspect it is hard to find someone who knows
this concept (it is an extra problem if there is a small bug or we need add something).

=head2 What this module does? and how?

To solve the time zone problem, this module override the original new method (and now, today, last_day_of_month and from_epoch),
add a pre-subroutine to add a default time zone if necessary.

Pseudocode

	ORIGINAL_SUBROUTINE = reference for DateTime::new;
	override DateTime::new = sub {
		add { time_zone => 'EST' } in arguments if has no 'time_zone' option
		goto ORIGINAL_SUBROUTINE;
	}

This solution is fine and using goto we can inherits the argument stack and other features of the new 'new' subroutine.

=head2 Final Considerations 

The CORE of this module is in BEGIN section and the first section of Fix-DateTime.t (you can find a comment).
I spend almost 1 hour to build the basic code in BEGIN section and the unit tests. The enable/disable and set_default_value 
I add later.

Using Perl::Critic I change some stuff like the change the grep for first (to be more efficient). 
Now there is only issues with severity 1 and 2.

I do not use Perl::Tidy, I think the code is clean 

The Coverage is acceptable

	----------------------------------- ------ ------ ------ ------ ------ ------
	File                                  stmt   bran   cond    sub   time  total
	----------------------------------- ------ ------ ------ ------ ------ ------
	blib/lib/Fix/DateTime.pm             100.0  100.0  100.0  100.0  100.0  100.0
	Total                                100.0  100.0  100.0  100.0  100.0  100.0
	----------------------------------- ------ ------ ------ ------ ------ ------

and I think it is a good module.

=head1 IMPORTANT

If you need add this module in your project, you need add in the main script (you can add in several files, no problem)
BUT you need add at least one test like this

	is(DateTime->today->time_zone_short_name, 'EST', "today should be EST");

Imagine if someone just remove the "use Fix::DateTime" ? Be careful!

=head1 TESTS

All tests are ok and there is no XXX, TODO or SKIP

	1..8
	ok 1 - use Fix::DateTime;
	ok 2 - require Fix::DateTime;
	    1..5
	    ok 1 - new should be EST
	    ok 2 - today should be EST
	    ok 3 - last_day_of_month should be EST
	    ok 4 - now should be EST
	    ok 5 - from_epoch should be EST
	ok 3 - Fix::DateTime should add EST as the default time_zone
	    1..5
	    ok 1 - new should be UTC
	    ok 2 - today should be UTC
	    ok 3 - last_day_of_month should be UTC
	    ok 4 - now should be UTC
	    ok 5 - from_epoch should be UTC
	ok 4 - Fix::DateTime should respect the argument time_zone
	    1..5
	    ok 1 - The object isa DateTime
	    ok 2 - The object isa DateTime
	    ok 3 - The object isa DateTime
	    ok 4 - The object isa DateTime
	    ok 5 - The object isa DateTime
	ok 5 - override methods in Fix::DateTime must respect the return type
	    1..6
	    ok 1 - the new default time_zone must be WET
	    ok 2 - new should be WET
	    ok 3 - today should be WET
	    ok 4 - last_day_of_month should be WET
	    ok 5 - now should be WET
	    ok 6 - from_epoch should be WET
	ok 6 - Fix::DateTime should add WET as the default time_zone
	    1..5
	    ok 1 - new should be UTC
	    ok 2 - today should be UTC
	    ok 3 - last_day_of_month should be floating
	    ok 4 - now should be UTC
	    ok 5 - from_epoch should be UTC
	ok 7 - Fix::DateTime should be disable
	    1..5
	    ok 1 - new should be EST
	    ok 2 - today should be EST
	    ok 3 - last_day_of_month should be EST
	    ok 4 - now should be EST
	    ok 5 - from_epoch should be EST
	ok 8 - Fix::DateTime should add EST as the default time_zone if the module is enable
	ok
	All tests successful.
	Files=1, Tests=8,  1 wallclock secs ( 0.03 usr  0.01 sys +  0.50 cusr  0.02 csys =  0.56 CPU)
	Result: PASS

=head1 FAQ

=head2 Why the default value is EST and not 'local'? 

Eastern Time Zone is a good choice for a preliminar version of this module. And in DateTime::TimeZone documentation, 
we can read:

	If a local time zone is not found, then an exception will be thrown.

In this case, set 'local' can be a problem. Be careful.

=head1 DEPENDENCIES

The following module are mandatory:

=over 8

=item L<DateTime>

=item L<List::Util>

=back

=head1 AUTHOR

Tiago Peczenyj, E<lt>tiago.peczenyj@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 by Tiago Peczenyj

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
