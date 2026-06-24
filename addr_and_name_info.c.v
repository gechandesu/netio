module netio

$if windows {
	#include <ws2tcpip.h>
} $else {
	#include <netdb.h>
}

fn C.getaddrinfo(&char, &char, &C.addrinfo, &&C.addrinfo) i32
fn C.freeaddrinfo(&C.addrinfo)
fn C.getnameinfo(voidptr, u32, &char, u32, &char, u32, i32) i32

$if !windows {
	fn C.gai_strerror(i32) &char
}

fn addr_info_error(code int) IError {
	$if windows {
		return last_error()
	} $else {
		if code == C.EAI_SYSTEM {
			return last_error()
		}
		msg := &char(C.gai_strerror(code))
		return error_with_code(unsafe { cstring_to_vstring(msg) }, code)
	}
}

struct C.addrinfo {
mut:
	ai_flags     i32
	ai_family    i32
	ai_socktype  i32
	ai_protocol  i32
	ai_addrlen   i32
	ai_addr      voidptr
	ai_canonname voidptr
	ai_next      voidptr
}

// AddrInfo represents the [addrinfo](https://man7.org/linux/man-pages/man3/getaddrinfo.3.html) struct.
pub struct AddrInfo {
pub:
	flags     AddrInfoFlag
	family    AddrFamily
	socktype  SocketType
	protocol  Protocol
	addr      SocketAddr
	canonical string
}

@[params]
pub struct AddrInfoParams {
pub:
	node     ?string
	service  ?string
	family   AddrFamily = af_unspec
	socktype SocketType
	protocol Protocol
	flags    AddrInfoFlag
}

// addr_info translates the network addresses and services. This is a low-level wrapper around
// the [getaddrinfo(3)](https://man7.org/linux/man-pages/man3/getaddrinfo.3.html) C API.
pub fn addr_info(hints AddrInfoParams) ![]AddrInfo {
	mut hints_ := C.addrinfo{}
	unsafe { vmemset(&hints_, 0, int(sizeof(hints_))) }
	hints_.ai_family = i32(hints.family)
	hints_.ai_socktype = i32(hints.socktype)
	hints_.ai_protocol = i32(hints.protocol)
	hints_.ai_flags = i32(hints.flags)
	mut node := unsafe { nil }
	if hints.node != none {
		node = &char(hints.node.str)
	}
	mut service := unsafe { nil }
	if hints.service != none {
		service = &char(hints.service.str)
	}
	mut results := &C.addrinfo(unsafe { nil })
	code := C.getaddrinfo(node, service, &hints_, &results)
	if code != 0 {
		return addr_info_error(code)
	}
	defer {
		C.freeaddrinfo(results)
	}
	mut addrs := []AddrInfo{}
	for result := unsafe { results }; !isnil(result); result = result.ai_next {
		addrs << AddrInfo{
			flags:     int(result.ai_flags)
			family:    int(result.ai_family)
			socktype:  int(result.ai_socktype)
			protocol:  int(result.ai_protocol)
			addr:      unsafe { SocketAddr.from_ptr(result.ai_addr, result.ai_addrlen)! }
			canonical: if isnil(result.ai_canonname) {
				''
			} else {
				unsafe {
					cstring_to_vstring(result.ai_canonname)
				}
			}
		}
	}
	return addrs
}

@[params]
pub struct NameInfoParams {
pub:
	flags NameInfoFlag
}

// name_info does address-to-name translation and returns the host and service names.
// See [getnameinfo(3)](https://man7.org/linux/man-pages/man3/getnameinfo.3.html) for details.
pub fn name_info(sa SocketAddr, params NameInfoParams) !(string, string) {
	mut addr := []u8{len: C.NI_MAXHOST}
	mut serv := []u8{len: C.NI_MAXSERV}
	code := C.getnameinfo(sa.ptr(), sa.size(), addr.data, addr.len, serv.data, serv.len,
		params.flags)
	if code != 0 {
		return addr_info_error(code)
	}
	return unsafe {
		tos_clone(&u8(addr.data))
	}, unsafe {
		tos_clone(&u8(serv.data))
	}
}
