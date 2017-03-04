import core.time, core.thread;
import std.stdio;
import button;
struct MultiState{
    int function() foo;
    int state;
    string msg;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    this (string msg){
        this.msg = msg;
    }
    void update(int current){
        if ( current != state){
            writeln(msg,current);
        }
        state = current;
    }
}

void main(){

    elev_init(elev_type.ET_Comedi);
    MultiState floors = MultiState("floor: ");
    while( true){
        foreach(i; 0..N_FLOORS){
            floors.update( elev_get_floor_sensor_signal());
        }
    }
}
