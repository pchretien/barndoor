//// barndoor ////
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License Version 2
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// You will find the latest version of this code at the following address:
// http://github.com/pchretien
//
// You can contact me at the following email address:
// philippe.chretien@gmail.com

#include <avr/interrupt.h>
#include <avr/io.h>

#define INIT_TIMER_COUNT 6
#define RESET_TIMER2 TCNT2 = INIT_TIMER_COUNT

#define CW     HIGH
#define CCW    LOW

// One and two phases
// 60000ms / 48steps = 1250ms/step
#define TRACK  1250

// Half steps
// 60000ms / 96steps = 625
//#define TRACK 625

int led13 = HIGH;
long counter = 0;
int stepStack = 0;

// Aruino runs at 16 Mhz, so we have 1000 Overflows per second...
// 1/ ((16000000 / 64) / 256) = 1 / 1000
ISR(TIMER2_OVF_vect) {
  RESET_TIMER2;
  counter++;  
  if(!(counter%TRACK))
  {
    // enqueue step message
    stepStack++;
  }
};

void setup()
{
  pinMode(2, OUTPUT);  // Step
  pinMode(3, OUTPUT);  // Direction
  pinMode(13, OUTPUT); // LED
  
  pinMode(4, INPUT);   // Power on/off
  pinMode(5, INPUT);   // Rewind
  
  //Timer2 Settings: Timer Prescaler /64, 
  TCCR2A |= (1<<CS22);    
  TCCR2A &= ~((1<<CS21) | (1<<CS20));     
  // Use normal mode
  TCCR2A &= ~((1<<WGM21) | (1<<WGM20));  
  // Use internal clock - external clock not used in Arduino
  ASSR |= (0<<AS2);
  //Timer2 Overflow Interrupt Enable
  TIMSK2 |= (1<<TOIE2) | (0<<OCIE2A);  
  RESET_TIMER2;               
  sei();
}

void loop()
{ 
  // READ INPUTS   
  int fast = digitalRead(4);
  int rewind = digitalRead(5);
  
  if(rewind == HIGH || fast == HIGH)
  {
    // Toggle the LED
    led13 ^= 1;
    digitalWrite(13, led13);
    
    // Clear the step messages buffer
    stepStack = 0;
    
    // Set rewind direction
    if(rewind == HIGH)
      digitalWrite(3, CCW);
    else
      digitalWrite(3, CW);
    
    digitalWrite(2, HIGH);  
    delay(10);  

    digitalWrite(2, LOW);   
    delay(10);
  }
  else if(stepStack)
  {
    // Toggle the LED
    led13 ^= 1;
    digitalWrite(13, led13); 
    
    // Set tracking direction
    digitalWrite(3, CW);
    
    digitalWrite(2, HIGH);  
    delay(1);  

    digitalWrite(2, LOW);   
    delay(1);
        
    stepStack--; 
  }
}

