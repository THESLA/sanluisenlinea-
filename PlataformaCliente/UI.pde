// ===== UI COMPONENTS =====

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
    this.bgColor = color(70);
  }
  
  void draw() {
    draw(bgColor, bgColor);
  }
  
  void draw(color normal, color active) {
    boolean hovered = isMouseOver();
    fill(hovered ? active : normal);
    stroke(50);
    strokeWeight(1);
    rect(x, y, w, h, 5);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(13);
    text(label, x + w/2, y + h/2);
  }
  
  boolean isMouseOver() {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}

class TextField {
  float x, y, w, h;
  String text;
  boolean isFocused;
  
  TextField(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.text = "";
    this.isFocused = false;
  }
  
  void draw() {
    fill(isFocused ? color(255, 255, 230) : 255);
    stroke(isFocused ? color(50, 150, 255) : 180);
    strokeWeight(isFocused ? 2 : 1);
    rect(x, y, w, h, 4);
    fill(30);
    textAlign(LEFT, CENTER);
    textSize(13);
    String display = text;
    if (isFocused && frameCount / 25 % 2 == 0) {
      display += "|";
    }
    // Truncate if too long
    while (textWidth(display) > w - 15 && display.length() > 0) {
      if (isFocused && display.endsWith("|")) {
        display = display.substring(1, display.length() - 1) + "|";
      } else {
        display = display.substring(1);
      }
    }
    text(display, x + 8, y + h/2);
  }
  
  void handleMouse() {
    isFocused = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}
