/*
Copyright (c) 2022 Andres Hernandez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
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
	godot::ClassDB::bind_method(godot::D_METHOD("connect"), &SpacemouseDevice::spacemouse_connect);
	godot::ClassDB::bind_method(godot::D_METHOD("disconnect"), &SpacemouseDevice::spacemouse_disconnect);
	godot::ClassDB::bind_method(godot::D_METHOD("translation"), &SpacemouseDevice::spacemouse_translation);
	godot::ClassDB::bind_method(godot::D_METHOD("rotation"), &SpacemouseDevice::spacemouse_rotation);
	godot::ClassDB::bind_method(godot::D_METHOD("get_modified"), &SpacemouseDevice::get_modified);
}

SpacemouseDevice::SpacemouseDevice() {
	// motionData = SpaceMotion();
	// motionData.translation = godot::Vector3(0, 0, 0);
	// motionData.rotation = godot::Vector3(0, 0, 0);
}

SpacemouseDevice::~SpacemouseDevice() {
	spacemouse_disconnect();
}

int getButton(int buttonMask) {
	int button = 0;
	for (int i = 0; i < 32; i++) {
		if (buttonMask & (1 << i))
			button += i;
	}
	return button + 1;
}

void SpacemouseDevice::messageHandler(unsigned int productID, unsigned int messageType, void *messageArgument) {
	ConnexionDeviceState *state;
	int32_t vidPid;
	ConnexionDevicePrefs prefs;
	int16_t error;
	switch (messageType) {
		case kConnexionMsgDeviceState:
			state = (ConnexionDeviceState*) messageArgument;
			if (state->client == connexionClientID) {
				switch (state->command) {
					case kConnexionCmdHandleAxis: {
						// already convert the mouse coordinates to godot coordinates
						translation = godot::Vector3(state->axis[0], - static_cast<float>(state->axis[2]), state->axis[1]);
						rotation = godot::Vector3(state->axis[3], - static_cast<float>(state->axis[5]), state->axis[4]);
						modified = true;
						print_line("Spacemouse handle axis ", translation, rotation);
					} break;
					case kConnexionCmdHandleButtons:
					case kConnexionCmdAppSpecific:
					case kConnexionCmdHandleRawData: {
						(void)ConnexionControl(kConnexionCtlGetDeviceID, 0, &vidPid);
						error = ConnexionGetCurrentDevicePrefs(kDevID_AnyDevice, &prefs);

						//              TDxEventData *data = new TDxEventData(NULL);

						//              if (state->buttons != 0)
						//                data->button = getButton(state->buttons);
						//              else
						//                data->button = 0;
						//
						//              gConnexionTest->updateData(data);
						//              delete data;
					} break;
					default:
						break;
				}
			}
			break;
		case kConnexionMsgPrefsChanged:
			break;
		default:
			// other messageTypes can happen and should be ignored
			break;
	}
}

void SpacemouseDevice::mouseAdded(unsigned int productID) {
	print_line("mouse added: ", productID);
}

void SpacemouseDevice::mouseRemoved(unsigned int productID) {
	print_line("mouse removed: ", productID);
}

bool SpacemouseDevice::spacemouse_disconnect() {
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

bool SpacemouseDevice::spacemouse_connect() {
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
	int16_t error;
	// Install message handler and register our client
	error = SetConnexionHandlers(on_message, on_mouse_added, on_mouse_removed, false);
	if (error) {
		print_line("failed to set connection handler.");
		return false;
	}
	// This takes over system-wide
	connexionClientID = RegisterConnexionClient(kConnexionClientWildcard,
			NULL,
			kConnexionClientModeTakeOver,
			kConnexionMaskAll);

	print_line("registered cx client: ", connexionClientID);
	if (connexionClientID) {
		connected_device = this;
		SetConnexionClientButtonMask(connexionClientID, kConnexionMaskAllButtons);
	}
	return true;
}

godot::Vector3 SpacemouseDevice::spacemouse_translation() {
	modified = false;
	return translation;
}

godot::Vector3 SpacemouseDevice::spacemouse_rotation() {
	modified = false;
	return rotation;
}

bool SpacemouseDevice::get_modified() {
	return modified;
}