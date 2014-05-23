CREATE TABLE users (
User varchar(16) NOT NULL default '',
status enum('0','1') NOT NULL default '0',
Password varchar(64) NOT NULL default '',
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
) ENGINE=MyISAM;

CREATE TABLE schema_version (version int);
INSERT INTO schema_version (version) VALUES (1);

