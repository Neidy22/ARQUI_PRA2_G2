

// Acceder a las subrutinas y procedimientos del archivo de assembler
extern "C"
{
  void start();
  void my_loop();
}

void setup(){
  start();
}

void loop(){
  
  my_loop();
  
}

  