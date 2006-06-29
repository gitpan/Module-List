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
use IO::Dir 1.03;

our $VERSION = "0.001";

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
files that are in the module namespace.

=item trivial_syntax

Boolean, default false.  If false, only valid bareword names are
permitted.  If true, bareword syntax is ignored, and any "::"-separated
name that can be turned into a correct filename by C<s!::!/!g> is
permitted.  This is of no use in listing actual Perl modules, because the
illegal names can't be used in Perl, but some programs such as B<perldoc>
use a "::"-separated name for the sake of appearance without really
using bareword syntax.  The loosened syntax applies both to the names
returned and to the I<PREFIX> parameter.

Precisely, the `trivial syntax' is that each "::"-separated component
cannot be "." or "..", cannot contain "::" or "/", and (except for the
final component of a leaf name) cannot end with ":".  This is precisely
what is required to achieve a unique interconvertible "::"-separated
path syntax.

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
	my $trivial_syntax = $options->{trivial_syntax};
	my($root_leaf_rx, $root_notleaf_rx);
	my($notroot_leaf_rx, $notroot_notleaf_rx);
	if($trivial_syntax) {
		$root_leaf_rx = $notroot_leaf_rx = qr#:?(?:[^/:]+:)*[^/:]+:?#;
		$root_notleaf_rx = $notroot_notleaf_rx =
			qr#:?(?:[^/:]+:)*[^/:]+#;
	} else {
		$root_leaf_rx = $root_notleaf_rx = qr/[a-zA-Z_]\w*/;
		$notroot_leaf_rx = $notroot_notleaf_rx = qr/\w+/;
	}
	croak "bad module name prefix `$prefix'"
		unless $prefix =~ /\A(?:${root_notleaf_rx}::
					 (?:${notroot_notleaf_rx}::)*)?\z/x &&
			 $prefix !~ /(?:\A|[^:]::)\.\.?::/;
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
		$dir_suffix =~ s#::#/#g;
		$dir_suffix =~ s#\A(.*)/\z#/$1#s;
		my $module_rx =
			$prefix eq "" ? $root_leaf_rx : $notroot_leaf_rx;
		my $pm_rx = qr/\A($module_rx)\.pmc?\z/;
		my $pod_rx = qr/\A($module_rx)\.pod\z/;
		my $dir_rx =
			$prefix eq "" ? $root_notleaf_rx : $notroot_notleaf_rx;
		$dir_rx = qr/\A$dir_rx\z/;
		foreach my $incdir (@INC) {
			my $dir = $incdir.$dir_suffix;
			my $dh = IO::Dir->new($dir) or next;
			while(defined(my $entry = $dh->read)) {
				next if $entry =~ /\A\.\.?\z/;
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

Copyright (C) 2004, 2006 Andrew Main (Zefram) <zefram@fysh.org>

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
