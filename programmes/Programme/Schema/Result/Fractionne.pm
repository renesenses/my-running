use utf8;
package Programme::Schema::Result::Fractionne;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Fractionne

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<fractionne>

=cut

__PACKAGE__->table("fractionne");

=head1 ACCESSORS

=head2 frac_lib

  data_type: 'text'
  is_nullable: 0

=head2 frac_planid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 frac_week

  data_type: 'text'
  is_nullable: 0

=head2 frac_day

  data_type: 'text'
  is_nullable: 0

=head2 frac_nbsteps

  data_type: 'integer'
  is_nullable: 0

=head2 frac_hduration

  data_type: 'date'
  is_nullable: 0

=head2 frac_hallureid

  data_type: 'date'
  is_foreign_key: 1
  is_nullable: 0

=head2 frac_lduration

  data_type: 'date'
  is_nullable: 0

=head2 frac_lallureid

  data_type: 'date'
  is_foreign_key: 1
  is_nullable: 0

=head2 frac_duration

  data_type: 'date'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "frac_lib",
  { data_type => "text", is_nullable => 0 },
  "frac_planid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "frac_week",
  { data_type => "text", is_nullable => 0 },
  "frac_day",
  { data_type => "text", is_nullable => 0 },
  "frac_nbsteps",
  { data_type => "integer", is_nullable => 0 },
  "frac_hduration",
  { data_type => "date", is_nullable => 0 },
  "frac_hallureid",
  { data_type => "date", is_foreign_key => 1, is_nullable => 0 },
  "frac_lduration",
  { data_type => "date", is_nullable => 0 },
  "frac_lallureid",
  { data_type => "date", is_foreign_key => 1, is_nullable => 0 },
  "frac_duration",
  { data_type => "date", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</frac_lib>

=back

=cut

__PACKAGE__->set_primary_key("frac_lib");

=head1 UNIQUE CONSTRAINTS

=head2 C<frac_lib_frac_planid_unique>

=over 4

=item * L</frac_lib>

=item * L</frac_planid>

=back

=cut

__PACKAGE__->add_unique_constraint("frac_lib_frac_planid_unique", ["frac_lib", "frac_planid"]);

=head1 RELATIONS

=head2 frac_hallureid

Type: belongs_to

Related object: L<Programme::Schema::Result::Allure>

=cut

__PACKAGE__->belongs_to(
  "frac_hallureid",
  "Programme::Schema::Result::Allure",
  { allure_id => "frac_hallureid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 frac_lallureid

Type: belongs_to

Related object: L<Programme::Schema::Result::Allure>

=cut

__PACKAGE__->belongs_to(
  "frac_lallureid",
  "Programme::Schema::Result::Allure",
  { allure_id => "frac_lallureid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 frac_planid

Type: belongs_to

Related object: L<Programme::Schema::Result::Plan>

=cut

__PACKAGE__->belongs_to(
  "frac_planid",
  "Programme::Schema::Result::Plan",
  { plan_id => "frac_planid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-10 19:49:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+fWs0WmStgGwd4b73S9wdQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
