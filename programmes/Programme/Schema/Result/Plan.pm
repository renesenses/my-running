use utf8;
package Programme::Schema::Result::Plan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Plan

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<plan>

=cut

__PACKAGE__->table("plan");

=head1 ACCESSORS

=head2 plan_id

  data_type: 'text'
  is_nullable: 0

=head2 plan_name

  data_type: 'text'
  is_nullable: 0

=head2 plan_authorname

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "plan_id",
  { data_type => "text", is_nullable => 0 },
  "plan_name",
  { data_type => "text", is_nullable => 0 },
  "plan_authorname",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</plan_id>

=back

=cut

__PACKAGE__->set_primary_key("plan_id");

=head1 RELATIONS

=head2 bases

Type: has_many

Related object: L<Programme::Schema::Result::Base>

=cut

__PACKAGE__->has_many(
  "bases",
  "Programme::Schema::Result::Base",
  { "foreign.base_planid" => "self.plan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fractionnes

Type: has_many

Related object: L<Programme::Schema::Result::Fractionne>

=cut

__PACKAGE__->has_many(
  "fractionnes",
  "Programme::Schema::Result::Fractionne",
  { "foreign.frac_planid" => "self.plan_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plan_authorname

Type: belongs_to

Related object: L<Programme::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "plan_authorname",
  "Programme::Schema::Result::Author",
  { author_name => "plan_authorname" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-10 19:49:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VuADFEJE6xaNq4xp7DKwWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
