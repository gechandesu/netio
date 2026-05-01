import netio

fn test_network_interfaces() {
	ifs := netio.network_interfaces()!
	// dump(ifs)
	assert ifs.len > 0
}

fn test_name_to_index() {
	ifs := netio.network_interfaces()!
	iface := ifs[0]
	dump(iface)
	assert netio.name_to_index(iface.name)! == iface.index
}

fn test_index_to_name() {
	ifs := netio.network_interfaces()!
	iface := ifs[0]
	dump(iface)
	assert netio.index_to_name(iface.index)! == iface.name
}

fn test_find_network_interface() {
	ifs := netio.network_interfaces()!
	iface := ifs[0]
	dump(iface)
	assert netio.find_network_interface(iface.name)!.name == iface.name
	assert netio.find_network_interface(iface.index.str())!.index == iface.index
}
