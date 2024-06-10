## Basic DNS Server Installation and Configuration

Welcome! Here we'll be going over the basics of manually setting up a DNS server as well as going over the script I made to speed up this process. Below there is a [quick guide](#quick-guide) and a more detailed guide (coming soon) for beginners that explains the ins and outs of DNS configuration.

#### Script Usage
This script is optimized for home lab environments and comes with default configuration settings. However, it allows you to specify the DNS server's listening address, accepted queries, and domain name. While it's capable of supporting multiple machines, additional configuration is required. Future updates will focus on enhancing customization options and improving usability for corporate environments.

#### Quick Guide
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

7. Verify the DNS is up with `dig`
dig @localhost [DOMAIN_NAME]

And now you're all done!


