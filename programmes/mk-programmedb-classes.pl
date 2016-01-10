#!/usr/bin/env perl

use DBIx::Class::Schema::Loader qw/ make_schema_at /;
make_schema_at(
	'Programme::Schema',
	{ 	debug => 1,
		dump_directory => '.',
	},
	[ 'dbi:SQLite:programme.db', '', '',
	],
);