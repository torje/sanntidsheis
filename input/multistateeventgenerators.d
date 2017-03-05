import std.typecons;
struct MultiState{
    int function() foo;
    int state;
    //string msg;
    Tuple!(int,int)[] events;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    void update(){
        int current = foo();
        if ( current != state){
            events~=tuple(state,current);;
        }
        state = current;
    }
}

struct MultiState2ary{
    int state;
    int function(int,int) foo;
    int arg0, arg1;
    Tuple!(int,int)[] events;
    this(int function(int,int) foo, int arg0, int arg1){
        this.foo = foo;
        this.arg0 = arg0;
        this.arg1 = arg1;
    }
    void update(){
        //writeln("updating");
        int current = foo(arg0, arg1);
        if ( current != state){
            //writeln("added event");
            events~=tuple(state,current);;
        }
        state = current;
    }

}
