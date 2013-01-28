#threeMF
threeMF (3MF) stands for *Mobile MultiModal (Interaction) Framework* and it is a **generic** and **extendable** framework for easy **ad-hoc device discovery** and **RPC based communication**.

This framework allows easy ad-hoc communication between devices without the pain of handling **service discovery and management**, network **socket handling**, **disconnection handling** and **data serialization**. Data exchange between multiple devices is abstracted with simple patterns and reduced code complexity. The framework is very generic and extendable to fit a wide range of use cases.

## How does it work
3MF creates a P2P network to share ad-hoc network services between devices. Remote instances of 3MF get discovered, managed during visibility and removed on disappearance automatically. Each peer can publish [remote procedures](http://en.wikipedia.org/wiki/Remote_procedure_call) (they are called commands in the context of 3MF) and execute them at each other. These commands are a semantic description defining **which data** gets shared on **which network channel** (TCP, UDP, ...) following **which pattern** ([Response Request](https://github.com/mgratzer/threeMF/wiki/ResponseRequest) or [Publish Subscribe](https://github.com/mgratzer/threeMF/wiki/PublishSubscribe)).

**Response Request** (RR) commands define remote procedures delivering a **response** for a list of defined parameters on **request**. An example would be a computer asking a mobile phone for its current GPS location.

**Publish Subscribe** (PS) commands on the other hand get triggered by the **publisher** whenever a defined event occurs. Other peers can **subscribe** to PS commands and get payload **pushed**. An example would be a mobile phone with motion sensors providing a command for real time accelerometer data sharing.

3MF comes with [build-in commands](https://github.com/mgratzer/threeMF/wiki/BuildInCommands) --- but it's real power lies in it's extendability. You are able to customize nearby every part, starting at [custom commands](https://github.com/mgratzer/threeMF/wiki/CustomCommands) over to [network channels](https://github.com/mgratzer/threeMF/wiki/CustomNewtorkChannels) and [communication protocols](https://github.com/mgratzer/threeMF/wiki/CustomProtocols).

The framework communicates **ad-hoc**, which means it is sending network messages directly between peers using their local network without a central instance.

### Platform
3MF is currently implemented in [Cocoa](https://developer.apple.com/cocoa/) running on iOS and OSX. The bigger vision is to have a system also spread across other relevant platforms like Android, Windows Phone, ... you name it. Feel free to contact [me](http://twitter.com/mgratzer), if you'r interested in porting 3MF --- I'm glad to provide help if needed.

### Requirements
The current implementation is using **ARC** with minimum deployment targets of **Mac OSX 10.7** and **iOS 5.0**.

## Publish Subscribe Example
The following code snippets show how to **publish** a command and **discover** peers providing it, to **subscribe** and finally how payload is **pushed**. 

### Scenario
Peer A provide a command pushing arbitrary key value pairs to subscribers. Peer B searches for peers serving the command and subscribes. Peer A will than start pushing payload causing Peer B's receive block to execute until the session ends.

1. Publish the `TMFKeyValueCommand`. (Peer A)
2. Discover peers providing the command. (Peer B)
3. Subscribe to the command at discovered peers. (Peer B)
4. Push key value pairs to all subscribers. (Peer A)

### Step 0: Setup (Peer A and Peer B)
	#import "threeMF.h"
	self.tmf = [TMFConnector new];

### Step 1: Provide (Peer A)
	self.kvCmd = [TMFKeyValueCommand new];
	[self.tmf publishCommand:self.kvCmd];

### Step 2: Discover (Peer B)
	[self.tmf startDiscoveryWithCapabilities:@[ [TMFKeyValueCommand name] ] delegate:self];

### Step 3: Subscribe (Peer B)
	- (void)threeMF:(TMFConnector *)tmf didChangeDiscoveringPeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)type {
			if(type == TMFPeerChangeFound) {
				[self.tmf subscribe:[TMFKeyValueCommand name] peer:peer receive:^(TMFKeyValueCommandArguments *arguments){ 
				// do awesome things
				NSLog(@"%@: %@", arguments.key, arguments.value);
			} 
			completion:^(NSError *error){
                 if(error) { // handle error
                     NSLog(@"%@", error);
                 }
             }];
		}
	}

### Step 4: Execute (Peer A)
	TMFKeyValueCommandArguments *kvArguments = [TMFKeyValueCommandArguments new];
    kvArguments.key = @"msg";
    kvArguments.value = @"Hello World!";
    [self.kvCmd sendWithArguments:kvArguments];

## Adding 3MF to your Xcode project

1. Add the framework as a [git submodule](http://schacon.github.com/git/user-manual.html#submodules). Go to the root folder of your project and execute the following commands.

	$ git submodule add https://github.com/mgratzer/threeMF.git Vendor/threeMF
	$ git submodule update --init --recursive 

2. Add (simply drag & drop) `Vendor/threeMF/threeMF` to your Xcode project.

3. Make sure the following frameworks are linked to your project's target: `CFNetworking.framework`, `Security.framework`, `SystemConfiguration.framework`. 

4. You need to add `CoreMotion.framework` and `CoreLocation.framework` to your -Prefix.pch file, if you want to use `TMFLocationCommand` and `TMFMotionCommand`.

Visit [http://threemf.com/documentation/](http://threemf.com/documentation/) for code documentation.

## Author
Martin Gratzer [@mgratzer](http://twitter.com/mgratzer)

The Framework was developed as part of my master thesis at the [Interactive Systems research group](http://www.uni-klu.ac.at/tewi/inf/isys/ias/index.html) of the [University of Klagenfurt](http://www.uni-klu.ac.at).

## Thanks
3MF uses the great [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) library for it's build-in [TCP](http://threemf.com/documentation/Classes/TMFTcpChannel.html) and [UDP](http://threemf.com/documentation/Classes/TMFUdpChannel.html) network channels and the Base64 encoding part from [ytoolkit](https://github.com/sprhawk/ytoolkit) to encode binary data. JSON-RPC is the default communication protocol, but there is also a [coding class](http://threemf.com/documentation/Classes/TMFMsgPackRpcCoder.html) using the [MsgPack-ObjectiveC](https://github.com/msgpack/msgpack-objectivec) for [MsgPack-RPC](https://github.com/mgratzer/threeMF/wiki/MsgPack-RPC).

## License
threeMF is available under the MIT license. See the LICENSE.txt file for more info.