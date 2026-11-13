/*
 * Iluminación de mueble - Tira WS2815B (12 V) + Arduino Nano (NANO-V3, ATmega328)
 *
 * Secuencia en bucle (con los valores por defecto, tira de 14 LEDs):
 *   t = 0,0 s  todo apagado
 *   t = 0,3 s  se encienden los LEDs 1 y 14   (los extremos)
 *   t = 0,6 s  se encienden los LEDs 4 y 11   (1 y 14 siguen encendidos)
 *   t = 0,9 s  se encienden los LEDs 7 y 8    (encendidos: 1, 14, 4, 11, 7 y 8)
 *   t = 1,2 s  se apaga todo y vuelve a empezar
 *
 * No se usa delay(): el estado de cada LED se calcula a partir del tiempo
 * transcurrido desde el inicio del ciclo (millis()), así el loop nunca se bloquea.
 */

#include <Arduino.h>
#include <FastLED.h>

// ============================================================================
//  PARÁMETROS EDITABLES
// ============================================================================

// --- Hardware ---
const uint8_t NUM_LEDS = 14;  // LEDs físicos de la tira
const uint8_t DATA_PIN = 6;   // Pin del Nano conectado a DI de la tira

// --- Secuencia: cada fila es un paso; los LEDs de una fila se encienden juntos ---
// LEDs numerados desde 1, como en la tira. Usa 0 para dejar un hueco vacío.
const uint8_t LEDS_POR_PASO = 2;
const uint8_t SECUENCIA[][LEDS_POR_PASO] = {
  {1, 14},   // paso 1
  {4, 11},   // paso 2
  {7, 8},    // paso 3
};

// --- Tiempos (milisegundos) ---
const uint32_t TIEMPO_APAGADO          = 300;   // Todo apagado al inicio de cada ciclo
const uint32_t INTERVALO_ENTRE_PASOS   = 300;   // Entre un paso y el siguiente
const uint32_t TIEMPO_TODOS_ENCENDIDOS = 300;   // Desde el último paso hasta que se apaga todo

// --- Aspecto ---
const uint8_t BRILLO = 255;                    // Brillo global 0-255 (255 = 100 %)
const CRGB    COLOR  = CRGB(255, 255, 255);    // Blanco puro. Blanco cálido: CRGB(255, 140, 40)

// --- Fade al encender (opcional) ---
const bool     FADE_ACTIVADO = false;  // true = cada paso aparece con un fundido suave
const uint32_t DURACION_FADE = 200;    // Duración del fundido (ms). Debe ser < INTERVALO_ENTRE_PASOS

// --- Orden de color de la tira ---
// Si el blanco cálido sale azulado/verdoso, prueba RGB, BRG, etc. (ver README).
#define ORDEN_COLOR GRB

// ============================================================================
//  CÓDIGO
// ============================================================================

const uint8_t PASOS = sizeof(SECUENCIA) / sizeof(SECUENCIA[0]);

// Instantes clave del ciclo (ms desde el inicio del ciclo)
const uint32_t INSTANTE_PRIMER_PASO = TIEMPO_APAGADO;
const uint32_t INSTANTE_APAGADO     = TIEMPO_APAGADO + (uint32_t)(PASOS - 1) * INTERVALO_ENTRE_PASOS
                                      + TIEMPO_TODOS_ENCENDIDOS;
const uint32_t DURACION_CICLO       = INSTANTE_APAGADO;  // al apagarse todo, empieza el siguiente ciclo

static_assert(PASOS >= 1, "SECUENCIA no puede estar vacía");

CRGB leds[NUM_LEDS];
uint32_t inicioCiclo = 0;  // millis() en el que empezó el ciclo actual

// Nivel (0-255) que deben tener los LEDs del paso p en el instante t del ciclo
uint8_t nivelPaso(uint8_t p, uint32_t t) {
  uint32_t inicio = INSTANTE_PRIMER_PASO + (uint32_t)p * INTERVALO_ENTRE_PASOS;
  if (t < inicio || t >= INSTANTE_APAGADO) return 0;
  if (!FADE_ACTIVADO || DURACION_FADE == 0) return 255;
  uint32_t dt = t - inicio;
  if (dt >= DURACION_FADE) return 255;
  return (uint8_t)(dt * 255UL / DURACION_FADE);  // rampa lineal
}

void setup() {
  FastLED.addLeds<WS2812B, DATA_PIN, ORDEN_COLOR>(leds, NUM_LEDS);  // WS2815 usa el mismo protocolo que WS2812B
  FastLED.setBrightness(BRILLO);
  FastLED.clear(true);  // arranca con todo apagado
  inicioCiclo = millis();
}

void loop() {
  uint32_t t = millis() - inicioCiclo;  // resta sin signo: segura ante el desborde de millis()

  if (t >= DURACION_CICLO) {            // fin del ciclo: reiniciar
    inicioCiclo += DURACION_CICLO;
    t -= DURACION_CICLO;
  }

  // Calcula el estado deseado de toda la tira: todo apagado salvo los LEDs de la secuencia
  CRGB deseado[NUM_LEDS];
  for (uint8_t i = 0; i < NUM_LEDS; i++) deseado[i] = CRGB::Black;

  for (uint8_t p = 0; p < PASOS; p++) {
    CRGB c = COLOR;
    c.nscale8_video(nivelPaso(p, t));
    for (uint8_t k = 0; k < LEDS_POR_PASO; k++) {
      uint8_t numero = SECUENCIA[p][k];
      if (numero == 0 || numero > NUM_LEDS) continue;  // hueco vacío o LED fuera de la tira
      deseado[numero - 1] = c;                         // número de LED (1..N) -> índice (0..N-1)
    }
  }

  // Solo refresca la tira si algo cambió
  bool cambio = false;
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    if (leds[i] != deseado[i]) {
      leds[i] = deseado[i];
      cambio = true;
    }
  }
  if (cambio) FastLED.show();
}
