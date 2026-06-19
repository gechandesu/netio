module netio

$if windows {
	#flag -liphlpapi
	#include <netioapi.h>
} $else {
	#include <net/if.h>
}

fn C.if_nametoindex(&char) u32
fn C.if_indextoname(u32, &char) &char

$if !windows {
	struct C.if_nameindex {
		if_index u32
		if_name  &char
	}

	fn C.if_nameindex() &C.if_nameindex
	fn C.if_freenameindex(voidptr)
}

pub struct NetworkInterfaceNotFound {
	Error
pub:
	index u32
	name  string
}

// msg returns the error message.
pub fn (e NetworkInterfaceNotFound) msg() string {
	if e.index != 0 {
		return 'network interface with index ${e.index} not found'
	} else {
		return 'network interface named `${e.name}` not found'
	}
}

// name_to_index translates the network interface name to index.
// See also [if_nametoindex(3p)](https://man7.org/linux/man-pages/man3/if_nametoindex.3p.html).
pub fn name_to_index(name string) !u32 {
	index := C.if_nametoindex(&char(name.str))
	if index == 0 {
		$if windows {
			return NetworkInterfaceNotFound{
				name: name
			}
		} $else {
			err := last_error()
			if err.code() == 19 { // ENODEV
				return NetworkInterfaceNotFound{
					name: name
				}
			} else {
				return err
			}
		}
	}
	return index
}

// index_to_name translates the network interface index to name e.g. 'eth0'.
// See also [if_indextoname(3p)](https://man7.org/linux/man-pages/man3/if_indextoname.3p.html).
pub fn index_to_name(index u32) !string {
	name := []u8{len: C.IF_NAMESIZE}
	ifname := C.if_indextoname(index, name.data)
	if isnil(ifname) {
		$if windows {
			return NetworkInterfaceNotFound{
				index: index
			}
		} $else {
			err := last_error()
			if err.code() == 6 { // ENXIO
				return NetworkInterfaceNotFound{
					index: index
				}
			} else {
				return err
			}
		}
	}
	return unsafe { cstring_to_vstring(ifname) }
}

pub struct NetworkInterfaceId {
pub:
	index u32
	name  string
}

// find_network_interface returns the network interface index and name by provided string s.
// If network interface is not present the NetworkInterfaceNotFound error will be returned.
// See also `index_to_name()` and `name_to_index()`.
// Example: assert netio.find_network_interface('eth0')!.index == 2
// Example: assert netio.find_network_interface('2')!.name == 'eth0'
pub fn find_network_interface(s string) !NetworkInterfaceId {
	mut index := u32(0)
	mut name := ''
	if s.is_int() {
		index = s.u32()
		name = index_to_name(index)!
	} else {
		name = s
		index = name_to_index(name)!
	}
	return NetworkInterfaceId{
		index: index
		name:  name
	}
}

// network_interfaces returns an array with names and indexes of all network interfaces on system.
// See also [if_nameindex(3p)](https://man7.org/linux/man-pages/man3/if_nameindex.3p.html).
pub fn network_interfaces() ![]NetworkInterfaceId {
	$if windows {
		mut result := []NetworkInterfaceId{}
		mut name := []u8{len: C.IF_NAMESIZE}
		for index in u32(1) .. u32(256) {
			ifname := C.if_indextoname(index, name.data)
			if !isnil(ifname) {
				result << NetworkInterfaceId{
					index: index
					name:  unsafe { cstring_to_vstring(ifname) }
				}
			}
		}
		if result.len == 0 {
			return last_error()
		}
		return result
	} $else {
		ifaces := C.if_nameindex()
		if isnil(ifaces) {
			return last_error()
		}
		defer {
			C.if_freenameindex(ifaces)
		}
		mut result := []NetworkInterfaceId{}
		mut i := 0
		for {
			iface := unsafe { ifaces[i] }
			i++
			if iface.if_index == 0 && isnil(iface.if_name) {
				break
			}
			result << NetworkInterfaceId{
				index: iface.if_index
				name:  unsafe { cstring_to_vstring(iface.if_name) }
			}
		}
		return result
	}
}
