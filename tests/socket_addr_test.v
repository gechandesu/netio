import netio
import encoding.binary

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

fn test_socket_addr_family_ptr_size() {
	addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 1080)
	assert addr.family() == netio.af_inet
	assert !isnil(addr.ptr())
	assert addr.size() == 16
}

fn test_socket_addr_from_ptr() {
	orig := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 8080)
	copy := unsafe { netio.SocketAddr.from_ptr_copy(orig.ptr(), orig.size())! }
	assert copy.str() == orig.str()

	borrowed := unsafe { netio.SocketAddr.from_ptr(orig.ptr(), orig.size())! }
	assert borrowed.str() == orig.str()
}

fn test_socket_addr_write() {
	mut addr := unsafe { netio.SocketAddr.new(netio.af_inet, 16) }
	unsafe {
		addr.write(binary.big_endian_get_u16(u16(1080)))!
		addr.write([u8(127), 0, 0, 1])!
	}
	assert addr.str() == '127.0.0.1:1080'
}

fn test_socket_addr_new_unix_too_long() {
	long_path := '/tmp/' + 'x'.repeat(netio.max_unix_path_len + 1)
	netio.SocketAddr.new_unix(long_path) or {
		assert err.msg().contains('too long unix socket path')
		return
	}
	assert false, 'expected error for too long unix socket path'
}
