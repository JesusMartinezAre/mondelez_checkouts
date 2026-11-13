// =============================================================================
//  Caja para Arduino Nano (NANO-V3) — controlador de tira WS2815B
//
//  - Base + tapa a presión (clic), esquinas redondeadas, etiqueta grabada.
//  - Ventana con rebaje para el conector USB Mini-B (reprogramar sin abrir).
//  - Salida de cable trasera con anclaje para brida (cincho) = alivio de tensión.
//  - Fondo plano para cinta doble cara.
//
//  Uso: abre en OpenSCAD, ajusta las medidas (sobre todo las del Nano, MÍDELAS),
//  cambia "pieza" a "base" o "tapa", F6 (render) y F7 (exportar STL).
//  Las piezas ya salen orientadas para imprimir (tapa boca abajo).
// =============================================================================

$fn = 48;

/* [Qué generar] */
pieza = "ensamble"; // [base, tapa, ensamble, explosion]

/* [Medidas del Nano — mídelas con vernier] */
placa_l       = 43.5;  // largo de la placa (sin contar el USB)
placa_a       = 18.6;  // ancho de la placa
placa_e       = 1.6;   // grosor del PCB
usb_sobresale = 1.0;   // cuánto sobresale el conector Mini-B del borde de la placa
usb_ancho     = 7.8;   // ancho del conector Mini-B
usb_alto      = 4.0;   // alto del conector Mini-B sobre la placa
icsp_alto     = 8.5;   // alto de los pines ICSP sobre la placa (0 si no están soldados)
pines_abajo   = 8.5;   // separador plástico + pines bajo la placa

/* [Caja] */
pared             = 2.0;
piso              = 2.0;
techo             = 2.0;
radio             = 3.0;   // radio de las esquinas exteriores
holgura           = 0.4;   // holgura alrededor de la placa
espacio_soldadura = 5.5;   // espacio bajo las puntas de los pines para soldar y doblar cables
espacio_lateral   = 2.0;   // a cada lado de la placa, para pasar cables
espacio_trasero   = 10.0;  // detrás de la placa: anclaje de brida y salida de cable
espacio_arriba    = 1.0;   // sobre lo más alto (ICSP o USB)
cable_d           = 5.0;   // diámetro del agujero de salida del cable
labio_alto        = 3.0;   // labio de la tapa que entra en la base
labio_e           = 1.2;   // grosor del labio
ajuste_tapa       = 0.2;   // holgura labio-pared (súbelo a 0.3 si entra muy duro)
clic              = true;  // pestañas de clic en la tapa

/* [Etiqueta] */
etiqueta   = "LED CTRL";
texto_tam  = 5;
texto_prof = 0.6;

// ----------------------------------------------------------------------------
//  Medidas derivadas (no tocar)
// ----------------------------------------------------------------------------
alto_bajo  = pines_abajo + espacio_soldadura;
alto_sobre = max(icsp_alto, usb_alto) + espacio_arriba;
gap_usb    = usb_sobresale + 0.2;   // la cara del conector queda a ras de la pared interior

in_l = gap_usb + placa_l + espacio_trasero;
in_a = placa_a + 2 * holgura + 2 * espacio_lateral;
L    = in_l + 2 * pared;
A    = in_a + 2 * pared;

z_b  = piso + alto_bajo;      // cara inferior de la placa
z_t  = z_b + placa_e;         // cara superior de la placa
z_in = z_t + alto_sobre;      // cara inferior de la tapa (= borde superior de la base)
H    = z_in + techo;          // alto total

bx0 = pared + gap_usb;        // borde de la placa del lado USB
bx1 = bx0 + placa_l;          // borde de la placa del lado ICSP
yc  = A / 2;
r_in = max(radio - pared, 0.5);

echo(str("Medidas exteriores: ", L, " x ", A, " x ", H, " mm"));

// ----------------------------------------------------------------------------
//  Utilidades
// ----------------------------------------------------------------------------
module rbox(l, a, h, r) {   // caja con aristas verticales redondeadas
  hull() for (x = [r, l - r], y = [r, a - r]) translate([x, y, 0]) cylinder(r = r, h = h);
}

module rrect_x(w, h, d, r) {   // rectángulo redondeado extruido en +X, centrado en Y/Z
  hull() for (sy = [-1, 1], sz = [-1, 1])
    translate([0, sy * (w / 2 - r), sz * (h / 2 - r)]) rotate([0, 90, 0]) cylinder(r = r, h = d);
}

// ----------------------------------------------------------------------------
//  Base
// ----------------------------------------------------------------------------
module base() {
  difference() {
    rbox(L, A, z_in, radio);

    // Hueco interior
    translate([pared, pared, piso]) rbox(in_l, in_a, z_in, r_in);

    // Ventana USB + rebaje exterior para que entre el plástico del cable
    translate([-1, yc, z_t + usb_alto / 2]) rrect_x(usb_ancho + 1.4, usb_alto + 1.4, pared + 2, 1);
    translate([-1, yc, z_t + usb_alto / 2]) rrect_x(12.5, 9, 1 + 1.2, 1.5);

    // Salida de cable trasera
    translate([L - pared - 1, yc, piso + 3.5 + cable_d / 2]) rotate([0, 90, 0]) cylinder(d = cable_d, h = pared + 2);

    // Ranuras de clic
    if (clic) for (y = [pared, A - pared])
      translate([L / 2 - 7.5, y, z_in - labio_alto / 2]) rotate([0, 90, 0]) cylinder(r = 0.6, h = 15);
  }

  // Soportes de la placa (solo en el centro de los extremos, lejos de los pines)
  translate([bx0, yc - 5, piso - 0.01]) cube([2.5, 10, alto_bajo + 0.01]);
  translate([bx1 - 2.5, yc - 5, piso - 0.01]) cube([2.5, 10, alto_bajo + 0.01]);
  // Tope trasero (impide que la placa se deslice hacia atrás)
  translate([bx1 + 0.3, yc - 5, piso - 0.01]) cube([1.8, 10, alto_bajo + placa_e + 0.8]);

  // Anclaje para brida: la brida pasa por el túnel y abraza el cable
  ax0 = L - pared - 7;
  difference() {
    translate([ax0, yc - 5, piso - 0.01]) cube([6, 10, 3.5]);
    translate([ax0 + 1, yc - 6, piso - 0.02]) cube([4, 12, 1.8]);
  }
}

// ----------------------------------------------------------------------------
//  Tapa (en posición de ensamble)
// ----------------------------------------------------------------------------
module tapa() {
  difference() {
    union() {
      translate([0, 0, z_in]) rbox(L, A, techo, radio);

      // Labio perimetral
      translate([0, 0, z_in - labio_alto]) difference() {
        translate([pared + ajuste_tapa, pared + ajuste_tapa, 0])
          rbox(in_l - 2 * ajuste_tapa, in_a - 2 * ajuste_tapa, labio_alto + 0.01, r_in);
        translate([pared + ajuste_tapa + labio_e, pared + ajuste_tapa + labio_e, -1])
          rbox(in_l - 2 * (ajuste_tapa + labio_e), in_a - 2 * (ajuste_tapa + labio_e), labio_alto + 2, 0.5);
      }

      // Pestañas de clic
      if (clic) for (y = [pared + ajuste_tapa, A - pared - ajuste_tapa])
        translate([L / 2 - 6, y, z_in - labio_alto / 2]) rotate([0, 90, 0]) cylinder(r = 0.5, h = 12);

      // Costillas que sujetan la placa contra los soportes
      zf = z_t + usb_alto + 0.2;   // sobre el conector USB
      translate([pared + 1.6, yc - 3, zf]) cube([bx0 + 5 - (pared + 1.6), 6, z_in - zf + 0.01]);
      zr = z_t + icsp_alto + 0.2;  // sobre el ICSP (o la placa si no hay ICSP)
      translate([bx1 - 6, yc - 3, zr]) cube([5, 6, z_in - zr + 0.01]);
    }

    // Etiqueta grabada
    translate([L / 2, A / 2, H - texto_prof])
      linear_extrude(texto_prof + 1)
        text(etiqueta, size = texto_tam, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
  }
}

// ----------------------------------------------------------------------------
//  Nano simplificado (solo para visualizar)
// ----------------------------------------------------------------------------
module nano_dummy() {
  y0 = yc - placa_a / 2;
  color("royalblue") translate([bx0, y0, z_b]) cube([placa_l, placa_a, placa_e]);
  color("silver") translate([bx0 - usb_sobresale, yc - usb_ancho / 2, z_t]) cube([7, usb_ancho, usb_alto]);
  if (icsp_alto > 0) color("dimgray") translate([bx1 - 6, yc - 3.8, z_t]) cube([5, 7.6, icsp_alto]);
  for (dy = [-7.62, 7.62]) {
    color("black") translate([bx0 + 2.5 - 1.27, yc + dy - 1.27, z_b - 2.5]) cube([38.1, 2.54, 2.5]);
    color("gold") translate([bx0 + 2.5, yc + dy - 0.3, z_b - pines_abajo]) cube([37, 0.6, pines_abajo]);
  }
}

// ----------------------------------------------------------------------------
//  Selección
// ----------------------------------------------------------------------------
if (pieza == "base") {
  base();
} else if (pieza == "tapa") {
  translate([0, A, H]) rotate([180, 0, 0]) tapa();   // boca abajo para imprimir
} else if (pieza == "explosion") {
  color("whitesmoke") base();
  nano_dummy();
  color("lightgray") translate([0, 0, 20]) tapa();
} else {
  color("whitesmoke") base();
  nano_dummy();
  color("lightgray", 0.35) tapa();
}
