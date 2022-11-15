#!/usr/bin/perl

# This script moves all the files in all
# subdirectories into the current directory.
# This is useful for creating playlists and
# slideshows, or for re-organizing files.

chomp($top = `pwd`);

mvhere(".");

sub mvhere
{
	$dir = shift;
	chdir($dir);
	my $cwd = $top."/".$dir;
	for $f (`ls`)
	{
		chomp($f);
		if(-d $f)
		{
			mvhere($f);
		}
		elsif(-f $f)
		{
			`mv $f $top/`;
		}
	}
	chdir("..");
}
