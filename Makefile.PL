use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'	=> 'Module for parsing and creating vCards (RFC 2426) address',
    'AUTHOR'	=> 'Leo Lapworth',
    'LICENSE'	=> 'perl',
    'NAME'	=> 'Text::vCard',
    'PREREQ_PM'	=> {
		    'Text::vFile::asData' => '0.07',
		    'File::Slurp'         => '9999.04',
		    'MIME::QuotedPrint'   => '3.07',
		    'MIME::Base64'        => '3.07',
		    'Test::More'          => '0.1',
        },
    'BUILD_REQUIRES' => {
        'Digest' => '1.16',
    },
    'VERSION_FROM' => 'lib/Text/vCard.pm',
    'META_MERGE'        => {
       resources => {
           repository  =>  'http://github.com/ranguard/text-vcard',
       },
    },
    'dist'	=> {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
);

