import std.concurrency, std.stdio, std.string, std.algorithm,std.array;
import core.thread, core.sync.mutex;
import core.time :dur;

import networkd.udp_bcast, networkd.peers;

struct Order{
    int floor;
    int direction;
    ubyte id;
    this(int floor, int direction, ubyte id){
        this.floor = floor;
        this.direction = direction;
        this.id = id;
    }
}
enum OrderOperation {Delete,Create};
struct OrderExpression{
    Order order;
    OrderOperation operation;
    this(Order order, OrderOperation operation){
        this.order = order;
        this.operation = operation;
    }
}
struct OrderPlusConfirmation{
    Order order;
    ubyte[] ids;
    this(Order order, ubyte id){
        ids = [id];
        this.order = order;
    }
}
struct OrderConfirmation{
    OrderExpression orderExpr;
    ubyte id;
    this(OrderExpression  orderExpr , ubyte id ){
        this.orderExpr = orderExpr;
        this.id = id;
    }
}
struct NetworkOrder{
    OrderExpression orderExpr;
    ubyte id;
    this( OrderExpression orderExpr, ubyte id){
        this.orderExpr = orderExpr;
        this.id = id;
    }
}


Mutex unconfirmedOrders_mutex;
OrderPlusConfirmation[] unconfirmedOrders;
Mutex confirmedOrders_mutex;
OrderPlusConfirmation[] confirmedOrders;
Mutex unconfirmedDeletions_mutex;
OrderPlusConfirmation[] unconfirmedDeletions;


void initCommand(){
    unconfirmedOrders_mutex = new Mutex;
    confirmedOrders_mutex = new Mutex;
    unconfirmedDeletions_mutex = new Mutex;
}

void readOrders(Tid bcast){
    import std.format;
    while(true){
        try{
            write("floor direction id op: ");
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
            auto oe = OrderExpression( Order(floor, direction, id), op) ;
            ownerTid.send(oe );
        }catch(Throwable t){
            writeln("you write like a drunk: ", t);
        }
    }
}

void retransmit(Tid bcast){
    synchronized(unconfirmedOrders_mutex){
        foreach(ref order; unconfirmedOrders){
            bcast.send( OrderExpression(order.order, OrderOperation.Create) );
        }
    }
}

bool cmpOrderToNetworkOrder(Order order, NetworkOrder nOrder){
    return order == nOrder.orderExpr.order;
}
bool cmpOrderPlusConfirmationToNetworkOrder(OrderPlusConfirmation opc, NetworkOrder norder){
    return opc.order == norder.orderExpr.order;
}

void moveOrders( PeerList pl){

}

void processNetworkOrder(NetworkOrder nOrder, Tid bcast, ubyte id ){
    if ( OrderOperation.Delete == nOrder.orderExpr.operation){
        deleteOrders(nOrder,bcast,id);
    }else if (OrderOperation.Create == nOrder.orderExpr.operation){
        insertOrders(nOrder,bcast,id);
    }
}
void insertOrders(NetworkOrder nOrder, Tid bcast, ubyte id ){
    synchronized( confirmedOrders_mutex){
        //if ( unconfirmedOrders.canFind!((a,b)=>a.order==b.orderExpr.order )(nOrder)){
        if ( unconfirmedOrders.canFind!(cmpOrderPlusConfirmationToNetworkOrder)(nOrder)){
            auto where = unconfirmedOrders.find!cmpOrderPlusConfirmationToNetworkOrder(nOrder) ;
            where[0].ids ~= nOrder.id ~ id;
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
                unconfirmedDeletions ~= OrderPlusConfirmation( toBeRemoved.orderExpr.order,toBeRemoved.id);
                auto conf = OrderConfirmation(toBeRemoved.orderExpr, id);
                bcast.send(conf);
            }
        }
    }
}


void processConfirmation( OrderConfirmation conf  ){
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



void main(){
    initCommand();
    Tid transmitThread = init();
    ubyte myId = id();
    Tid bcast = init!(NetworkOrder,OrderConfirmation)(id);
    spawn(&readOrders, bcast);
    Thread.sleep(dur!"seconds"(1) );
    auto timeout = dur!"msecs"(20);

    while(true){
        receiveTimeout( timeout,
        (Order order){writeln(order);},
        (OrderExpression orderexpr){
            writeln(orderexpr);
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
        (PeerList pl){
            writeln("Peerlist: ",pl);
        },
        //(OrderConfirmation conf){writeln(conf);},
        &processConfirmation,
        (Variant var){
            writeln("Torje, handle your shit");
            writeln(var);
        }

        );
    }
}
