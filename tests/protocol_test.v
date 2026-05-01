import netio.protocol

fn test_protocols() {
	assert protocol.protocols().len > 0
}

fn test_protocol_by_name() {
	assert 'TCP' in protocol.protocol_by_name('tcp')!.aliases
}

fn test_protocol_by_number() {
	tcp_proto := protocol.protocol_by_name('tcp')!
	assert protocol.protocol_by_number(tcp_proto.number)!.name == 'tcp'
}
