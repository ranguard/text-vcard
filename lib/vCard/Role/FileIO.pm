package vCard::Role::FileIO;
use Moo::Role;
use Path::Tiny;

requires qw/encoding_in encoding_out/;

# PerlIO layers should look like ':encoding(UTF-8)'
# The ':encoding()' part does character set and encoding transformations.
# Without it you are just declaring the stream to be of a certain encoding.
# See PerlIO, PerlIO::encoding docs.

sub _iomode_out {
    my ($self) = @_;
    return {} if $self->encoding_out eq 'none';
    return { binmode => ':encoding(' . $self->encoding_out . ')' };
}

sub _iomode_in {
    my ($self) = @_;
    return {} if $self->encoding_in eq 'none';
    return { binmode => ':encoding(' . $self->encoding_in . ')' };
}

# Filename can be a string, a Path::Tiny obj, or a Path::Class obj.
# Returns a Path::Tiny obj.
sub _path {
    my ( $self, $filename ) = @_;
    return ref $filename eq 'Path::Class::File'    #
        ? path("$filename")
        : path($filename);    # works for strings and Path::Tiny objects
}

1;
