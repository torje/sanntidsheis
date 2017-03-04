import core.time, core.thread;
import std.stdio;
static import elevator;
import button;
import std.concurrency;

void main(){

    elevator.init(elev_type.ET_Comedi);

    elevator.stop();

    Thread.sleep(dur!"msecs"(20));
}
