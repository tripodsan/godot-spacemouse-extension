#include "spacemouse.h"

#if __has_include(<3DConnexionClient/ConnexionClient.h>)
	#include <3DConnexionClient/ConnexionClient.h>
	#include <3DConnexionClient/ConnexionClientAPI.h>
#else
	#include <ConnexionClient.h>
	#include <ConnexionClientAPI.h>
#endif

SpacemouseDevice* SpacemouseDevice::connected_device = nullptr;

void SpacemouseDevice::_bind_methods() {
	print_line("SpaceMouse Extension 3.0");
	godot::ClassDB::bind_method(godot::D_METHOD("connect"), &SpacemouseDevice::connect);
	godot::ClassDB::bind_method(godot::D_METHOD("disconnect"), &SpacemouseDevice::disconnect);
	godot::ClassDB::bind_method(godot::D_METHOD("get_translation"), &SpacemouseDevice::get_translation);
	godot::ClassDB::bind_method(godot::D_METHOD("get_rotation"), &SpacemouseDevice::get_rotation);
	godot::ClassDB::bind_method(godot::D_METHOD("is_modified"), &SpacemouseDevice::is_modified);
	godot::ClassDB::bind_method(godot::D_METHOD("get_buttons"), &SpacemouseDevice::get_buttons);
}

SpacemouseDevice::SpacemouseDevice() {
}

SpacemouseDevice::~SpacemouseDevice() {
	disconnect();
}

void SpacemouseDevice::messageHandler(unsigned int productID, unsigned int messageType, void *messageArgument) {
	if (messageType == kConnexionMsgDeviceState) {
		ConnexionDeviceState *state = (ConnexionDeviceState*) messageArgument;
		if (state->client == connexionClientID) {
			switch (state->command) {
				case kConnexionCmdHandleAxis:
					// convert the mouse coordinates to godot coordinates
					translation = godot::Vector3(state->axis[0], - static_cast<float>(state->axis[2]), state->axis[1]);
					rotation = godot::Vector3(state->axis[3], - static_cast<float>(state->axis[5]), state->axis[4]);
					modified = true;
					if (debug) {
						print_line("Spacemouse handle axis ", translation, rotation);
					}
					break;
				case kConnexionCmdHandleButtons:
					if (debug) {
						print_line("Spacemouse handle button ", state->buttons);
					}
					buttons = state->buttons;
					break;
			}
		}
	} else {
		print_line("message type ", messageType);
	}
}

void SpacemouseDevice::mouseAdded(unsigned int productID) {
	print_line("mouse added: ", productID);
}

void SpacemouseDevice::mouseRemoved(unsigned int productID) {
	print_line("mouse removed: ", productID);
}

bool SpacemouseDevice::disconnect() {
	// Make sure the framework is installed
	if (connexionClientID) {
		UnregisterConnexionClient(connexionClientID);
		connexionClientID = 0;
	}
	connected_device = nullptr;
	CleanupConnexionHandlers();
	print_line("disconnected from connection handler.");
	return true;
}

void on_message(unsigned int productID, unsigned int messageType, void *messageArgument) {
	if (SpacemouseDevice::connected_device) {
		SpacemouseDevice::connected_device->messageHandler(productID, messageType, messageArgument);
	}
}
void on_mouse_added(unsigned int productID) {
	if (SpacemouseDevice::connected_device) {
		SpacemouseDevice::connected_device->mouseAdded(productID);
	}
}

void on_mouse_removed(unsigned int productID) {
	if (SpacemouseDevice::connected_device) {
		SpacemouseDevice::connected_device->mouseRemoved(productID);
	}
}

bool SpacemouseDevice::connect() {
	if (connected_device) {
		print_line("already connected");
		if (connected_device != this) {
			print_error("Spacemouse device instance mismatch");
			connected_device = this;
			return true;
		}
		return false;
	}

	print_line("connecting to connection handler..");
	// Install message handler and register our client
	int16_t error = SetConnexionHandlers(on_message, on_mouse_added, on_mouse_removed, false);
	if (error) {
		print_line("failed to set connection handler: ", error);
		return false;
	}

	connexionClientID = RegisterConnexionClient(0L, nullptr, kConnexionClientModeTakeOver, kConnexionMaskAll);

	print_line("registered cx client: ", connexionClientID);
	if (connexionClientID) {
		connected_device = this;
		SetConnexionClientButtonMask(connexionClientID, kConnexionMaskAllButtons);
	}
	return true;
}

godot::Vector3 SpacemouseDevice::get_translation() {
	modified = false;
	return translation;
}

godot::Vector3 SpacemouseDevice::get_rotation() {
	modified = false;
	return rotation;
}

bool SpacemouseDevice::is_modified() const {
	return modified;
}

int SpacemouseDevice::get_buttons() const {
	return buttons;
}

bool SpacemouseDevice::get_debug() const {
	return debug;
}

void SpacemouseDevice::set_debug(bool value) {
	debug = value;
}