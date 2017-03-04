import button;

struct MultiState{
    int function() foo;
    int state;
    string msg;
    int[] events;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    this (string msg){
        this.msg = msg;
    }
    void update(int current){
        if ( current != state){
            //writeln(msg,current);
            events~=current;
        }
        state = current;
    }
}

MultiState floor;
void init(elev_type et){
    elev_init( et);
}
void stop(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_STOP);
}
void up(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_UP);
}
void down(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_DOWN);
}
