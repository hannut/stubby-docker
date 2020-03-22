#! /bin/sh

reserved=12582912
availableMemory=$((1024 * $( (fgrep MemAvailable /proc/meminfo || fgrep MemTotal /proc/meminfo) | sed 's/[^0-9]//g' ) ))
if [ $availableMemory -le $(($reserved * 2)) ]; then
    echo "Not enough memory" >&2
    exit 1
fi
availableMemory=$(($availableMemory - $reserved))
msg_cache_size=$(($availableMemory / 3))
rr_cache_size=$(($availableMemory / 3))
nproc=$(nproc)
if [ $nproc -gt 1 ]; then
    threads=$(($nproc - 1))
else
    threads=1
fi
# Lookup IP of Stubby container as work around because forward-host did not
# resolve stubby correctly and does not support @port syntax.
# This uses ping rather than 'dig +short stubby' to avoid needing dnsutils
# package.
stubby_ip=$(ping -4 -c 1 stubby | head -n 1 | cut -d ' ' -f 3 | cut -d '(' -f 2 | cut -d ')' -f 1)
stubby_port=@8053
stubby=$stubby_ip$stubby_port

# Use this default unbound.conf unless a user mounts a custom one:
if [ ! -f /unbound.conf ]; then
sed \
    -e "s/@MSG_CACHE_SIZE@/${msg_cache_size}/" \
    -e "s/@RR_CACHE_SIZE@/${rr_cache_size}/" \
    -e "s/@THREADS@/${threads}/" \
    -e "s/@STUBBY@/${stubby}/" \
    > /unbound.conf << EOT
server:
  verbosity: 1
  num-threads: @THREADS@
  interface: 0.0.0.0@53
  so-reuseport: yes
  edns-buffer-size: 1472
  delay-close: 10000
  cache-min-ttl: 60
  cache-max-ttl: 86400
  do-daemonize: no
  deny-any: yes
  username: "unbound"
  log-queries: no
  hide-version: yes
  hide-identity: yes
  identity: "DNS"
  harden-algo-downgrade: yes
  harden-short-bufsize: yes
  harden-large-queries: yes
  harden-glue: yes
  harden-dnssec-stripped: yes
  harden-below-nxdomain: yes
  harden-referral-path: no
  do-not-query-localhost: no
  prefetch: yes
  prefetch-key: yes
  qname-minimisation: yes
  aggressive-nsec: yes
  ratelimit: 1000
  rrset-roundrobin: yes
  minimal-responses: yes
  #chroot: "/opt/unbound/etc/unbound"
  #directory: "/opt/unbound/etc/unbound"
  #auto-trust-anchor-file: "var/root.key"
  num-queries-per-thread: 4096
  outgoing-range: 8192
  msg-cache-size: @MSG_CACHE_SIZE@
  rrset-cache-size: @RR_CACHE_SIZE@
  neg-cache-size: 4M
  serve-expired: yes
  use-caps-for-id: yes
  unwanted-reply-threshold: 10000
  val-clean-additional: yes
  #private-address: 10.0.0.0/8
  private-address: 172.16.0.0/12
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: fd00::/8
  private-address: fe80::/10
  private-address: ::ffff:0:0/96
  access-control: 127.0.0.1/32 allow
  access-control: 192.168.1.1/24 allow
  access-control: 172.16.0.0/12 allow
  access-control: 10.0.0.0/8 allow
  include: /opt/unbound/etc/unbound/a-records.conf
  forward-zone:
    name: "."
    forward-addr: @STUBBY@

remote-control:
  control-enable: no

EOT
fi

/usr/lib/unbound/package-helper root_trust_anchor_update

exec /usr/sbin/unbound -d -c /unbound.conf
