import std.concurrency, std.stdio, core.time;
import orders.command;
import networkd.udp_bcast, networkd.peers;
void main(){
    initCommand();
    Tid transmitThread = init();
    ubyte myId = id();
    Tid bcast = init!(NetworkOrder,OrderConfirmation)(id);
    spawn(&readOrders, bcast);
    auto timeout = dur!"msecs"(20);

    while(true){
        receiveTimeout( timeout,
        (Order order){writeln(order);},
        (OrderExpression orderexpr){
            writeln(orderexpr);
            if ( OrderOperation.Create == orderexpr.operation ){
                appendUnconfirmed(orderexpr.order,id);
            }else{
                removeOrders( orderexpr.order,id );
            }
            auto nOrder = NetworkOrder(orderexpr,id);
            writeln(nOrder);
            bcast.send(nOrder);
            },
        (NetworkOrder norder){
            writeln("received from net",norder);
            processNetworkOrder(norder,bcast,id);
            writeln( "processed order: ");
            writeln("confirmed: ",confirmedOrders);
            writeln("unconfirmedOrders: ", unconfirmedOrders);
            writeln("unconfirmedDeletions: ", unconfirmedDeletions);
        },
        //&deleteOrders,
        (PeerList pl1){
            writeln("Peerlist: ",pl1);
            pl = pl1;
        },
        (Update update){
            writeln("confirmed: ",confirmedOrders);
            writeln("unconfirmedOrders: ", unconfirmedOrders);
            writeln("unconfirmedDeletions: ", unconfirmedDeletions);
        },
        (OrderConfirmation conf){
            writeln(conf);
            processConfirmation(conf);
            writeln( "processed order: ");
            writeln("confirmed: ",confirmedOrders);
            writeln("unconfirmedOrders: ", unconfirmedOrders);
            writeln("unconfirmedDeletions: ", unconfirmedDeletions);
        },
        (Variant var){
            writeln("Torje, handle your shit");
            writeln(var);
        });
        pruneLists(pl);
    }
}
