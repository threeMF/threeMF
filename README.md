#threeMF
The Mobile MultiModal (Interaction) Framework (3MF or threeMF) is a **generic** and **extendable** ad-hoc networking framework for **easy device discovery**, **capability checking** and pattern based **RPC communication**.

3MF allows ad-hoc communication between devices, without the pain of handling **service discovery and management**, network **socket** and **disconnection handling** as well as **data serialization**. Data exchange is abstracted with simple patterns which reduce code complexity to a few lines. To fit a wide range of use cases the framework is very generic and extendable.

## How does it work
3MF creates a P2P network to share ad-hoc network services between devices. Discovery of remote 3MF instances, their management during visibility and disappearance is handled automatically. Each peer can publish [remote procedures](http://en.wikipedia.org/wiki/Remote_procedure_call) (they are called commands in the context of 3MF) and execute them at each other. These commands are a semantic description defining **which data** gets shared on **which network channel** (TCP, UDP, ...) following **which pattern** ([Response Request](https://github.com/mgratzer/threeMF/wiki/ResponseRequest) or [Publish Subscribe](https://github.com/mgratzer/threeMF/wiki/PublishSubscribe)).

**Response Request** (RR) commands define remote procedures delivering a **response** for a list of defined parameters on **request**. An example would be a computer asking a mobile phone for it's current GPS location.

![](http://threemf.com/images/request_response.png)

**Publish Subscribe** (PS) commands on the other hand get triggered by the **publisher** whenever a defined event occurs. Other peers can **subscribe** to PS commands and get payload **pushed**. Messages send to subscribers will not create responses, they are just notifications for subscribers. An example would be a mobile phone with motion sensors providing a command for real time accelerometer data sharing.

![](http://threemf.com/images/publish_subscribe.png)

3MF comes with [build-in commands](https://github.com/mgratzer/threeMF/wiki/BuildInCommands) --- but it's real power lies in it's extendability. You are able to customize nearby every part, starting at [custom commands](https://github.com/mgratzer/threeMF/wiki/CustomCommands) over to [network channels](https://github.com/mgratzer/threeMF/wiki/CustomNewtorkChannels) and [communication protocols](https://github.com/mgratzer/threeMF/wiki/CustomProtocols).

The framework communicates **ad-hoc**, which means it is sending network messages directly between peers using their local network without a central instance.

## Examples

### Publish Subscribe Example
The following code snippets show how to **publish** a command and **discover** peers providing it, to **subscribe** and finally how payload is **pushed**. 

#### Scenario
Peer A provide a command pushing arbitrary key value pairs to subscribers. Peer B searches for peers serving the command and subscribes. Peer A will than start pushing payload causing Peer B's receive block to execute until the session ends.

1. Publish the `TMFKeyValueCommand`. (Peer A)
2. Discover peers providing the command. (Peer B)
3. Subscribe to the command at discovered peers. (Peer B)
4. Push key value pairs to all subscribers. (Peer A)

#### Step 0: Setup (Peer A and Peer B)
``` objective-c
	#import "threeMF.h"
	self.tmf = [TMFConnector new];
```

#### Step 1: Provide (Peer A)
``` objective-c
	self.kvCmd = [TMFKeyValueCommand new];
	[self.tmf publishCommand:self.kvCmd];
```

#### Step 2: Discover (Peer B)
``` objective-c
	[self.tmf startDiscoveryWithCapabilities:@[ [TMFKeyValueCommand name] ] delegate:self];
```

#### Step 3: Subscribe (Peer B)
``` objective-c
	- (void)connector:(TMFConnector *)tmf didChangeDiscoveringPeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)type {
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
```

#### Step 4: Execute (Peer A)
``` objective-c
	TMFKeyValueCommandArguments *kvArguments = [TMFKeyValueCommandArguments new];
    kvArguments.key = @"msg";
    kvArguments.value = @"Hello World!";
    [self.kvCmd sendWithArguments:kvArguments];
```

### Request Response Example
Request Response commands are a bit simpler. Setup, providing and discovery are equal to the Publish Subscribe scenario and the subscribe step is not available. The execution differs because the requester executes the command. This sends all parameters (may be optional) to the provider where request get processed followed by a result returned as response (asynchronously).
``` objective-c
	CADAnnounceCommandArguments *args = [CADAnnounceCommandArguments new];
	args.name = self.nameLabel.text;
	args.color = _color;

	[self.tmf sendCommand:[CADAnnounceCommand class] arguments:args destination:peer
		response:^(id response, NSError *error){
			// handle response or error
	}];	
```

## Platform
3MF is currently implemented in [Cocoa](https://developer.apple.com/cocoa/) running on iOS and OSX. The bigger vision is to have a system also spread across other relevant platforms like Android, Windows Phone, ... you name it. Feel free to contact [me](http://twitter.com/mgratzer), if you'r interested in porting 3MF --- I'm glad to provide help if needed.

## Requirements
The current implementation is using **ARC** with minimum deployment targets of **Mac OSX 10.7** and **iOS 5.0**.

## Adding 3MF to your Xcode project

You may use   [CocoaPods](http://cocoapods.org) instead of adding the source files directly to your project. Follow the instructions on the CocoaPods site for installation, and specify threeMF in your Podfile with `pod 'threeMF', '0.1'`.

Otherwise you can add threeMF as a [git submodule]((http://schacon.github.com/git/user-manual.html#submodules)) or [download](https://github.com/mgratzer/threeMF/archive/master.zip) the source code and manually copy it to your project.

1. Add the framework as a git submodule. Go to the root folder of your project and execute the following commands.
``` bash
	$ git submodule add https://github.com/mgratzer/threeMF.git Vendor/threeMF
	$ git submodule update --init --recursive 
```

2. Add (simply drag & drop) `Vendor/threeMF/threeMF` to your Xcode project.

3. Make sure the following frameworks are linked to your project's target: `CFNetworking.framework`, `Security.framework`, `SystemConfiguration.framework`. 

4. You need to add `CoreMotion.framework` and `CoreLocation.framework` to your -Prefix.pch file, if you want to use `TMFLocationCommand` and `TMFMotionCommand`.

## Documentation
Visit the [Wiki](https://github.com/mgratzer/threeMF/wiki/) for more detailed information and [http://threemf.com/documentation/](http://threemf.com/documentation/) for code documentation.

## Author
Developed by [Martin Gratzer](http://www.mgratzer.com) ([@mgratzer](http://twitter.com/mgratzer)) with supported by the [Interactive Systems research group](http://www.uni-klu.ac.at/tewi/inf/isys/ias/index.html) at the [University of Klagenfurt](http://www.uni-klu.ac.at).

## Thanks
3MF uses the great [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) library for it's build-in [TCP](http://threemf.com/documentation/Classes/TMFTcpChannel.html) and [UDP](http://threemf.com/documentation/Classes/TMFUdpChannel.html) network channels and the Base64 encoding part from [ytoolkit](https://github.com/sprhawk/ytoolkit) to encode binary data. JSON-RPC is the default communication protocol, but there is also a [coding class](http://threemf.com/documentation/Classes/TMFMsgPackRpcCoder.html) using the [MsgPack-ObjectiveC](https://github.com/msgpack/msgpack-objectivec) for [MsgPack-RPC](https://github.com/mgratzer/threeMF/wiki/MsgPack-RPC).

## License
threeMF is available under the MIT license. See the LICENSE.txt file for more info.