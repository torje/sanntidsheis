import core.time, core.thread;
import std.stdio;
static import elevator;


void main(){

    Elevator.init(elev_type.ET_Comedi);
    //MultiState floors = MultiState("floor: ");
    Elevator.up();
    Elevator.stop();
    Elevator.down();
    Elevator.stop();

    /+while( true){
        foreach(i; 0..N_FLOORS){
            floors.update( elev_get_floor_sensor_signal());
        }
    }+/
}
