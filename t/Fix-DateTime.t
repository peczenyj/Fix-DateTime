use DateTime;
use Test::More tests => 8;

BEGIN { use_ok('Fix::DateTime') };

require_ok('Fix::DateTime');

subtest 'Fix::DateTime should add EST as the default time_zone' => sub {
	plan tests => 5;
	
	is(DateTime->new(year => 2099)->time_zone_short_name,         'EST', "new should be EST");
	is(DateTime->today->time_zone_short_name,                     'EST', "today should be EST");
	is(DateTime->last_day_of_month(month => 2, 
		year => 2099)->time_zone_short_name,                      'EST', "last_day_of_month should be EST");
	is(DateTime->now->time_zone_short_name,                       'EST', "now should be EST");
	is(DateTime->from_epoch(epoch => 1024)->time_zone_short_name, 'EST', "from_epoch should be EST");
};

subtest 'Fix::DateTime should respect the argument time_zone' => sub {
	plan tests => 5;
	
	is(DateTime->new(year => 2099, 
		time_zone => 'UTC')->time_zone_short_name,                'UTC', "new should be UTC");
	is(DateTime->today(time_zone => 'UTC')->time_zone_short_name, 'UTC', "today should be UTC");
	is(DateTime->last_day_of_month(month => 2, 
		year => 2099, time_zone => 'UTC')->time_zone_short_name,  'UTC', "last_day_of_month should be UTC");
	is(DateTime->now(time_zone => 'UTC')->time_zone_short_name,   'UTC', "now should be UTC");
	is(DateTime->from_epoch(epoch => 1024, 
		time_zone => 'UTC')->time_zone_short_name,                'UTC', "from_epoch should be UTC");
};

subtest 'override methods in Fix::DateTime must respect the return type' => sub{
	plan tests => 5;
	isa_ok(DateTime->new(year => 2099),           'DateTime');
	isa_ok(DateTime->today,                       'DateTime');
	isa_ok(DateTime->last_day_of_month(month => 2, 
		year => 2099),                            'DateTime');
	isa_ok(DateTime->now,                         'DateTime');
	isa_ok(DateTime->from_epoch(epoch => 1024),   'DateTime');
	
};

## end of basic tests (0.01), now starting tests for 0.02 version 

subtest 'Fix::DateTime should add WET as the default time_zone' => sub {
	plan tests => 6;
	
	my $result = Fix::DateTime::set_default_value 'WET';
	
	is($result->{new}, 'WET', 'the new default time_zone must be WET');
	eval {	
		is(DateTime->new(year => 2099)->time_zone_short_name,         'WET', "new should be WET");
		is(DateTime->today->time_zone_short_name,                     'WET', "today should be WET");
		is(DateTime->last_day_of_month(month => 2, 
			year => 2099)->time_zone_short_name,                      'WET', "last_day_of_month should be WET");
		is(DateTime->now->time_zone_short_name,                       'WET', "now should be WET");
		is(DateTime->from_epoch(epoch => 1024)->time_zone_short_name, 'WET', "from_epoch should be WET");		
	};
	
	Fix::DateTime::set_default_value $result->{old};
};


subtest 'Fix::DateTime should be disable' => sub {
	plan tests => 5;
	
	Fix::DateTime::disable;
	
	eval {
		is(DateTime->new(year => 2099, 
			time_zone => 'UTC')->time_zone_short_name, 'UTC', "new should be UTC");
		is(DateTime->today()->time_zone_short_name,    'UTC', "today should be UTC");
		is(DateTime->last_day_of_month(month => 2, 
			year => 2099)->time_zone_short_name,       'floating', "last_day_of_month should be floating");
		is(DateTime->now()->time_zone_short_name,      'UTC', "now should be UTC");
		is(DateTime->from_epoch(epoch => 1024)
			->time_zone_short_name,                    'UTC', "from_epoch should be UTC");
	};
	
	Fix::DateTime::enable;
};


subtest 'Fix::DateTime should add EST as the default time_zone if the module is enable' => sub {
	plan tests => 5;
	
	Fix::DateTime::disable;
	Fix::DateTime::enable;
	
	is(DateTime->new(year => 2099)->time_zone_short_name,         'EST', "new should be EST");
	is(DateTime->today->time_zone_short_name,                     'EST', "today should be EST");
	is(DateTime->last_day_of_month(month => 2, 
		year => 2099)->time_zone_short_name,                      'EST', "last_day_of_month should be EST");
	is(DateTime->now->time_zone_short_name,                       'EST', "now should be EST");
	is(DateTime->from_epoch(epoch => 1024)->time_zone_short_name, 'EST', "from_epoch should be EST");
};