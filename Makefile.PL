use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'	=> 'Module for parsing and creating vCards (RFC 2426) address',
    'AUTHOR'	=> 'Leo Lapworth',
    'LICENSE'	=> 'perl',
    'NAME'	=> 'Text::vCard',
    'PREREQ_PM'	=> {
		    'Text::vFile::asData' => '0.05',
		    'File::Slurp' => '9999.04',
		    'MIME::QuotedPrint' => '3.07',
		    'Test::More' => '0.1',
		   },
    'VERSION_FROM' => 'lib/Text/vCard.pm',
    'dist'	=> {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
);

