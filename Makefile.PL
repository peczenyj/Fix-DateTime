use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Fix::DateTime',
    VERSION_FROM      => 'lib/Fix/DateTime.pm', # finds $VERSION
    PREREQ_PM         => { 
		DateTime => 0.78, 
		List::Util =>  0
	}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Fix/DateTime.pm', # retrieve abstract from module
       AUTHOR         => 'Tiago Peczenyj <tiago.peczenyj@gmail.com>') : ()),
);
