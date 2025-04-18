#ifndef MESH_PEER_H
#define MESH_PEER_H

#include <godot_cpp/classes/node.hpp>

namespace godot {

	class MeshPeer : public Node {
		GDCLASS(MeshPeer, Node)
			/*
			MESH:
				HAS: peers/hosts
				DOES: cp2pm(), broadcast, join, peer list, add peer, new peer, bye, del peer, end

			DO WE NEED poll_peer_slots() ANYMORE?

			PROTOCOL: client is peer, server is lobby host peer
				FIND GAME: LAN broadcast received or check signal server
				HANDSHAKE (NEW CONNECTION):
					1. client sends JOIN to server
					- if lobby is full:
						2. server responds to client NO
						3. HANDSHAKE FAIL, CLIENT DOES NOT CONNECT
					- if lobby is not full:
						2. server responds with peer list (including host)
						3. IN UNSPECIFIED ORDER:
							- server adds client to its mesh
							- server tells existing peers to add client to their meshes
							- client creates its P2P mesh and connects to game
				DISCONNECT:
					1. client sends BYE to peers
					2. IN UNSPECIFIED ORDER:
						- client saves player/character state, closes connections and exits (back to main menu or full exit)
						- peers remove client from their meshes
				END GAME:
					1. server sends END to peers
					2. IN UNSPECIFIED ORDER:
						- server saves game and player/character states, closes connections, and exits (back to main menu or full exit)
						- peers save player/character states, close connections, and exit (back to main menu)
			*/
	};
}

#endif

