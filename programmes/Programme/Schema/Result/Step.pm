use utf8;
package Programme::Schema::Result::Step;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Step

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<step>

=cut

__PACKAGE__->table("step");

=head1 ACCESSORS

=head2 step_lib

  data_type: 'text'
  is_nullable: 0

=head2 step_type

  data_type: 'char'
  default_value: 'b'
  is_nullable: 0
  size: 1

=head2 step_proglib

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 step_duration

  data_type: 'date'
  is_nullable: 0

=head2 step_tolerance

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "step_lib",
  { data_type => "text", is_nullable => 0 },
  "step_type",
  { data_type => "char", default_value => "b", is_nullable => 0, size => 1 },
  "step_proglib",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "step_duration",
  { data_type => "date", is_nullable => 0 },
  "step_tolerance",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</step_lib>

=back

=cut

__PACKAGE__->set_primary_key("step_lib");

=head1 UNIQUE CONSTRAINTS

=head2 C<step_lib_step_type_step_proglib_unique>

=over 4

=item * L</step_lib>

=item * L</step_type>

=item * L</step_proglib>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "step_lib_step_type_step_proglib_unique",
  ["step_lib", "step_type", "step_proglib"],
);

=head1 RELATIONS

=head2 bases

Type: has_many

Related object: L<Programme::Schema::Result::Base>

=cut

__PACKAGE__->has_many(
  "bases",
  "Programme::Schema::Result::Base",
  {
    "foreign.base_lib"     => "self.step_lib",
    "foreign.base_proglib" => "self.step_proglib",
    "foreign.base_type"    => "self.step_type",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fractionnes

Type: has_many

Related object: L<Programme::Schema::Result::Fractionne>

=cut

__PACKAGE__->has_many(
  "fractionnes",
  "Programme::Schema::Result::Fractionne",
  {
    "foreign.frac_lib"     => "self.step_lib",
    "foreign.frac_proglib" => "self.step_proglib",
    "foreign.frac_type"    => "self.step_type",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 step_proglib

Type: belongs_to

Related object: L<Programme::Schema::Result::Programme>

=cut

__PACKAGE__->belongs_to(
  "step_proglib",
  "Programme::Schema::Result::Programme",
  { prog_lib => "step_proglib" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-11 18:56:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cJcxKzSvd+BDQ3IzYY3gLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
