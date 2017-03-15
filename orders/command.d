import std.concurrency, std.stdio, std.string, std.algorithm,std.array;
import core.thread, core.sync.mutex;
import orders.ordertypes;
import core.time :dur;

import networkd.udp_bcast, networkd.peers;


Mutex unconfirmedOrders_mutex;
OrderPlusConfirmation[] unconfirmedOrders;
Mutex confirmedOrders_mutex;
OrderPlusConfirmation[] confirmedOrders;
Mutex unconfirmedDeletions_mutex;
OrderPlusConfirmation[] unconfirmedDeletions;
PeerList pl;

void initCommand(){
    unconfirmedOrders_mutex = new Mutex;
    confirmedOrders_mutex = new Mutex;
    unconfirmedDeletions_mutex = new Mutex;
}
bool orderAmongstUnconfirmed( const OrderPlusConfirmation a ,const Order order){
    return a.order == order;
}
void appendUnconfirmed(Order order, ubyte id){

    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){
                if ( unconfirmedOrders.canFind!(orderAmongstUnconfirmed)(order)
                ){
                    auto where = unconfirmedOrders.find!(orderAmongstUnconfirmed)(order) ;
                    where[0].ids ~= id;
                    where[0].ids = where[0].ids.sort.uniq.array;
                }else if ( confirmedOrders.canFind!(orderAmongstUnconfirmed)(order) ){
                    auto where = confirmedOrders.find!(orderAmongstUnconfirmed)(order) ;
                    where[0].ids ~= id;
                    where[0].ids = where[0].ids.sort.uniq.array;
                }else{
                    unconfirmedOrders ~= OrderPlusConfirmation(order, id);
                }

            }
        }
    }

}
void removeOrders(Order order, ubyte id){

    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){
                if ( confirmedOrders.canFind!orderAmongstUnconfirmed(order) ){
                    confirmedOrders = confirmedOrders.remove!(a=> a.order == order);
                    auto where =  unconfirmedDeletions.find!orderAmongstUnconfirmed(order);
                    if ( where.length>0 ){
                        where[0].ids ~= id;
                    }else{
                        unconfirmedDeletions ~= OrderPlusConfirmation( order, id );
                    }
                }
            }
        }
    }
}
void readOrders(Tid bcast){
    import std.format;
    while(true){
        try{
            //write("floor direction id op: ");
            string line = readln();
            int floor,direction;
            string strOp;
            OrderOperation op;
            ubyte id;
            formattedRead(line, " %s %s %s" , &floor,&direction,&id,&strOp);
            strOp = strOp.strip;
            if ( "Delete" == strOp ){
                op = OrderOperation.Delete;
            }
            else if ( "Create" == strOp ) {
                op = OrderOperation.Create;
            }else{
                throw new Exception("done goofed");
            }
            auto oe = OrderExpression( Order(floor, cast(OrderDirection)direction, id), op) ;
            ownerTid.send(oe );
        }catch(Throwable t){
            //writeln("you write like a drunk: ", t);
            writeln("update");
            Update up;
            ownerTid.send(up);
        }
    }
}
void retransmit(Tid bcast, PeerList pl){
    ubyte[] ids = pl.peers.dup;
    synchronized(unconfirmedOrders_mutex){
        foreach(ref order; unconfirmedOrders){
            if (order.ids.sort != ids.sort){
                bcast.send( OrderExpression(order.order, OrderOperation.Create) );
            }
        }
    }
}
bool cmpOrderToNetworkOrder(Order order, NetworkOrder nOrder){
    return order == nOrder.orderExpr.order;
}
bool cmpOrderPlusConfirmationToNetworkOrder(OrderPlusConfirmation opc, NetworkOrder norder){
    return opc.order == norder.orderExpr.order;
}
void processNetworkOrder(NetworkOrder nOrder, Tid bcast, ubyte id ){
    if ( OrderOperation.Delete == nOrder.orderExpr.operation){
        deleteOrders(nOrder,bcast,id);
    }else if (OrderOperation.Create == nOrder.orderExpr.operation){
        insertOrders(nOrder,bcast,id);
    }
}
void insertOrders(NetworkOrder nOrder, Tid bcast, ubyte id ){

    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){

            }
        }
    }
    synchronized( confirmedOrders_mutex){
        //if ( unconfirmedOrders.canFind!((a,b)=>a.order==b.orderExpr.order )(nOrder)){
        if ( unconfirmedOrders.canFind!(cmpOrderPlusConfirmationToNetworkOrder)(nOrder)){
            auto where = unconfirmedOrders.find!cmpOrderPlusConfirmationToNetworkOrder(nOrder) ;
            where[0].ids ~= nOrder.id;
            where[0].ids ~= id;
            where[0].ids = where[0].ids.sort.uniq.array;
            auto conf = OrderConfirmation(nOrder.orderExpr, id);
            bcast.send(conf);
            // do not confirm anything from here
        }else if(  confirmedOrders.canFind!( ( a,b) => a.order == b )(nOrder.orderExpr.order)){
            auto conf = OrderConfirmation(nOrder.orderExpr, id);
            bcast.send(conf);
            // do not confirm anything from here
        }else{
            auto newOrder = OrderPlusConfirmation( nOrder.orderExpr.order, nOrder.id ) ;
            newOrder.ids ~= id;
            unconfirmedOrders ~= newOrder;
            auto conf = OrderConfirmation(nOrder.orderExpr, id);
            bcast.send(conf);
            // do not confirm anything from here
        }
    }
}
void deleteOrders(NetworkOrder toBeRemoved, Tid bcast, ubyte id ){
    synchronized( confirmedOrders_mutex){
        synchronized( unconfirmedDeletions_mutex ){
            OrderPlusConfirmation[] toBeKept;
            foreach( order ; confirmedOrders){
                if (order.order != toBeRemoved.orderExpr.order ){
                    toBeKept ~= order;
                }
            }
            confirmedOrders = toBeKept;
            if ( unconfirmedDeletions.canFind!( (a,b) => a.order == b.orderExpr.order )(toBeRemoved) ){
                auto where = unconfirmedDeletions.find!( (a,b) => a.order == b.orderExpr.order )(toBeRemoved) ;
                where[0].ids ~= toBeRemoved.id;
                where[0].ids = where[0].ids.sort.uniq.array;
                auto conf = OrderConfirmation(toBeRemoved.orderExpr, id);
                bcast.send(conf);
            }else{
                auto ud = OrderPlusConfirmation(  toBeRemoved.orderExpr.order,toBeRemoved.id );
                ud.ids ~= id;
                unconfirmedDeletions ~= ud;

                auto conf = OrderConfirmation(toBeRemoved.orderExpr, id);
                bcast.send(conf);
            }
        }
    }
}
void processConfirmation( OrderConfirmation conf  ){

    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){

            }
        }
    }

    if (conf.orderExpr.operation == OrderOperation.Create){
        foreach( ref ord; unconfirmedOrders ){
            if ( ord.order == conf.orderExpr.order){
                ord.ids ~= conf.id;
                ord.ids = ord.ids.sort.uniq.array;
            }
        }
    }else if ( conf.orderExpr.operation == OrderOperation.Delete ) {
        OrderPlusConfirmation[] newConfirmed;
        foreach(index, ref ord; confirmedOrders ){
            if ( ord.order == conf.orderExpr.order){
                OrderPlusConfirmation ordC = ord;
                unconfirmedDeletions ~=ord;
            }else{
                newConfirmed ~=ord;
            }
        }
        confirmedOrders = newConfirmed;
        foreach(ref ord; unconfirmedDeletions){
            if ( ord.order == conf.orderExpr.order){
                ord.ids ~= conf.id;
                ord.ids = ord.ids.sort.uniq.array;
            }
        }
    }
}
void pruneLists(PeerList pl){
    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){
                ubyte[] ids = pl.peers.dup.sort;
                {
                    OrderPlusConfirmation[] newUnconfirmed;
                    OrderPlusConfirmation[] newConfirmed;
                    foreach( ref order; unconfirmedOrders){
                        if ( order.ids.sort == ids ){
                            newConfirmed ~= order;
                        }else{
                            newUnconfirmed ~=order;
                        }
                    }
                    confirmedOrders ~= newConfirmed;
                    unconfirmedOrders = newUnconfirmed;
                }


                {
                    OrderPlusConfirmation[] newUnconfirmedDeletes;
                    foreach( ref order; unconfirmedDeletions){
                        if ( order.ids.sort == ids){
                        }else{
                            newUnconfirmedDeletes ~= order;
                        }
                    }
                    unconfirmedDeletions = newUnconfirmedDeletes;
                }
            }
        }
    }
}

void removeConfirmations(ubyte id){
    synchronized(unconfirmedOrders_mutex){
        synchronized(confirmedOrders_mutex){
            synchronized(unconfirmedOrders_mutex){
                foreach(ref order;unconfirmedOrders){
                    order.ids = order.ids.filter!(a=>a!=id).array;
                }
                foreach(ref order;confirmedOrders){
                    order.ids = order.ids.filter!(a=>a!=id).array;
                }

            }
        }
    }
}

immutable(Order)[] getRemainingOrders(){
    synchronized(confirmedOrders_mutex){
        auto confirmed = confirmedOrders.map!(a=>a.order).array;
        auto unconfirmed = confirmedOrders.map!(a=>a.order).array;
        auto all = confirmed~unconfirmed;
        return all.idup;
    }
}
immutable(ubyte)[] getPeers(){
    return pl.peers.idup;
}

void command_spawn(){
    initCommand();
    Tid transmitThread = init();
    ubyte myId = id();
    Tid bcast = init!(NetworkOrder,OrderConfirmation)(id);
    auto timeout = dur!"msecs"(20);

    while(true){
        receiveTimeout( timeout,
        (Order order){writeln(order);},
        (OrderExpression orderexpr){
            //writeln(orderexpr);
            if ( OrderOperation.Create == orderexpr.operation ){
                appendUnconfirmed(orderexpr.order,id);
            }else{
                removeOrders( orderexpr.order,id );
            }
            auto nOrder = NetworkOrder(orderexpr,id);
            //writeln(nOrder);
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
            //writeln("Peerlist: ",pl1);
            pl = pl1;
        },
        (Update update){
            writeln("confirmed: ",confirmedOrders);
            writeln("unconfirmedOrders: ", unconfirmedOrders);
            writeln("unconfirmedDeletions: ", unconfirmedDeletions);
        },
        (NetworkResendAll client){
            removeConfirmations(client.id);
        },
        (ResendAll client){
            unconfirmedOrders = [];
            confirmedOrders = [];
            unconfirmedDeletions =[];
        },
        (RetrieveOrders ret){
            auto ans = getRemainingOrders();
            ownerTid.send( ans );
        },
        (RetrieveId dummy){ ownerTid.send(id);},
        (RetrievePeers dummy){
            ownerTid.send(getPeers());
        },
        (OrderConfirmation conf){
            writeln(conf);
            processConfirmation(conf);
            //writeln( "processed order: ");
            //writeln("confirmed: ",confirmedOrders);
            //writeln("unconfirmedOrders: ", unconfirmedOrders);
            //writeln("unconfirmedDeletions: ", unconfirmedDeletions);
        },
        (Variant var){
            writeln("Unhandled message");
            writeln(var);
        });
        retransmit(bcast, pl);
        pruneLists(pl);
    }
}
