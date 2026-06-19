@[has_globals]
module protocol

import os
import sync

$if windows {
	#flag -lws2_32
	#include <winsock2.h>
	// #include <ws2tcpip.h>

	struct C.WSAData {}

	fn C.WSAStartup(u16, &C.WSAData) i32
	fn C.WSACleanup() i32

	const wsa_version = u32(0x0202)
} $else {
	#include <netdb.h>
}

// Mutex for accessing to protocol entries via getprotoent(3).
__global netio_proto_mutex &sync.Mutex

fn init() {
	$if windows {
		mut wsadata := C.WSAData{}
		if C.WSAStartup(wsa_version, &wsadata) != 0 {
			panic('netio.protocol: WSAStartup failed')
		}
	}
	netio_proto_mutex = sync.new_mutex()
}

fn cleanup() {
	$if windows {
		_ := C.WSACleanup()
	}
	netio_proto_mutex.destroy()
	unsafe { free(netio_proto_mutex) }
}

struct C.protoent {
	p_name    &char
	p_aliases &&char
	p_proto   i32
}

fn C.getprotobyname(&char) &C.protoent
fn C.getprotobynumber(i32) &C.protoent

$if !windows {
	fn C.getprotoent() &C.protoent
	fn C.setprotoent(i32)
	fn C.endprotoent()
}

$if windows {
	fn C.WSAGetLastError() i32
}

pub struct ProtocolEntry {
pub:
	name    string   // The official name of protocol.
	aliases []string // List of alternative names for the protocol.
	number  int      // The protocol number.
}

fn make_proto(ent &C.protoent) ProtocolEntry {
	mut aliases := []string{}
	if unsafe { ent.p_aliases[0] != nil } {
		mut ptr := *ent.p_aliases
		mut nullterm := 1
		for {
			if *ptr == 0 {
				break
			}
			str := unsafe { cstring_to_vstring(ptr) }
			ptr = unsafe { ptr + str.len + nullterm }
			nullterm++
			aliases << str
		}
	}
	return ProtocolEntry{
		name:    unsafe { cstring_to_vstring(ent.p_name) }
		aliases: aliases
		number:  int(ent.p_proto)
	}
}

// protocols returns all protocol entries from database in arbitrary order.
pub fn protocols() []ProtocolEntry {
	netio_proto_mutex.@lock()
	defer {
		netio_proto_mutex.unlock()
	}
	$if windows {
		mut protos := []ProtocolEntry{}
		mut seen := map[string]bool{}
		for num in 0 .. 256 {
			proto := C.getprotobynumber(i32(num))
			if isnil(proto) {
				continue
			}
			entry := make_proto(proto)
			if entry.name !in seen {
				seen[entry.name] = true
				protos << entry
			}
		}
		return protos
	} $else {
		C.setprotoent(1)
		defer {
			C.endprotoent()
		}
		mut protos := []ProtocolEntry{}
		for {
			proto := C.getprotoent()
			if isnil(proto) {
				break
			}
			protos << make_proto(proto)
		}
		return protos
	}
}

// protocol_by_name returns the protocol entry by name e.g. 'tcp', 'icmp'.
pub fn protocol_by_name(name string) !ProtocolEntry {
	netio_proto_mutex.@lock()
	defer {
		netio_proto_mutex.unlock()
	}
	proto := C.getprotobyname(&char(name.str))
	if isnil(proto) {
		$if windows {
			code := int(C.WSAGetLastError())
			return error_with_code(os.get_error_msg(code), code)
		} $else {
			return os.last_error()
		}
	}
	return make_proto(proto)
}

// protocol_by_number returns the protocol entry by protocol number.
pub fn protocol_by_number(num int) !ProtocolEntry {
	netio_proto_mutex.@lock()
	defer {
		netio_proto_mutex.unlock()
	}
	proto := C.getprotobynumber(num)
	if isnil(proto) {
		$if windows {
			code := int(C.WSAGetLastError())
			return error_with_code(os.get_error_msg(code), code)
		} $else {
			return os.last_error()
		}
	}
	return make_proto(proto)
}
