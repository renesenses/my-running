rm programmev2.db
rm -R Programme
sqlite3 programmev2.db < cr-programmedb-v2.sql
perl -w mk-programmedb-classes-v2.pl