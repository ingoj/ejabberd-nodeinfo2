# ejabberd-nodeinfo2
This script reports some statistical information in a x-nodeinfo2 JSON file for https://the-federation.info

# Requirements
You need to have PostgreSQL as your database backend for all your vhosts. To determine whether or not your domain has registration open or not, you need to have curl installed. 

# Configuration
The script should be pretty self-explaining. Of course you need to make some changes. 
You also need your webserver to redirect to the correct x-nodeinfo file on the disk. The files are named $VHOST_x-nodeinfo2

# Notice
- It may be that this is just a temporary workaround and someone else will write an ejabberd module for nodeinfo2. When this happens, this bash script will become obsolete & deprecated.
- currently you can't have two services registered on the-federation.info, e.g. Friendica and XMPP
