# Iluminación de mueble — WS2815B + Arduino Nano

Secuencia en bucle (tira de 14 LEDs):
todo apagado → (0,3 s) LEDs 1 y 14 → (0,3 s) LEDs 4 y 11 → (0,3 s) LEDs 7 y 8 → (0,3 s) se apaga todo → repetir.
Color blanco puro, brillo 100 %.
Los demás LEDs quedan siempre apagados.
Todos los parámetros están al inicio de `src/main.cpp` (`SECUENCIA`, tiempos, brillo, color).

## Compilar y subir (PlatformIO)

```bash
pio run                        # compilar (bootloader nuevo, entorno por defecto)
pio run -t upload --upload-port COM6   # subir (tu Nano está en COM6)
pio run -e nano_old -t upload  # solo si algún día usas un Nano con bootloader viejo
pio device list                # ver en qué puerto COM está el Nano
```

Si falla con `stk500_getsync(): not in sync`, prueba con el otro entorno o revisa que el puerto sea el correcto.

## Conexión

```
 Fuente 12V                        Tira WS2815B (primer LED)
 ┌────────┐                        ┌──────────────────────┐
 │  +12V  ├────────────┬──────────►│ +12V                 │
 │        │          ═╪═ 1000µF    │                      │
 │        │           │  25V       │                      │
 │  GND   ├───────────┴───┬───────►│ GND                  │
 └────────┘               │   ┌───►│ BI  (backup data)    │
                          │   │    │                      │
                          ├───┘ ┌─►│ DI  (data in)        │
                          │     │  └──────────────────────┘
 Arduino Nano             │     │
 ┌────────┐               │     │
 │  GND   ├───────────────┘     │   (GND común obligatorio)
 │  D6    ├────[ 330–470 Ω ]────┘   (resistencia cerca de la tira)
 │  VIN   │◄── +12V de la fuente (el regulador del Nano lo baja a 5 V)
 └────────┘
```

- **BI → GND** en el primer LED.
- **Alimentación del Nano:** +12V de la fuente al pin **VIN** y GND de la fuente al **GND** del Nano.
  El NANO-V3 admite 7–12 V en VIN; con la carga de este proyecto (solo el Nano, unos 20 mA) el regulador apenas se calienta.
  **Nunca** conectes 12 V al pin **5V**.
- Alternativa (no hace falta aquí): reductor 12V→5V al pin 5V, solo si la fuente da más de ~12,5 V o si el Nano tuviera que alimentar más cosas.

## Placa usada

NANO-V3 de AG Electrónica (clon compatible, marca MIN): ATmega328, USB Mini-B. Al conectarlo se detectó como FTDI FT232R (VID 0403:6001), no CH340, y con bootloader NUEVO (115200).
- Windows lo reconoce con el driver FTDI que trae de serie (no hace falta el CH340).
- Por eso `nano_new` es el entorno por defecto.

## Orden de color

Por defecto es `GRB`. Si el blanco cálido no sale bien, cambia `#define ORDEN_COLOR` en `src/main.cpp`.
Haz dos pruebas con `ORDEN_COLOR GRB` todavía puesto:
1. `COLOR = CRGB(255, 0, 0)` (rojo puro) → apunta qué color ves
2. `COLOR = CRGB(0, 0, 255)` (azul puro) → apunta qué color ves

| Con rojo ves | Con azul ves | Usa   |
|--------------|--------------|-------|
| Rojo         | Azul         | `GRB` (ya está bien) |
| Rojo         | Verde        | `BRG` |
| Verde        | Azul         | `RGB` |
| Verde        | Rojo         | `BGR` |
| Azul         | Verde        | `RBG` |
| Azul         | Rojo         | `GBR` |

Luego vuelve a poner el `COLOR` original.

## Caja para el Nano (impresión 3D)

Archivos en `caja/`:
- `caja_nano.scad`: modelo paramétrico (OpenSCAD).
- `stl/caja_base.stl` y `stl/caja_tapa.stl`: listos para imprimir, ya orientados.

Medidas exteriores: **58,7 × 27,4 × 29,1 mm**. Tapa a presión (clic), etiqueta "LED CTRL" grabada, ventana para el USB Mini-B (puedes reprogramar sin abrir), salida de cable trasera con anclaje de brida y fondo plano para cinta doble cara.

**Antes de imprimir, mide tu Nano** (largo y ancho de la placa). Si no coincide con 43,5 × 18,6 mm, cambia `placa_l` / `placa_a` en el `.scad` y vuelve a exportar (en `pieza`, elige `base` o `tapa`, luego F6 y F7).

Impresión: PLA o PETG, capa 0,2 mm, 3 perímetros, 20 % de relleno, **sin soportes**.

Montaje:
1. Pasa el cable de 3 hilos por el agujero trasero **antes de soldar**.
2. Suelda a las puntas de los pines (por debajo de la placa): **VIN**, **GND** y **D6**. La resistencia de 330–470 Ω puede ir dentro de la caja, en línea con el cable de D6, cubierta con termorretráctil.
3. Asegura el cable con una brida delgada (2,5 mm) que pase por el túnel del anclaje.
4. Apoya el Nano en los soportes con el USB pegado a la ventana y cierra la tapa hasta que haga clic.
