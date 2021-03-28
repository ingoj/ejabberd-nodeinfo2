# ejabberd-nodeinfo2
This script reports some statistical information in a x-nodeinfo2 JSON file for https://the-federation.info

# Requirements
You need to have PostgreSQL as your database backend for all your vhosts and the database needs to be in new format (all domains in one database with global SQL config). To determine whether or not your domain has registration open or not, you need to have curl installed. 

# Configuration
The script should be pretty self-explaining. Of course you need to make some changes. 
You also need your webserver to redirect to the correct x-nodeinfo file on the disk. The files are named $VHOST_x-nodeinfo2, maybe something like:

```apache 
RewriteEngine on
RewriteRule   "^/.well-known/x-nodeinfo2"  "http://jabber.windfluechter.net/.well-known/hookipa.net_x-nodeinfo2"  [R,L]
```

# Notice
- It may be that this is just a temporary workaround and someone else will write an ejabberd module for nodeinfo2. When this happens, this bash script will become obsolete & deprecated.
- currently you can't have two services registered on the-federation.info, e.g. Friendica and XMPP
- this script only works with global SQL configuration, not per-host config in config_hosts: section

# More Information
You can find more information about nodeinfo2 here: https://git.feneas.org/jaywink/nodeinfo2

# ToDo
- Adapt to support MySQL/MariaDB backend: done! But actual MySQL queries are missing... 
Example output (reformatted for easier read): 
```
ejabberd=# select concat(
(select count(username) from last where extract(epoch from now())-seconds::integer<86400*7 and server_host='VHOST')
||':'||
(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30 and server_host='VHOST')
||':'||
(select count(username) from last where extract(epoch from now())-seconds::integer<86400*30*6 and server_host='VHOST')
||':'||
(select count(username) from users where server_host='VHOST')
||':'||
(select count(*) from archive where server_host='VHOST'));

      concat
-------------------
 10:12:15:15:17509
(1 row)
```
So, the expected output is: `ActiveWeek:ActiveMonth:ActiveHalfyear:TotalUsers:LocalPosts`
