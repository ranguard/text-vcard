use vCard;
use Test::Most;

my $vcard = vCard->new;
my $nickname = $vcard->load_file( 't/nickname.vcf' )->nickname();
ok($nickname, 'T-nickname');
done_testing;
