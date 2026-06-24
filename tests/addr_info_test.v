import netio

fn test_addr_info_localhost() {
	addrs := netio.addr_info(node: 'localhost', socktype: netio.sock_stream)!
	assert addrs.len > 0
	for a in addrs {
		assert a.family == netio.af_inet || a.family == netio.af_inet6
		assert a.socktype == netio.sock_stream
	}
}

fn test_addr_info_passive() {
	addrs := netio.addr_info(
		service:  '0'
		socktype: netio.sock_stream
		family:   netio.af_inet
		flags:    netio.ai_passive
	)!
	assert addrs.len > 0
}

fn test_name_info_ipv4() {
	addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 1080)
	host, port := netio.name_info(addr, flags: netio.ni_numerichost | netio.ni_numericserv)!
	assert host == '127.0.0.1'
	assert port == '1080'
}

fn test_name_info_ipv6() {
	addr := netio.SocketAddr.new_ipv6([16]u8{}, 9999)
	host, port := netio.name_info(addr, flags: netio.ni_numerichost | netio.ni_numericserv)!
	assert host == '::'
	assert port == '9999'
}
