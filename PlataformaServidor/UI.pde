// ===== UI COMPONENTS =====

class Button {
  float x, y, w, h;
  String label;
  color bgColor;
  boolean hovered;
  
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
    hovered = isMouseOver();
    fill(hovered ? active : normal);
    stroke(50);
    strokeWeight(1);
    rect(x, y, w, h, 4);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(label, x + w/2, y + h/2);
  }
  
  boolean isMouseOver() {
    return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
  
  boolean isClicked() {
    return isMouseOver();
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
    fill(isFocused ? color(255, 255, 240) : 255);
    stroke(isFocused ? color(50, 150, 255) : 180);
    strokeWeight(isFocused ? 2 : 1);
    rect(x, y, w, h, 3);
    fill(30);
    textAlign(LEFT, CENTER);
    textSize(12);
    String display = text;
    if (isFocused && frameCount / 20 % 2 == 0) {
      display += "|";
    }
    text(display, x + 5, y + h/2);
  }
  
  void handleMouse() {
    isFocused = mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
  }
}
