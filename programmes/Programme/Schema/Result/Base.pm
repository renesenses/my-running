use utf8;
package Programme::Schema::Result::Base;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Base

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<base>

=cut

__PACKAGE__->table("base");

=head1 ACCESSORS

=head2 base_lib

  data_type: 'text'
  is_nullable: 0

=head2 base_planid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 base_week

  data_type: 'text'
  is_nullable: 0

=head2 base_day

  data_type: 'text'
  is_nullable: 0

=head2 base_allureid

  data_type: 'date'
  is_foreign_key: 1
  is_nullable: 0

=head2 base_duration

  data_type: 'date'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "base_lib",
  { data_type => "text", is_nullable => 0 },
  "base_planid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "base_week",
  { data_type => "text", is_nullable => 0 },
  "base_day",
  { data_type => "text", is_nullable => 0 },
  "base_allureid",
  { data_type => "date", is_foreign_key => 1, is_nullable => 0 },
  "base_duration",
  { data_type => "date", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</base_lib>

=back

=cut

__PACKAGE__->set_primary_key("base_lib");

=head1 UNIQUE CONSTRAINTS

=head2 C<base_lib_base_planid_base_week_base_day_unique>

=over 4

=item * L</base_lib>

=item * L</base_planid>

=item * L</base_week>

=item * L</base_day>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "base_lib_base_planid_base_week_base_day_unique",
  ["base_lib", "base_planid", "base_week", "base_day"],
);

=head1 RELATIONS

=head2 base_allureid

Type: belongs_to

Related object: L<Programme::Schema::Result::Allure>

=cut

__PACKAGE__->belongs_to(
  "base_allureid",
  "Programme::Schema::Result::Allure",
  { allure_id => "base_allureid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 base_planid

Type: belongs_to

Related object: L<Programme::Schema::Result::Plan>

=cut

__PACKAGE__->belongs_to(
  "base_planid",
  "Programme::Schema::Result::Plan",
  { plan_id => "base_planid" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-10 19:49:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o8N8aerv6dtw9/FOtZe6WQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
