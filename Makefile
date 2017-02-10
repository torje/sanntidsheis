DC=dmd
DO=-c

elevatordriver:elevatordriver/elevatordriver.o
elevatordriver/elevatordriver.o: elevatordriver/elevatordriver.d 
	$(DC) $(DO) -of$@ $^
iotest.o:iotest.d
	$(DC) $(DO) -of$@ $^

iotest:iotest.o elevatordriver/elevatordriver.o
	$(DC) $^
