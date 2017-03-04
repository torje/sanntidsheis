import button;
import core.thread;

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
    void update(){
        int current = foo();
        if ( current != state){
            events~=current;
        }
        state = current;
    }
    void update(int current){
        if ( current != state){
            //writeln(msg,current);
            events~=current;
        }
        state = current;
    }
}

enum OrderDirection{
    DontCare,DOWN,UP
}

struct Order{
    int floor;
    int direction;
}

bool defined = false;
MultiState floor;
void floor_seek(){
    up();
    floor.update();
    while(floor.state != -1){Thread.sleep(dur!"msecs"(32));floor.update();}
    stop();
}
void spawn(elev_type et){
    elev_init(et);
    //stop();
    floor_seek();
}
void init(elev_type et){
    elev_init(et);
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
