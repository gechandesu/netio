module netio

import encoding.binary

struct C.sockaddr_storage {}

// SocketAddrStorage represents the sockaddr_storage struct which can be used to store any socket address.
// See [sockaddr(3type)](https://www.man7.org/linux/man-pages/man3/sockaddr.3type.html) for details.
pub type SocketAddrStorage = C.sockaddr_storage

pub const max_unix_path_len = $if linux {
	108
} $else $if windows {
	108
} $else {
	104
}

pub struct SocketAddr {
mut:
	data &u8 = unsafe { nil }
	len  int
	pos  int
}

// SocketAddr.new_ipv4 creates new AF_INET socket address.
// addr must be set in network (big-endian) byte order.
pub fn SocketAddr.new_ipv4(addr [4]u8, port u16) SocketAddr {
	mut sock_addr := unsafe { SocketAddr.new(af_inet, 16) }
	unsafe {
		sock_addr.write(binary.big_endian_get_u16(port)) or {}
		sock_addr.write(addr[..]) or {}
	}
	return sock_addr
}

@[params]
pub struct Inet6SocketAddrParams {
pub:
	flow_info u32
	scope_id  u32
}

// SocketAddr.new_ipv6 creates new AF_INET6 socket address.
// addr must be set in network (big-endian) byte order.
// Use `find_network_interface()` to get an integer scope_id from its string representation.
pub fn SocketAddr.new_ipv6(addr [16]u8, port u16, params Inet6SocketAddrParams) SocketAddr {
	mut sock_addr := unsafe { SocketAddr.new(af_inet6, 28) }
	unsafe {
		sock_addr.write(binary.big_endian_get_u16(port)) or {}
		sock_addr.write(binary.big_endian_get_u32(params.flow_info)) or {}
		sock_addr.write(addr[..]) or {}
		sock_addr.write(binary.big_endian_get_u32(params.scope_id)) or {}
	}
	return sock_addr
}

// SocketAddr.new_unix creates new AF_UNIX socket address with given path. The path must
// fit in platform dependent `max_unix_path_len` const value.
pub fn SocketAddr.new_unix(path string) !SocketAddr {
	if path.len > max_unix_path_len {
		return error('too long path to socket, max length is ${max_unix_path_len}')
	}
	mut sock_addr := unsafe { SocketAddr.new(af_unix, usize(max_unix_path_len) + 2) }
	unsafe {
		sock_addr.write(path.bytes()) or {}
	}
	return sock_addr
}

// SocketAddr.new creates new instance of SocketAddr with specified address family and size.
//
// This function allocates memory (zero filled) for the address, but does not initialize
// the address itself, you need to do that manually. The benefit is that you can create the
// any kind of socket address.
//
// SocketAddr is a builder for
// [sockaddr(3type)](https://www.man7.org/linux/man-pages/man3/sockaddr.3type.html) objects.
// Use this function only if you understand what you do. Using the `write()` method you must
// write the data for the desired socket address, ensuring the correct sizes of all types,
// the order of the fields in the struct, the byte order, and the total size of the struct.
// The sizes and byte order may vary by platform, so you'll need to keep an eye on that as
// well. A mistake while creating an address will crash your application. So this function
// is marked as `unsafe`.
//
// The example below creates a sockaddr_in struct describing the loopback IPv4-address
// 127.0.0.1 with port number 1080. Note the comment in the example. This is a fragment
// of [sockaddr_in(3type)](https://www.man7.org/linux/man-pages/man3/sockaddr.3type.html)
// manual page, which shows the target C struct. Summing the field sizes yields 8
// bytes, but we need to allocate 16 bytes according to the <netinet/in.h>.
// Data must be padded to sockaddr struct size which is 16 bytes. Each field is then
// written in turn, from top to bottom. Keep in mind that two-byte address family field
// (sin_family in this case) is already written. According to the manual page, the
// address and port are written using the network (big-endian) byte order.
//
// On *BSD, the first byte of the socket address stores the address size, and the second
// byte stores the address family.
//
// Example:
// ```v
// import encoding.binary
// import netio
//
// // struct sockaddr_in {
// //     sa_family_t     sin_family;     /* AF_INET */
// //     in_port_t       sin_port;       /* Port number */
// //     struct in_addr  sin_addr;       /* IPv4 address */
// // };
// //
// // struct in_addr {
// //     in_addr_t s_addr;
// // };
// //
// // typedef uint32_t in_addr_t;
// // typedef uint16_t in_port_t;
//
// mut sa := unsafe { netio.SocketAddr.new(netio.af_inet, 16) }
// unsafe {
// 	sa.write(binary.big_endian_get_u16(u16(1080)))!
// 	sa.write([u8(127), 0, 0, 1])!
// }
// println(sa)
// ```
@[unsafe]
pub fn SocketAddr.new(af AddrFamily, size isize) SocketAddr {
	ptr := unsafe { vcalloc(usize(size)) }
	mut sock_addr := SocketAddr{
		data: ptr
		len:  int(size)
	}
	unsafe {
		$if bsd {
			// On *BSD sockaddr's first byte is address len, second byte is address family.
			// See <sys/socket.h>.
			sock_addr.write([u8(size), u8(af)]) or {}
		} $else {
			$if little_endian {
				sock_addr.write(binary.little_endian_get_u16(u16(af))) or {}
			} $else {
				sock_addr.write(binary.big_endian_get_u16(u16(af))) or {}
			}
		}
	}
	return sock_addr
}

// SocketAddr.from_ptr_copy creates new socket address by copying data from specified pointer.
@[unsafe]
pub fn SocketAddr.from_ptr_copy(ptr voidptr, size isize) !SocketAddr {
	if isnil(ptr) {
		return error('${@METHOD}: cannot accept nil ptr')
	}
	data := unsafe { vcalloc(usize(size)) }
	unsafe {
		vmemcpy(data, ptr, size)
	}
	return SocketAddr{
		data: data
		len:  int(size)
	}
}

// SocketAddr.from_ptr creates new socket address from specified pointer.
// Note: Data is reused, not copied.
@[unsafe]
pub fn SocketAddr.from_ptr(ptr voidptr, size isize) !SocketAddr {
	if isnil(ptr) {
		return error('${@METHOD}: cannot accept nil ptr')
	}
	return SocketAddr{
		data: ptr
		len:  int(size)
	}
}

// family returns the socket address family.
// Note: It returns 0 if socket address is nil, see also `is_empty()`.
pub fn (a SocketAddr) family() AddrFamily {
	if isnil(a.data) {
		return 0
	}
	mut f := 0
	unsafe {
		$if bsd {
			vmemcpy(&f, a.data + 1, isize(1))
		} $else {
			vmemcpy(&f, a.data, isize(2))
		}
	}
	return f
}

// is_empty returns true if socket address is unspecified: the data pointer is nil or socket
// address data is zero. Empty address cannot be used in `bind()` and `connect()` calls.
pub fn (a SocketAddr) is_empty() bool {
	if isnil(a.data) {
		return true
	}
	start_point := $if bsd { 1 } $else { 0 } // skip first byte on *BSD
	for i := start_point; i < a.len; i++ {
		if unsafe { a.data[i] } != 0 {
			return false
		}
	}
	return true
}

// write writes `buf.len` bytes of data to the socket address memory area
// and returns the number of bytes written.
// write will return an error if the socket address pointer is nil or
// the buffer length, including the length of the data already written,
// exceeds the size of the socket address.
@[unsafe]
pub fn (mut a SocketAddr) write(buf []u8) !int {
	if isnil(a.data) {
		return error('${@METHOD}: SocketAddr is nil')
	}
	if a.pos + buf.len > a.len {
		return error('${@METHOD}: data overflow')
	}
	mut i := 0
	for a.pos + 1 < a.len {
		unsafe {
			a.data[a.pos + i] = buf[i]
		}
		i++
		if i >= buf.len {
			break
		}
	}
	a.pos += i
	return i
}

// ptr returns the pointer to sockaddr data.
pub fn (a SocketAddr) ptr() voidptr {
	return a.data
}

// size reports the size of sockaddr data.
pub fn (a SocketAddr) size() u32 {
	return u32(a.len)
}

// str returns the string representation of socket address.
// Only AF_UNIX, AF_INET, and AF_INET6 are supported. str will return a string
// consisting of the address and port number separated by a colon, or the absolute
// path to the socket file. The IPv6 address will be returned in expanded form and
// enclosed in square brackets. For all other address families, str will return a
// string of the form `SocketAddr(0x00000000)` with the socket address data pointer
// in brackets.
// Note: See also `name_info()`.
pub fn (a SocketAddr) str() string {
	match a.family() {
		af_inet {
			mut addr := [4]u8{}
			mut port := [2]u8{}
			unsafe {
				vmemcpy(port, &u8(a.ptr()) + 2, 2)
				vmemcpy(addr, &u8(a.ptr()) + 4, 4)
			}
			port_int := binary.big_endian_u16_fixed(port)
			// vfmt off
			return addr[0].str() + '.'
				+ addr[1].str() + '.'
				+ addr[2].str() + '.'
				+ addr[3].str() + ':' + port_int.str()
			// vfmt on
		}
		af_inet6 {
			mut addr := [16]u8{}
			mut port := [2]u8{}
			mut res := ''
			unsafe {
				vmemcpy(port, &u8(a.ptr()) + 2, 2)
				vmemcpy(addr, &u8(a.ptr()) + 8, 16)
			}
			for i := 0; i < 16; i += 2 {
				res += addr[i..i + 2].hex()
				if i < 14 {
					res += ':'
				}
			}
			port_int := binary.big_endian_u16_fixed(port)
			return '[' + res + ']:' + port_int.str()
		}
		af_unix {
			mut path := [max_unix_path_len]u8{}
			mut res := ''
			unsafe {
				vmemcpy(path, &u8(a.ptr()) + 2, max_unix_path_len)
				res = tos_clone(&u8(path[..].data))
			}
			return res
		}
		else {
			return 'SocketAddr(0x${a.data:08x})'
		}
	}
}
