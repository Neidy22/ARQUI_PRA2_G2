//Permite la compatibilidad entre versiones AVR anteriores
#define __SFR_OFFSET 0x00

//Permite el uso de mnemónicos como PORTB, DDRB, UCSR0A, etc 
#include "avr/io.h"  


;================================================================================================================
;     Definiciones de subrutinas globales para que puedan ser accedidas desde el archivo .ino
;================================================================================================================
.global start
.global write_serial
.global write_char
.global my_loop 
;================================================================================================================


;===============================================================================================================
;                PINES DE ENTRADA
; Definición de los pines a utilizar como INPUTS
;================================================================================================================
; Botón para seleccionar, conectado al pin digital 8
; Botón para ir al menú de la aplicación, conectado al pin digital 7
; Botón para seleccionar  arriba, conectado al pin digital 6
; Botón para seleccionar  abajo, conectado al pin digital 5
; Botón para seleccionar  izquierda, conectado al pin digital 4
; Botón para seleccionar  derecha, conectado al pin digital 3


;===============================================================================================================
;                PIN DE SALIDA
; Definición de los pines a utilizar como OUTPUT
;================================================================================================================
; Vibrador conectado al pin digital 2



;===============================================================================================================
;                START 
; Tiene la función de un setup en arduino, inicializa la comunicación serial y los pinmode de los pines utilizados
;================================================================================================================
start:
  
  ;---------------------------Serial.begin(9600)---------------------------

  CLR R24                       ; limpiar el registro R0 para asegurarse que el contenido inicial sea 0
  STS UCSR0A, R24               ; limpiar el registro UCSR0A
  STS UBRR0H, R24               ; limpiar el registro UBRR0H
  LDI R24, 103                  ; Valor para el baudrate  calculado br = (10^6/9600) - 1 = 103
  STS UBRR0L, R24               ; Cargar el baudrate en la parte baja del registro UBRR0 
  LDI R24, 1<<RXEN0 | 1<<TXEN0  ; Habilitar los pines RX y TX 
  STS UCSR0B, R24
  LDI R24, 1<<UCSZ00 | 1<<UCSZ01 ; asincrono porque es para comunicarse con el puerto com de la computadora, sin paridad,  1 bit de stop,  8 bits de transferencia
  STS UCSR0C, R24 

  ;---------------------------pinmode(pin, INPUT)---------------------------
  CBI DDRB, 0 ; Limpiar PB0 para i/o del botón seleccionar
  CBI DDRD, 7 ; Limpiar PD7 para i/o del botón menu
  CBI DDRD, 6 ; Limpiar PD7 para i/o del botón arriba
  CBI DDRD, 5 ; Limpiar PD7 para i/o del botón abajo
  CBI DDRD, 4 ; Limpiar PD7 para i/o del botón izquierda
  CBI DDRD, 3 ; Limpiar PD7 para i/o del botón derecha 

  ;---------------------------pinmode(pin, OUTPUT)---------------------------
  SBI DDRD, 2 ; Configurar PD2 para el vibrador
  
  RET 

;===============================================================================================================
;                MY LOOP
; Estará monitoreando la actividad de los botones para detectar cuando se pulse uno y mandará a escribir al 
; puerto serial
;===============================================================================================================
my_loop:


  ;--------------------------- Leer del puerto serial y activar el pin 2 si es 'v' ---------------------------
  LDS R17, UCSR0A
  SBRS R17, RXC0        ; Verificar si hay datos disponibles para leer del puerto serial
  RJMP check_serial_data ; Si no hay datos disponibles, saltar a la próxima verificación

  LDS R18, UDR0          ; Leer el carácter del puerto serial
  CPI R18, 'v'           ; Comparar si el carácter leído es 'v'
  RCALL delay_10ms    ; llamar al delay para que espere
  BREQ activate_pin_2  ; Si es 'v', saltar a activate_pin_2

check_serial_data:
  ;--------------------------- Verificar si el botón select se pulso -------------------------------------------
  SBIC PINB, 0
  RJMP pushed_select
  ;--------------------------- Verificar si el botón menu se pulso -------------------------------------------
  SBIC PIND, 7
  RJMP pushed_menu
  ;--------------------------- Verificar si el botón arriba -------------------------------------------
  SBIC PIND, 6
  RJMP pushed_up
  ;--------------------------- Verificar si el botón abajo -------------------------------------------
  SBIC PIND, 5
  RJMP pushed_down
  ;--------------------------- Verificar si el botón izquierda -------------------------------------------
  SBIC PIND, 4
  RJMP pushed_left
  ;--------------------------- Verificar si el botón derecha se pulso -------------------------------------------
  SBIC PIND, 3
  RJMP pushed_right

  ; Si no se pulsó ningún botón
  
  LDI R18, 'n'
  RCALL write_char
  LDI R20, 50 
  RCALL delay_10ms;
  JMP my_loop 

pushed_select:
  LDI R18, 'k'        ; Cargar en el registro R18 el caracter a enviar a la app
  RCALL write_char
  ;--------------------------- Encender el led por un segundo / vibrar -------------------------------------------
  SBI PORTD, 2        ; enviando un bit en el pin 2
  LDI R20, 100         ; Indicar cuántos ms quiero que este encendida
  RCALL delay_10ms    ; llamar al delay para que espere
  
  CBI PORTD, 2       ; Apagar el pin 2
  LDI R20,  10        ; Esperar 10 ms
  RCALL delay_10ms    ; llamar al delay para que espere
  JMP my_loop


pushed_menu:
  LDI R18, 'm'
  JMP next_cycle
pushed_up:
  LDI R18, 'w'
  JMP next_cycle
pushed_down:
  LDI R18, 's'
  JMP next_cycle
pushed_left:
  LDI R18, 'a'
  JMP next_cycle
pushed_right:
  LDI R18, 'd'
  
next_cycle:
  RCALL write_char
  JMP my_loop 

activate_pin_2:
  ;--------------------------- Activar pin 2 por 3 segundos -------------------------------------------

  SBI PORTD, 2           ; Activar el pin 2
  LDI R20, 100            ; Indicar cuántos ciclos de 100 ms (3000 ms en total)
  RCALL delay_10ms      ; Llamar al delay para esperar

  CBI PORTD, 2           ; Desactivar el pin 2
  LDI R20,  10            ; Esperar 10 ms
  RCALL delay_10ms       ; Llamar al delay para esperar  
  JMP my_loop






;===============================================================================================================
;                WRITE SERIAL
; Tiene la función de comprobar que el TX tenga activada la bandera de disponibilidad para escribir en el puerto
;================================================================================================================
write_serial:
  LDI R30, lo8(message)    ; cargar en el registro R30 el valor almacenado en los 8 bits menos significativos del dato en memoria correspondiente al mensaje
  LDI R31, hi8(message)    ; cargar en el registro R30 el valor almacenado en los 8 bits más significativos del dato en memoria correspondiente al mensaje
load_char:
  LPM R18, Z+              ; Z apunta hacia la cadena de salida, cargar su valor en el registro R18
  CPI R18, 0               ; Comparar si la cadena que se encuentra cargada en el registro R18 ya llegó a su final (0)
  BREQ completed_sending   ; Si llegó al final de la cadena ramificar hacia la subrutina "completed_sending" 
l1:
  LDS R17, UCSR0A
  SBRS R17, UDRE0         ; Verificar si se puede enviar datos por el puerto de transmisión 
  RJMP l1                 ; Si el puerto no está disponible esperar hasta que lo este 
  STS UDR0, R18           ; Almacenar el char cargado en el registro R18 hacia el puerto serial 
  RJMP  load_char         ; Saltar hacia atrás al load_char para obtener y cargar el siguiente carácter 
completed_sending:
  RCALL delay_10ms
  RET 

;===============================================================================================================
;                WRITE CHAR
; Tiene la función de comprobar que el TX tenga activada la bandera de disponibilidad para escribir en el puerto
; Y escribe el char que trae en R18
;================================================================================================================
write_char:
  LDS R17, UCSR0A
  SBRS R17, UDRE0         ; Verificar si se puede enviar datos por el puerto de transmisión 
  RJMP write_char              ; Si el puerto no está disponible esperar hasta que lo este 
  STS UDR0, R18           ; Almacenar el char cargado en el registro R18 hacia el puerto serial 
completed_sending_char:
  RCALL delay_10ms
  RET 



;===============================================================================================================
;                MESSAGE
; Cadena de caracteres que se enviarà como respuesta al detectar una acciòn en el circuito 
;================================================================================================================
message:
  .ascii "Sin actividad" ; mensaje inicial cuando no se ha detectado ninguna señal
  .byte 10,13,0          ; 10 = salto de linea, 13 = retorno de carro, 0 = finalizador de la cadena





;===============================================================================================================
;                DELAY_10MS
; Crea un delay de 1s iterando sobre un loop por un tiempo establecido.
;================================================================================================================

	.equ	delayCont, 39998		;  número de veces que se va a iterar para usar los ciclos esperados

delay_10ms:

  LDI	R30, lo8(delayCont)	; Cargar los bits menos significativos del contador del delay en el registro R30
  LDI	R31, hi8(delayCont)	; Cargar los bits mas significativos del contador del delay en el registro R31

counterLoop: 				; Se va a iterar hasta que el delayCont llegue al valor de 0

	SBIW	R30, 1 		; Del registro con los bits menos significativos se decrementa en uno 
	BRNE	counterLoop 	; Verificar que la zero flag no este activa para seguir en el loop

	SUBI	R20, 1		; Inner loop got to zero so now decrement (by 1) the outer loop counter [1 cycle]
	BRNE	delay_10ms	; Ramifica hasta el delay_1s si la zero flag esta desactivada
  

	NOP				; Añade un ciclo para completar los 160,000 ciclos del reloj para el 10mS delay 
	RET					; Retorna al PC donde fue llamado




