#ifndef MESH_PEER_H
#define MESH_PEER_H

#include <godot_cpp/classes/e_net_connection.hpp>
#include <godot_cpp/classes/e_net_multiplayer_peer.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MeshPeer : public Node {
	GDCLASS(MeshPeer, Node)

private:
	static int const HOST_PEER_ID = 2;

	bool is_host;
	HashMap<int, Ref<ENetConnection>> pending_peers;
	int peer_id;
	Ref<ENetMultiplayerPeer> local_peer;

	void add_peer(int p_peer_id, const String &p_address); // RPC: authority (?; only host can call), call_local, reliable, CHANNEL
	/*
	void connect_pending_peers(); // TODO: poll_peer_slots()
	*/
	void end_mesh(); // RPC: authority (?; only host can call), call_remote, reliable, CHANNEL
	void disconnect_peer(); // RPC: any_peer, call_remote, reliable, CHANNEL
	void set_up_local_peer();
	void set_up_rpcs();

protected:
	static void _bind_methods();

public:
	static uint16_t const BASE_PORT = 25250;

	MeshPeer() :
			is_host(true), pending_peers(), peer_id(MeshPeer::HOST_PEER_ID), local_peer(memnew(ENetMultiplayerPeer)){};

	void _process(double p_delta) override;
	void _ready() override;

	void set_as_peer(const HashMap<int, String> &p_peers);
	/*
	POSSIBLE PROBLEM WHEREIN A NEW PEER ONLY ESTABLISHES SUCCESSFUL CONNECTIONS WITH PART OF THE NETWORK; HOW TO HANDLE?? (RETRY HOW MANY TIMES BEFORE DISCONNECT FROM LOBBY?)

	PUT BROADCAST AND PEER LIST INTO ITS OWN CLASS (ABSTRACT? SUBCLASSES FOR ONLINE VS. LAN?)
	PUT JOIN INTO ITS OWN CLASS

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
} //namespace godot

#endif
