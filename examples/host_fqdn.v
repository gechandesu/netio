import netio
import os

fn main() {
	// Resolve the fully qualified domain name for host.
	// This programm is analog for `hostname -f` command.
	hostname := os.hostname()!
	ai := netio.addr_info(node: hostname, flags: netio.ai_canonname) or { []netio.AddrInfo{} }
	mut fqdn := hostname
	for a in ai {
		// Not needed to iterate over all entries, return the first one per getaddrinfo(3).
		fqdn = a.canonical
		break
	}
	println(fqdn)
}
