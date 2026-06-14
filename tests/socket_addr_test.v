import netio

fn test_socket_addr_new_ipv4() {
	addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 1080)
	assert addr.str() == '127.0.0.1:1080'
}

fn test_socket_addr_new_ipv6() {
	addr := netio.SocketAddr.new_ipv6([u8(0xfd), 0xf1, 0x72, 0xd1, 0x00, 0x33, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x47]!, 25535)
	assert addr.str() == '[fdf1:72d1:0033:0000:0000:0000:0000:0247]:25535'
}

fn test_socket_addr_new_unix() {
	path := $if windows { r'\\.\pipe\app.sock' } $else { '/run/app.sock' }
	addr := netio.SocketAddr.new_unix(path)!
	assert addr.str() == path
}

fn test_socket_addr_is_empty() {
	assert unsafe { netio.SocketAddr.new(netio.af_unspec, 16).is_empty() }
	assert netio.SocketAddr{}.is_empty()
	assert !netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 16).is_empty()
}
