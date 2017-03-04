import core.time, core.thread;
import std.stdio;
static import elevator;
import button;

void main(){

    elevator.init(elev_type.ET_Comedi);
    //MultiState floors = MultiState("floor: ");
    elevator.up();
    Thread.sleep(dur!"msecs"(250));
    elevator.stop();
    Thread.sleep(dur!"msecs"(250));
    elevator.down();
    Thread.sleep(dur!"msecs"(250));
    elevator.stop();

    /+while( true){
        foreach(i; 0..N_FLOORS){
            floors.update( elev_get_floor_sensor_signal());
        }
    }+/
}
