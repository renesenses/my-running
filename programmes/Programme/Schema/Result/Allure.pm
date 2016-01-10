use utf8;
package Programme::Schema::Result::Allure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Allure

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<allure>

=cut

__PACKAGE__->table("allure");

=head1 ACCESSORS

=head2 allure_id

  data_type: 'text'
  is_nullable: 0

=head2 allure_vitesse

  data_type: 'text'
  is_nullable: 0

=head2 allure_tkilo

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "allure_id",
  { data_type => "text", is_nullable => 0 },
  "allure_vitesse",
  { data_type => "text", is_nullable => 0 },
  "allure_tkilo",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</allure_id>

=back

=cut

__PACKAGE__->set_primary_key("allure_id");

=head1 RELATIONS

=head2 bases

Type: has_many

Related object: L<Programme::Schema::Result::Base>

=cut

__PACKAGE__->has_many(
  "bases",
  "Programme::Schema::Result::Base",
  { "foreign.base_allureid" => "self.allure_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fractionne_frac_hallureids

Type: has_many

Related object: L<Programme::Schema::Result::Fractionne>

=cut

__PACKAGE__->has_many(
  "fractionne_frac_hallureids",
  "Programme::Schema::Result::Fractionne",
  { "foreign.frac_hallureid" => "self.allure_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fractionne_frac_lallureids

Type: has_many

Related object: L<Programme::Schema::Result::Fractionne>

=cut

__PACKAGE__->has_many(
  "fractionne_frac_lallureids",
  "Programme::Schema::Result::Fractionne",
  { "foreign.frac_lallureid" => "self.allure_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-10 19:49:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sQreycEq1ktMdKhZYQtWJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
