#!/usr/bin/perl

use Test::More;
use lib qw(./lib);
use MIME::Base64;
use Path::Class;

BEGIN { use_ok('Text::vCard::Addressbook'); }

my $address_book = Text::vCard::Addressbook    #
    ->new( { 'source_file' => 't/base64.vcf', } );

ok( $address_book, "Got an address book object" );

my ($vcard) = ( $address_book->vcards );
ok( $vcard, 'vCard is present' );

my ($photo) = $vcard->get('photo');
ok( $photo, 'Photo is present' );

my $base64_image
    = 'R0lGODlhlgAyALMPAAAAAP9BAP////9PAP//AP/xAP/ZAP//Vv//sP+KAP+gAP9tAP9fAP+wAP/L
AP///yH5BAEAAA8ALAAAAACWADIAQAT/8MlJq7046827/2DIAYIAVGRpAiyaqvApvXAtP2xc3hO9
W6QWhcbD1VRF49GEARCe0JPzmZxSgVZC8pLVoqDenlPY3fbA2myxnGFvAIp4nCXfwuWKNd4MxOdR
e4B/OH58Yn6DgnVthR0AA5CRkXaSA2uSVUI9lZeTKJAyj5iOoqBcnG2ojgGsrQF8AK6sPLGyLLNN
ta9YraG6u7eytlW2vL1mwbOGIszNzs/Q0SFBM0s2LjY3PkuaYtfYPx85TFg+duNITQjrCLTrVezt
XPHtUvViLADx8Oy+9zP05GHZB7AfEHqwEGpgYaBhQ4YPuTiMOGTish4TDayxiIIigIzL/z5mdFgF
ZBuTbxaoVAlg5QI7Ll+icHlxRsw1NGfKxHHTQ8uV3WzmbNJzlbBdXIoNcUUrFrFjKJguxTWD6cVf
SKP2WijVJ9ZXmr4O8yUsKBCqZ4+CFaM2q1a3PY7akRstX7l8ZvHlvRvSbq6aLq76XTh4GrUZ25A0
5RbK2jfEMc49HhEDhbUql9sUxhFkTWUu2dJV4wY6XYrFkYEo7vGZdbbSqZscmD3bV20gtA/Yyb13
CADeuGtruz0jN/HgtKUA920c2e/lTQpIny5FulkA0wtUyQ4YO3cU34dYn5FdO+Hy3seLD88F/QgH
8OGziG8nvnwU9rvbd7AmP37+M+x31f9+/NXnXxMCjpDAgguywKAdDDaIQoTdRZjAGhROeOEMFtYE
gIUbavggMh16yMCJDACAYopcrMjiECt25+IaMaJwYigz+lQjEDk20eMIlXhyyihDECmGJZ8YOYOS
pYSiyhtPFqlkkkKOIBcyw0ylDGJwVbXVW1klo80veG2Gg1LSTKNWUPmUZVcyaCaFlpZgKSVWWWnN
6WWcceHp1Za5ZMlFML35BouY5+hi5lK9IaoZVGlGKumklFbKmi/5HGEmOt2Uiddqg54mWaGgNTqO
qaI2cxg6mQ1B2miOheONYpiB6oitkGmKxavTyMoZY5a1ymqrsOJarK+I1YpsYuS4yiv/CKcFi6xr
xDJbJrUrdCataM522tqxOygb264rdKsat75lE+1orGay2rrg2hEbEeCgm+63B/WjzTv58tuvv4vi
QBAKAwsskMEFE6wvwgf3oJA6CSMnHA7JSbxbxSM05wLGxenWQ3PO8cYCdB0nhwzIC6HhhRVVgNFy
FB6isYbLX4ThRhMyq1FzFG3I/EZ52rGgHnjUrcHez0fjkLR3obi3ENBFE01dG04vBJJIGknEUUUk
+YQSRl1zHcrXuYykUUlbax32Qg203TYLbtvh9tsozN3d3A2sYXfdec+A91V45y333k38PUIhdyQy
RCOLL+II4z0E0ngokC+ESCaV+5Y5/xcdZghEhyKGqKDnPZDOYYgfmq4Z6KGL/rnqudA0lE5A0b7T
CEX1MLtQoeSeUu1A+G777W/EuKONx8+Q/EI/Ko8ijS+quHwb0+PQPPLP+xQkKJRMWQqSn3RS5ZLj
s2AKDlGmMiX541N5vpV0yflln3o6tQafZGpJ1vxcdQVmo1bxyZqagD//nek6BtyTWxRFPz3Jz4Gc
wQthJChAPz1wTljBy1ry1KX8KRBTbekgn5IVMBKSik6Q4iAG2wJACCqqTVC5UwrpxKavnMOCb2Ah
PkKIlDsZglCDCuH+1oRAQKHQhfEzijLWAKdjMHGEvHCOm+43RQJu0AWCwmIAxVFCExiSioJpupZm
upisN4DxLye0lBrXyEYPRAAAOw==' . "\x0A";
my $base64_image_decoded = MIME::Base64::decode($base64_image);
is $photo->value, $base64_image_decoded, 'compare decoded values';

my $photo_value = MIME::Base64::encode( $photo->value );
is $photo_value, $base64_image, 'compare encoded values';

# $vcard->as_string returns a decoded string.
# slurp( iomode => '<:encoding(UTF-8)' ) returns a decoded string
my $original_vcard
    = file('t/base64.vcf')->slurp( iomode => '<:encoding(UTF-8)' );
is $vcard->as_string, $original_vcard,
    'as_string() output is the same as the input';

# Uncomment these lines to view the gif and inspect the new and original images
# visually.
#file('/tmp/victoly_original.gif')->spew($base64_image_decoded);
#file('/tmp/victoly_new.gif')->spew( $photo->value );

done_testing;
