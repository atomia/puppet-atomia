CREATE TABLE users (
User varchar(16) NOT NULL default '',
status enum('0','1') NOT NULL default '0',
Password TEXT NOT NULL,
Uid varchar(11) NOT NULL default '-1',
Gid varchar(11) NOT NULL default '-1',
Dir varchar(128) NOT NULL default '',
ULBandwidth smallint(5) NOT NULL default '0',
DLBandwidth smallint(5) NOT NULL default '0',
comment tinytext NOT NULL,
QuotaSize smallint(5) NOT NULL default '0',
QuotaFiles int(11) NOT NULL default 0,
PRIMARY KEY (User),
UNIQUE KEY User (User)
) ENGINE=InnoDB;

CREATE TABLE schema_version (version int) ENGINE=InnoDB;
INSERT INTO schema_version (version) VALUES (1);

