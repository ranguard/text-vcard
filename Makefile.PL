use ExtUtils::MakeMaker;

my $ABSTRACT = "Module for parsing and creating vCards (RFC 2426) address";

WriteMakefile1(
          LICENSE => 'perl',
          META_MERGE => {
                    resources => {
                              repository => 'http://github.com/ranguard/text-vcard',
                    },
          },
          #BUILD_REQUIRES => {
          #},

 	'NAME'		=> 'Text::vCard',
	'ABSTRACT'	=> $ABSTRACT,
	'AUTHOR'	=> 'Leo Lapworth',
	'VERSION_FROM'	=> 'lib/Text/vCard.pm',
	'PREREQ_PM'		=> {
    	Text::vFile::asData => 0.05,
    	Test::More 			=> 0.1,
		File::Slurp 		=> 9999.04,
		MIME::QuotedPrint 	=> 3.07,
    }, 
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
          my %params=@_;
          my $eumm_version=$ExtUtils::MakeMaker::VERSION;
          $eumm_version=eval $eumm_version;
          die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
          die "License not specified" if not exists $params{LICENSE};
          if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
                    #EUMM 6.5502 has problems with BUILD_REQUIRES
                    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
                    delete $params{BUILD_REQUIRES};
          }
          delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
          delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
          delete $params{META_MERGE} if $eumm_version < 6.46;
          delete $params{META_ADD} if $eumm_version < 6.46;
          delete $params{LICENSE} if $eumm_version < 6.31;
          delete $params{AUTHOR} if $] < 5.005;
          delete $params{ABSTRACT_FROM} if $] < 5.005;
          delete $params{BINARY_LOCATION} if $] < 5.005;

          WriteMakefile(%params);
}

