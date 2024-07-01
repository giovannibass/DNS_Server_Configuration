# Basic DNS Server Installation and Configuration

Welcome! Here we'll be going over the basics of manually setting up a DNS server as well as going over the script I made to speed up this process. Below there is a [quick guide](#quick-guide) for beginners that explains the ins and outs of DNS configuration.

## Script Usage
As of right now the shell script comes with 3 options:

"Usage: sudo ./quickdns [-lqd]"

Example:
`sudo ./quickdns -l 192.168.1.10 -q 192.168.1.0/24 -d wowthatwasfast.com`

**-l**: This value specifies the IP address that the DNS server will *listen* on. More often than not it will be the same as your machine's IP.
**-q**: Determines which network(s) the server will accept *queries* from. This can be a single IP, subnet, or hostname.
**-d**: Specify the name of the domain. It will need an appropriate TLD ending (.com, .org, etc.)


## Quick Guide
1. Install BIND
```bash
sudo dnf install bind bind-utils
```

2. Configure BIND
```bash
sudo vim /etc/named.conf
```

At the minimum you'll need to specify values for these two lines in the configuration file.
```
listen-on port 53 { 127.0.0.1; [IP SERVER WILL LISTEN ON]; };
allow-query { localhost; [QUERY]; };
```

`allow-query` will accept values of:
any              # Allow queries from anyone
192.168.1.1      # Allow queries from a specific address
192.168.1.0/24   # Allow queries from a specific subnet
localnets        # Allow queries from networks directly connected to the server
none             # No queries
custom_acl       # A custom ACL

3. Create a zone file for the domain
```
sudo vim /var/named/[DOMAIN_NAME].zone
```

Paste the following, adjusting as needed.
```
$TTL 86400
@   IN  SOA     ns1.[DOMAIN_NAME]. admin.[DOMAIN_NAME]. (
            2021050101 ; Serial
            3600       ; Refresh
            1800       ; Retry
            1209600    ; Expire
            86400 )    ; Minimum TTL
;
@       IN  NS      ns1.[DOMAIN_NAME].
@       IN  A       192.168.1.10
ns1     IN  A       192.168.1.10
www     IN  A       192.168.1.10
```

If you've never seen a zone file before this can look like a lot. The most important thing to know are TTL (Time-to-live) which determmines how long DNS records are cached in devices before that device reaches out to the server for an update. In the example above that would be once every 86400 seconds (24 hours). 

**Wouldn't updating the records every few seconds be more accurate?** Yes, but in return everything would be much slower since the checks are being ran more frequently. DNS records don't change that often.

To learn about SOA (Start of Authority) and more, visit this resource from [Cloudfare](https://www.cloudflare.com/learning/dns/glossary/dns-zone/)


4. Add a zone declaration in the BIND confiugration file.
```bash
   zone "[DOMAIN_NAME]" IN {
       type master;
       file "[DOMAIN_NAME].zone";
       allow-update { none; };
   };

```
5. Update firewall rules to allow DNS traffic
```bash
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload
```

6. Enable the BIND service and confirm it's status
```bash
sudo systemctl start named
sudo systemctl enable named
sudo systemctl status named
```

7. Verify the DNS server is up with `dig`
dig @localhost [DOMAIN_NAME]

And now you're all done!
