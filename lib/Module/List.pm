=head1 NAME

Module::List - module `directory' listing

=head1 SYNOPSIS

	use Module::List qw(list_modules);

	$id_modules = list_modules("Data::ID::",
			{ list_modules => 1});
	$prefixes = list_modules("",
			{ list_prefixes => 1, recurse => 1 });

=head1 DESCRIPTION

This module deals with the examination of the namespace of Perl modules.
The contents of the module namespace is split across several physical
directory trees, but this module hides that detail, providing instead
a view of the abstract namespace.

=cut

package Module::List;

use warnings;
use strict;

use Carp qw(croak);
use Exporter;
use IO::Dir;

our $VERSION = "0.000";

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(list_modules);

=head1 FUNCTIONS

=over

=item list_modules(PREFIX, OPTIONS)

This function generates a listing of the contents of part of the module
namespace.  The part of the namespace under the module name prefix PREFIX
is examined, and information about it returned as specified by OPTIONS.

Module names are handled by this function in standard bareword syntax.
They are always fully-qualified; isolated name components are never used.
A module name prefix is the part of a module name that comes before
a component of the name, and so either ends with "::" or is the empty
string.

OPTIONS is a reference to a hash, the elements of which specify what is
to be returned.  The options are:

=over

=item list_modules

Boolean, default false.  If true, return names of modules in the relevant
part of the namespace.

=item list_prefixes

Boolean, default false.  If true, return module name prefixes in the
relevant part of the namespace.  Note that prefixes are returned if the
corresponding directory exists, even if there is nothing in it.

=item list_pod

Boolean, default false.  If true, return names of POD documentation
files that are in the moudle namespace.

=item recurse

Boolean, default false.  If false, only names at the next level down
from PREFIX (having one more component) are returned.  If true, names
at all lower levels are returned.

=back

Note that the default behaviour, if an empty options hash is supplied, is
to return nothing.  You I<must> specify what kind of information you want.

The function returns a reference to a hash, the keys of which are the
names of interest.  The value associated with each of these keys is undef.

=cut

sub list_modules($$) {
	my($prefix, $options) = @_;
	croak "bad module name prefix `$prefix'"
		unless $prefix =~ m#\A(?:[a-zA-Z_]\w*::(?:\w+::)*)?\z#;
	my $list_modules = $options->{list_modules};
	my $list_prefixes = $options->{list_prefixes};
	my $list_pod = $options->{list_pod};
	return {} unless $list_modules || $list_prefixes || $list_pod;
	my $recurse = $options->{recurse};
	my @prefixes = ($prefix);
	my %seen_prefixes;
	my %results;
	while(@prefixes) {
		my $prefix = pop(@prefixes);
		my $dir_suffix = $prefix;
		$dir_suffix =~ s#(\w+)::#/$1#g;
		my $module_rx = $prefix eq "" ? qr/[a-zA-Z_]\w*/ : qr/\w+/;
		my $dir_rx = qr/\A$module_rx\z/;
		my $pm_rx = qr/\A($module_rx)\.pmc?\z/;
		my $pod_rx = qr/\A($module_rx)\.pod\z/;
		foreach my $incdir (@INC) {
			my $dir = $incdir.$dir_suffix;
			my $dh = IO::Dir->new($dir) or next;
			while(defined(my $entry = $dh->read)) {
				if(($list_modules && $entry =~ $pm_rx) ||
						($list_pod &&
							$entry =~ $pod_rx)) {
					$results{$prefix.$1} = undef;
				} elsif(($list_prefixes || $recurse) &&
						$entry =~ $dir_rx &&
						-d $dir."/".$entry) {
					my $newpfx = $prefix.$entry."::";
					next if exists $seen_prefixes{$newpfx};
					$results{$newpfx} = undef
						if $list_prefixes;
					push @prefixes, $newpfx if $recurse;
				}
			}
		}
	}
	return \%results;
}

=back

=head1 SEE ALSO

L<Module::Runtime>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2004 Andrew Main (Zefram) <zefram@fysh.org>

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
