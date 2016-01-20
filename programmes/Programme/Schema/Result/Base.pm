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
  is_foreign_key: 1
  is_nullable: 0

=head2 base_type

  data_type: 'char'
  default_value: 'b'
  is_foreign_key: 1
  is_nullable: 0
  size: 1

=head2 base_proglib

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 base_allureid

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "base_lib",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "base_type",
  {
    data_type => "char",
    default_value => "b",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 1,
  },
  "base_proglib",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "base_allureid",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</base_lib>

=back

=cut

__PACKAGE__->set_primary_key("base_lib");

=head1 UNIQUE CONSTRAINTS

=head2 C<base_lib_base_type_unique>

=over 4

=item * L</base_lib>

=item * L</base_type>

=back

=cut

__PACKAGE__->add_unique_constraint("base_lib_base_type_unique", ["base_lib", "base_type"]);

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

=head2 step

Type: belongs_to

Related object: L<Programme::Schema::Result::Step>

=cut

__PACKAGE__->belongs_to(
  "step",
  "Programme::Schema::Result::Step",
  {
    step_lib     => "base_lib",
    step_proglib => "base_proglib",
    step_type    => "base_type",
  },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-11 18:56:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5PlsEf/InjK6VErSBV6Ang


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
