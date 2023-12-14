


// Acceder a las subrutinas y procedimientos del archivo de assembler

extern "C"
{
  void start();
  void write_serial();
}

void setup(){
  start();
}

void loop(){
  write_serial();
}

  