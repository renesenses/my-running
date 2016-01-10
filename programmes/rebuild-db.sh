rm programme.db
rm -R Programme
sqlite3 programme.db < cr-programmedb.sql
perl -w mk-programmedb-classes.pl