import os
import netio

fn main() {
	mut step := 0

	mut socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
	server_addr := netio.SocketAddr.new_ipv4([u8(127), 0, 0, 1]!, 1088)
	socket.connect(server_addr)!

	println('Connected to server ${server_addr}')
	println("Type 'quit' or 'exit' to end the chat.")

	mut buf := []u8{len: 1024}

	for {
		msg := $if netio_test ? {
			defer { step++ }
			if step == 0 { 'ping' } else { 'quit' }
		} $else {
			os.input('Client: ')
		}
		if msg in ['quit', 'exit'] {
			println('Client requested to end chat. Closing connection.')
			socket.send(msg.bytes(), 0)!
			break
		}
		socket.send(msg.bytes(), 0)!

		bytesread := socket.recv(mut buf, 0)!
		incmsg := unsafe { buf#[..bytesread] }
		match true {
			bytesread > 0 {
				println('Server: ${incmsg.bytestr()}')
				if incmsg.bytestr() in ['quit', 'exit'] {
					println('Server requested to end chat. Closing connection.')
					break
				}
			}
			bytesread == 0 {
				println('Server disconnected.')
				break
			}
			else {
				break
			}
		}
	}
	socket.close()!
	println('Client socket closed.')
}
