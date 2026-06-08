// ===== UI COMPONENTS - ESTILO MINIMALISTA MODERNO =====
// Paleta: Fondo crema, acento azul cobalto, texto oscuro

// Colores del tema (se usan en todo el cliente)
final color CREMA_FONDO     = color(245, 240, 232);
final color AZUL_ACCENTO    = color(26, 95, 158);
final color AZUL_OSCURO     = color(13, 59, 102);
final color AZUL_CLARO      = color(200, 225, 245);
final color TEXTO_OSCURO    = color(26, 26, 46);
final color TEXTO_SUAVE     = color(130, 130, 150);
final color BLANCO_TARJETA  = color(255, 255, 255);
final color VERDE_ACIERTO   = color(46, 139, 87);
final color ROJO_ERROR      = color(192, 57, 43);
final color GRIS_BORDE      = color(210, 210, 215);

// ===== BOTÓN ESTILO PÍLDORA =====

class Button {
  float x, y, w, h;
  String label;
  color bgColor;
  float cornerRadius;

  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.bgColor = AZUL_ACCENTO;
    this.cornerRadius = h / 2;  // Forma de píldora
  }

  void draw() {
    draw(AZUL_ACCENTO, AZUL_OSCURO);
  }

  void draw(color normal, color hovered) {
    boolean sobre = isMouseOver();

    // Sombra sutil
    noStroke();
    fill(0, 0, 0, 15);
    rect(x + 2, y + 3, w, h, cornerRadius);

    // Cuerpo del botón
    fill(sobre ? hovered : normal);
    noStroke();
    rect(x, y, w, h, cornerRadius);

    // Texto blanco centrado, contenido dentro del botón con padding
    fill(255);
    textAlign(CENTER, CENTER);
    float labelSize = constrain(w * 0.1, 11, 15);
    textSize(labelSize);
    // Usar bounding box para que el texto no se salga del botón
    text(label, x + 6, y + 2, w - 12, h - 4);

    // Efecto de brillo sutil al pasar el mouse
    if (sobre) {
      fill(255, 255, 255, 20);
      rect(x, y, w, h/2, cornerRadius);
    }
  }

  boolean isMouseOver() {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}

// ===== CAMPO DE TEXTO ESTILO MODERNO =====

class TextField {
  float x, y, w, h;
  String text;
  String placeholder;
  boolean isFocused;

  TextField(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.text = "";
    this.placeholder = "";
    this.isFocused = false;
  }

  void setPlaceholder(String p) {
    this.placeholder = p;
  }

  void draw() {
    float r = h / 3;

    // Sombra sutil
    noStroke();
    fill(0, 0, 0, 8);
    rect(x + 1, y + 2, w, h, r);

    // Fondo del campo
    fill(isFocused ? color(255, 255, 250) : BLANCO_TARJETA);
    stroke(isFocused ? AZUL_ACCENTO : GRIS_BORDE);
    strokeWeight(isFocused ? 2 : 1);
    rect(x, y, w, h, r);

    // Texto
    fill(TEXTO_OSCURO);
    textAlign(LEFT, CENTER);
    textSize(constrain(h * 0.42, 11, 15));

    String display = text;
    boolean mostrarPlaceholder = (display.length() == 0 && !isFocused && placeholder.length() > 0);

    if (mostrarPlaceholder) {
      fill(TEXTO_SUAVE);
      display = placeholder;
    }

    if (isFocused && frameCount / 25 % 2 == 0 && !mostrarPlaceholder) {
      display += "|";
    }

    // Truncar si es muy largo
    while (textWidth(display) > w - 20 && display.length() > 0) {
      if (isFocused && display.endsWith("|")) {
        display = display.substring(1, display.length() - 1) + "|";
      } else {
        display = display.substring(1);
      }
    }
    text(display, x + 12, y + h/2);
  }

  void handleMouse() {
    isFocused = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}
