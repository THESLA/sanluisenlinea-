// ===== UI COMPONENTS - SERVIDOR (ESTILO MINIMALISTA) =====
// Paleta consistente con el cliente

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

// ===== BOTÓN ESTILO MODERNO =====

class Button {
  float x, y, w, h;
  String label;
  color bgColor;

  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
    this.bgColor = AZUL_ACCENTO;
  }

  void draw() {
    draw(bgColor, AZUL_OSCURO);
  }

  void draw(color normal, color hovered) {
    boolean sobre = isMouseOver();
    float r = min(h/2, 6);

    // Sombra
    noStroke();
    fill(0, 0, 0, 12);
    rect(x + 1, y + 2, w, h, r);

    // Cuerpo
    fill(sobre ? hovered : normal);
    noStroke();
    rect(x, y, w, h, r);

    // Texto
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(constrain(h * 0.42, 11, 13));
    text(label, x + w/2, y + h/2);
  }

  boolean isMouseOver() {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}

// ===== CAMPO DE TEXTO =====

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
    float r = min(h/2, 5);

    // Sombra
    noStroke();
    fill(0, 0, 0, 6);
    rect(x + 1, y + 1, w, h, r);

    // Fondo
    fill(isFocused ? color(255, 255, 248) : BLANCO_TARJETA);
    stroke(isFocused ? AZUL_ACCENTO : GRIS_BORDE);
    strokeWeight(isFocused ? 2 : 1);
    rect(x, y, w, h, r);

    // Texto
    fill(TEXTO_OSCURO);
    textAlign(LEFT, CENTER);
    textSize(constrain(h * 0.45, 11, 13));

    String display = text;
    if (display.length() == 0 && !isFocused && placeholder.length() > 0) {
      fill(TEXTO_SUAVE);
      display = placeholder;
    }
    if (isFocused && frameCount / 20 % 2 == 0) {
      display += "|";
    }
    text(display, x + 6, y + h/2);
  }

  void handleMouse() {
    isFocused = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}
