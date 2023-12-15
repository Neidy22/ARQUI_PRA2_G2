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
.equ SELEC_BTN, 6 ; Botón para seleccionar, conectado al pin digital 13
.equ MENU_BTN, 5 ; Botón para ir al menú de la aplicación, conectado al pin digital 12
.equ UP_BTN, 4 ; Botón para ir al menú de la aplicación, conectado al pin digital 11
.equ DOWN_BTN, 3 ; Botón para ir al menú de la aplicación, conectado al pin digital 10
.equ LEFT_BTN, 2 ; Botón para ir al menú de la aplicación, conectado al pin digital 9
.equ RIGHT_BTN, 1 ; Botón para ir al menú de la aplicación, conectado al pin digital 8


;===============================================================================================================
;                PIN DE SALIDA
; Definición de los pines a utilizar como OUTPUT
;================================================================================================================
.equ VIBRATOR, 4 ; Vibrador conectado al pin digital 4



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
  LDI R16, 0xFF ; Cargo el valor de 1 en el registro R16 
  OUT DDRB, R16 ; Configura todos los pines del puerto B como inputs porque le envia un 1


  ;---------------------------pinmode(pin, OUTPUT)---------------------------
  LDI R16, (1<<VIBRATOR) 
  OUT DDRD, R16  ; Activar el pin del puerto D como salida 
  

  SEI 
  RET 

;===============================================================================================================
;                MY LOOP
; Estará monitoreando la actividad de los botones para detectar cuando se pulse uno y mandará a escribir al 
; puerto serial
;===============================================================================================================
my_loop:

  ;--------------------------- Verificar si el botón select se pulso -------------------------------------------
  LDI R16, (1<<SELEC_BTN)  ; Cargar en el registro el  pin del puerto B que se va a monitorear
  IN R17, PINB             ; Obtener el status del pin 
  CPI R17, 0xFF            ; Comparar si está pulsado
  BREQ pushed_select

  

  

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
  SBI PORTD, 4        ; enviando un bit en el pin 4
  LDI R20, 90         ; Indicar cuántos ms quiero que este encendida
  RCALL delay_10ms    ; llamar al delay para que espere

  CBI PORTD, 4        ; Apagar el pin 4
  LDI R20,  10        ; Esperar 10 ms
  RCALL delay_10ms    ; llamar al delay para que espere

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



