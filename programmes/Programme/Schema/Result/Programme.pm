use utf8;
package Programme::Schema::Result::Programme;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Programme

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<programme>

=cut

__PACKAGE__->table("programme");

=head1 ACCESSORS

=head2 prog_id

  data_type: 'binary'
  is_nullable: 0
  size: 8

=head2 prog_lib

  data_type: 'text'
  is_nullable: 0

=head2 prog_planid

  data_type: 'binary'
  is_foreign_key: 1
  is_nullable: 0
  size: 8

=head2 prog_week

  data_type: 'integer'
  is_nullable: 0

=head2 prog_day

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "prog_id",
  { data_type => "binary", is_nullable => 0, size => 8 },
  "prog_lib",
  { data_type => "text", is_nullable => 0 },
  "prog_planid",
  { data_type => "binary", is_foreign_key => 1, is_nullable => 0, size => 8 },
  "prog_week",
  { data_type => "integer", is_nullable => 0 },
  "prog_day",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</prog_id>

=back

=cut

__PACKAGE__->set_primary_key("prog_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<prog_id_prog_planid_prog_week_prog_day_unique>

=over 4

=item * L</prog_id>

=item * L</prog_planid>

=item * L</prog_week>

=item * L</prog_day>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "prog_id_prog_planid_prog_week_prog_day_unique",
  ["prog_id", "prog_planid", "prog_week", "prog_day"],
);

=head1 RELATIONS

=head2 prog_planid

Type: belongs_to

Related object: L<Programme::Schema::Result::Plan>

=cut

__PACKAGE__->belongs_to(
  "prog_planid",
  "Programme::Schema::Result::Plan",
  { plan_id => "prog_planid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 steps

Type: has_many

Related object: L<Programme::Schema::Result::Step>

=cut

__PACKAGE__->has_many(
  "steps",
  "Programme::Schema::Result::Step",
  { "foreign.step_proglib" => "self.prog_lib" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-11 18:56:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8K2DKCLV2H3pV/AakNsMtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
