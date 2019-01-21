echo "### Install postgresql-jdbc ###"
# yum install of postgres is available!
sudo yum -y install postgresql-jdbc

#chmod 744 /usr/share/java/postgresql-jdbc.jar

# run on ambari server
echo "### Register postgresql-jdbc.jar with ambari-server ###"
sudo ambari-server setup --jdbc-db=postgres --jdbc-driver=/usr/share/java/postgresql-jdbc.jar

# tee /var/lib/pgsql/data/pg_hba.conf <<EOF
# sudo tee /var/lib/pgsql/9.6/data/pg_hba.conf <<EOF
PG_HBA_CONF=$(sudo find / -name "pg_hba.conf")
sudo tee $PG_HBA_CONF <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host  all  all 0.0.0.0/0 md5

# "local" is for Unix domain socket connections only
local   all   hive,postgres,rangeradmin,rangerkms                                     trust
# IPv4 local connections:
host    all   hive,postgres,rangeradmin,rangerkms             127.0.0.1/32            trust
# IPv6 local connections:
host    all   hive,postgres,rangeradmin,rangerkms             ::1/128                 ident
# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     postgres                                peer
#host    replication     postgres        127.0.0.1/32            ident
#host    replication     postgres        ::1/128                 ident

local  all  ambari,mapred md5
host  all   ambari,mapred 0.0.0.0/0  md5
host  all   ambari,mapred ::/0 md5
EOF

#service postgresql restart
sudo service postgresql-9.6.service restart
sudo service postgresql.service restart

echo "GRANT ALL PRIVILEGES ON DATABASE postgres to postgres;" > /tmp/hdp_postgres_setup.sql

# create file ranger.sql
echo "create database ranger;
CREATE USER rangeradmin;
ALTER USER rangeradmin WITH PASSWORD 'rangeradmin';
GRANT ALL PRIVILEGES ON DATABASE ranger to rangeradmin;" >> /tmp/hdp_postgres_setup.sql

# create file rangerkms.sql
echo "create database rangerkms;
CREATE USER rangerkms;
ALTER USER rangerkms WITH PASSWORD 'rangerkms';
GRANT ALL PRIVILEGES ON DATABASE rangerkms to rangerkms;" >> /tmp/hdp_postgres_setup.sql

psql -U postgres -a -f /tmp/hdp_postgres_setup.sql
