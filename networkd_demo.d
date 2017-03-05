// build:  dmd main.d net/peers.d net/udp_bcast.d net/d-json/jsonx.d

import  core.thread,
        core.time,
        std.conv,
        std.concurrency,
        std.stdio;


//import  peers,
import  networkd.peers,
    networkd.udp_bcast;
    //udp_bcast;





void main(){
    Tid     peerTx  = init;
    ubyte   id      = id;
    Tid     bcast   = init!(HelloMsg, ArrayMsg)(id);

    spawn(&helloFrom, id, bcast);


    while(true){
        Duration timeout = dur!"msecs"(20);
        receiveTimeout(timeout,
        //receiveTimeout!(dur!"msecs"(20) )(
            (HelloMsg a){
                writeln("Received HelloMsg: ", a);
            },
            (ArrayMsg a){
                writeln("Received ArrayMsg: ", a);
            },
            (PeerList a){
                writeln("Received peer list: ", a);
            }
        );  
    }
}

void helloFrom(ubyte id, Tid bcast){
    while(true){
        bcast.send(HelloMsg("Hello!", id));
        //bcast.send(ArrayMsg([1,2,3,4]));
        Thread.sleep(1.seconds);
    }

}




struct HelloMsg {
    string  str;
    ubyte   id;
}

// Special case for sending dynamic arrays ("pointer & length" arrays):
// Sending pointers between threads is not allowed unless they are explicitly shared, and modifying shared values is not allowed
//  Solution: duplicate and cast to shared before sending to udp_bcast.tx thread (for 2+ dimensions remember to deep copy!),
//            cast away shared when reading freshly allocated value from udp_bcast.rx thread
struct ArrayMsg {
    shared int[] _arr;

    this(int[] a){
        this._arr = cast(shared)a.dup;
    }

    int[] arr(){
        return cast(int[])_arr;
    }
}
