#include "mesh_peer.h"

#include <godot_cpp/classes/e_net_multiplayer_peer.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void MeshPeer::_bind_methods() {
	//ClassDB::bind_method(D_METHOD("get_base_port"), &MeshPeer::get_base_port);
}

MeshPeer::MeshPeer() {
	this->enet_peer = Ref<ENetMultiplayerPeer>(memnew(ENetMultiplayerPeer));
}

MeshPeer::~MeshPeer() {
}

/*
static uint16_t MeshPeer::get_base_port() {
	return MeshPeer::BASE_PORT;
}
*/
