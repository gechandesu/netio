import os
import netio

fn main() {
	mut socket := netio.Socket.new(netio.af_inet, netio.sock_stream, 0)!
	socket.set_option(netio.sol_socket, netio.so_reuseaddr, 1)!
	listen_addr := netio.SocketAddr.new_ipv4([4]u8{}, 1088)
	socket.bind(listen_addr)!
	socket.listen(3)!

	println('Server listening on ${listen_addr}...')

	mut buf := []u8{len: 1024}

	conn, remote_addr := socket.accept()!

	println('Connection accepted from ${remote_addr}')
	println("Type 'quit' or 'exit' to end the chat.")

	for {
		buf = []u8{len: 1024}
		bytesread := conn.recv(mut buf, 0)!
		incmsg := unsafe { buf#[..bytesread] }
		match true {
			bytesread > 0 {
				println('Client: ${incmsg.bytestr()}')
				if incmsg.bytestr() in ['quit', 'exit'] {
					println('Client requested to end chat. Closing connection.')
					break
				}
			}
			bytesread == 0 {
				println('Client disconnected.')
				break
			}
			else {
				break
			}
		}

		msg := os.input('Server: ')
		if msg in ['quit', 'exit'] {
			println('Server requested to end chat. Closing connection.')
			conn.send(msg.bytes(), 0)!
			break
		}
		conn.send(msg.bytes(), 0)!
	}
	conn.close()!
	println('Client socket closed.')
	socket.close()!
	println('Server listening socket closed.')
}
