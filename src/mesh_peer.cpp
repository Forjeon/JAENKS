#include "mesh_peer.h"

#include <godot_cpp/classes/e_net_connection.hpp>
#include <godot_cpp/classes/e_net_multiplayer_peer.hpp>
#include <godot_cpp/classes/e_net_packet_peer.hpp>
#include <godot_cpp/classes/multiplayer_api.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/templates/hash_map.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

/*
void MeshPeer::add_peer(int p_id, const String &p_address) {
// TODO
}

void MeshPeer::connect_pending_peers() {
for (HashMap<int, Ref<ENetConnection>>::ConstIterator it = this->pending_peers.begin(); it; ++it) {
	// TODO
}
}

void MeshPeer::end_mesh() {
// TODO
}

void MeshPeer::disconnect_peer() {
// TODO
}

void MeshPeer::set_up_local_peer() {
this->local_peer->create_mesh(this->id);
this->get_multiplayer()->set_multiplayer_peer(this->local_peer);
}

void MeshPeer::set_up_rpcs() {
// TODO
}
*/

void MeshPeer::_bind_methods() {
	BIND_CONSTANT(MeshPeer::BASE_PORT);
}

void MeshPeer::_process(double p_delta) {
	//this->connect_pending_peers();
}

void MeshPeer::_ready() {
	//this->set_up_local_peer();
}

void MeshPeer::set_as_peer(const HashMap<int, String> &p_peers) {
	this->is_host = false;
	this->id = p_peers.size() + MeshPeer::HOST_PEER_ID;

	// Create the pending mesh peers (will be finalized in connect_peers())
	for (HashMap<int, String>::ConstIterator it = p_peers.begin(); it; ++it) {
		Ref<ENetConnection> peer_connection = memnew(ENetConnection);
		peer_connection->create_host();
		peer_connection->connect_to_host((*it).value, MeshPeer::BASE_PORT + this->id);
		this->pending_peers.insert((*it).key, peer_connection);
	}
}
