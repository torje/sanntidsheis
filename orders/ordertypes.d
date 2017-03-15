
import input.elev_wrap;



enum OrderDirection:int{
    DontCare = elev_button_type_t.BUTTON_COMMAND,
    DOWN = elev_button_type_t.BUTTON_CALL_DOWN,
    UP= elev_button_type_t.BUTTON_CALL_UP
}
enum Direction:int{
    UP ,
    DOWN,
    STILL
}
struct ArrivedAtDestination{
}
struct ResendAll{
    ubyte id;
}
struct FloorStop{
}
struct NetworkResendAll{
    ubyte id;
}
struct Update{
}
struct RetrieveId{
}
struct PollElevator{
}
struct RetrieveOrders{
}
struct RetrievePeers{
}
struct Order{
    int floor;
    OrderDirection direction;
    ubyte id;
    this(int floor, OrderDirection direction, ubyte id){
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
