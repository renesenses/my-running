use utf8;
package Programme::Schema::Result::Author;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Programme::Schema::Result::Author

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<author>

=cut

__PACKAGE__->table("author");

=head1 ACCESSORS

=head2 author_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 author_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "author_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "author_name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</author_id>

=back

=cut

__PACKAGE__->set_primary_key("author_id");

=head1 RELATIONS

=head2 plans

Type: has_many

Related object: L<Programme::Schema::Result::Plan>

=cut

__PACKAGE__->has_many(
  "plans",
  "Programme::Schema::Result::Plan",
  { "foreign.plan_authorname" => "self.author_name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-01-10 19:49:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TQx4l1ozzTnIA6b8vBEGMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
