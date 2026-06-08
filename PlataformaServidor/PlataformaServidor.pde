import processing.net.*;
import processing.data.*;

// Network
Server server;
final int PORT = 5204;

// Data models
ArrayList<Workshop> workshops = new ArrayList<Workshop>();
ArrayList<Grade> grades = new ArrayList<Grade>();

// Connected students
ArrayList<Student> students = new ArrayList<Student>();
int nextClientId = 1;

// GUI state
String currentTab = "talleres";
int scrollOffset = 0;
int questionScrollOffset = 0;
String statusMessage = "";
int statusTimer = 0;

// Workshop editing state
int editingWorkshopIndex = -1;
String editingTitle = "";
String editingContent = "";   // Contenido de lectura del taller (texto de estudio)
ArrayList<Question> editingQuestions = new ArrayList<Question>();
String editingQuestionText = "";
int editingCorrect = 0;
int selectedQuestionIndex = -1;
int contentScrollOffset = 0;  // Scroll vertical para el contenido

// Historial state
ArrayList<String> histStudentKeys = new ArrayList<String>();
int selectedHistStudent = -1;
int selectedHistGrade = -1;
int histStudentScroll = 0;
int histGradeScroll = 0;

// UI controls
Button[] tabButtons;
Button btnNewWorkshop, btnSaveWorkshop, btnDeleteWorkshop;
Button btnAddQuestion, btnRemoveQuestion, btnMoveQuestionUp, btnMoveQuestionDown;
Button btnWorkshopListUp, btnWorkshopListDown;
Button btnGradeFilterAll, btnGradeFilterWorkshop;
Button btnHistStudentUp, btnHistStudentDown;
Button btnHistGradeUp, btnHistGradeDown;
TextField tfTitle;
TextField tfContent;       // Campo de contenido del taller (multi-línea)
TextField[] tfOptions = new TextField[4];
TextField tfQuestionText;
String gradeFilterWorkshop = "";
int selectedWorkshopIndex = -1;

void setup() {
  size(960, 650);
  surface.setTitle("Plataforma Educativa - Servidor");

  tabButtons = new Button[5];
  tabButtons[0] = new Button(10, 10, 110, 32, "Talleres");
  tabButtons[1] = new Button(130, 10, 120, 32, "Estudiantes");
  tabButtons[2] = new Button(260, 10, 100, 32, "Notas");
  tabButtons[3] = new Button(370, 10, 120, 32, "Enviar Taller");
  tabButtons[4] = new Button(500, 10, 120, 32, "Historial");

  int yb = 55;
  btnNewWorkshop = new Button(10, yb, 130, 26, "+ Nuevo Taller");
  btnSaveWorkshop = new Button(150, yb, 130, 26, "Guardar");
  btnDeleteWorkshop = new Button(290, yb, 130, 26, "Eliminar");
  btnWorkshopListUp = new Button(590, yb, 60, 26, "Subir");
  btnWorkshopListDown = new Button(660, yb, 70, 26, "Bajar");

  int qBtnY = 375;
  btnAddQuestion = new Button(245, qBtnY, 130, 26, "+ Agregar Pregunta");
  btnRemoveQuestion = new Button(385, qBtnY, 100, 26, "- Quitar");
  btnMoveQuestionUp = new Button(495, qBtnY, 60, 26, "Subir");
  btnMoveQuestionDown = new Button(565, qBtnY, 70, 26, "Bajar");

  yb = 55;
  btnGradeFilterAll = new Button(10, yb, 100, 26, "Todas");
  btnGradeFilterWorkshop = new Button(120, yb, 130, 26, "Por Taller");

  btnHistStudentUp = new Button(10, 470, 70, 26, "Subir");
  btnHistStudentDown = new Button(90, 470, 80, 26, "Bajar");
  btnHistGradeUp = new Button(500, 90, 60, 22, "Subir");
  btnHistGradeDown = new Button(570, 90, 70, 22, "Bajar");

  tfTitle = new TextField(245, 172, 400, 24);
  tfContent = new TextField(245, 220, 400, 75);  // Campo multi-línea para contenido
  tfQuestionText = new TextField(245, 400, 400, 24);
  for (int i = 0; i < 4; i++) {
    tfOptions[i] = new TextField(260, 455 + i * 26, 370, 22);
  }

  server = new Server(this, PORT);
  loadWorkshops();
  loadGrades();
  setStatus("Servidor iniciado en puerto " + PORT + " (" + workshops.size() + " talleres)");
}

void draw() {
  background(CREMA_FONDO);
  handleNetwork();
  drawTabs();
  drawContent();
  if (statusTimer > 0) {
    fill(0, 0, 0, 60);
    noStroke();
    rect(width/2 - 130, height - 32, 260, 24, 12);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(statusMessage, width/2, height - 20);
    statusTimer--;
  }
}

void drawTabs() {
  noStroke();
  fill(AZUL_ACCENTO);
  rect(0, 0, width, 50);
  for (int i = 0; i < tabButtons.length; i++) {
    boolean isActive = currentTab.equals(tabButtons[i].label.toLowerCase().replace(" ", ""));
    tabButtons[i].draw(isActive ? AZUL_OSCURO : color(255, 255, 255, 30), isActive ? color(20, 80, 140) : color(255, 255, 255, 60));
  }
}

void drawContent() {
  if (currentTab.equals("talleres")) drawTalleresTab();
  else if (currentTab.equals("estudiantes")) drawEstudiantesTab();
  else if (currentTab.equals("notas")) drawNotasTab();
  else if (currentTab.equals("enviartaller")) drawEnviarTab();
  else if (currentTab.equals("historial")) drawHistorialTab();
}

// ===== TAB: TALLERES =====

void drawTalleresTab() {
  int x1 = 10, y1 = 130, w1 = 220;
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(x1, y1, w1, height - y1 - 30, 6);

  fill(TEXTO_OSCURO);
  textAlign(LEFT, TOP);
  textSize(13);
  text("Talleres:", x1 + 5, y1 + 3);

  int ly = y1 + 22;
  int visibleCount = (height - y1 - 50) / 28;
  int maxScroll = max(0, workshops.size() - visibleCount);
  scrollOffset = constrain(scrollOffset, 0, maxScroll);

  for (int i = scrollOffset; i < workshops.size() && i < scrollOffset + visibleCount; i++) {
    int iy = ly + (i - scrollOffset) * 28;
    fill(i == selectedWorkshopIndex ? color(200, 230, 255) : 245);
    stroke(210);
    rect(x1 + 2, iy, w1 - 4, 26);
    fill(30);
    textAlign(LEFT, CENTER);
    text(workshops.get(i).title, x1 + 8, iy + 13);
  }

  int x2 = 240, y2 = 130;
  int ew = width - x2 - 10;
  int eh = height - y2 - 30;
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(x2, y2, ew, eh, 6);

  fill(AZUL_OSCURO);
  textAlign(LEFT, TOP);
  textSize(13);
  text("Editor de Taller:", x2 + 5, y2 + 3);

  textSize(12);
  text("Título:", x2 + 5, y2 + 25);
  tfTitle.draw();

  // === CONTENIDO DE LECTURA ===
  textSize(12);
  fill(TEXTO_OSCURO);
  text("Contenido del taller (texto de estudio):", x2 + 5, 198);
  fill(255, 255, 248);
  stroke(GRIS_BORDE);
  rect(x2 + 5, 208, ew - 10, 55, 4);
  fill(TEXTO_OSCURO);
  textSize(11);

  // Mostrar contenido con scroll si es necesario
  float contentW = ew - 20;
  float contentH = 45;
  textAlign(LEFT, TOP);
  String contentDisplay = editingContent;
  if (contentDisplay.length() == 0) contentDisplay = "Escribe aquí el contenido del taller...";
  fill(editingContent.length() == 0 ? color(160) : 30);

  // Renderizar contenido con word-wrap
  float lineH = 13;
  int maxLines = (int)(contentH / lineH);
  // Simple word wrap: split by words
  String[] words = split(contentDisplay, ' ');
  String wrapped = "";
  String currentLine = "";
  int linesOut = 0;
  int charsToShow = contentDisplay.length();

  // Mostrar texto visible según scroll
  int totalHeight = 0;
  String displayText = contentDisplay;
  // Calcular aprox cuantas líneas podemos mostrar
  int shown = 0;
  int maxChars = contentDisplay.length();
  // Recortar por scroll
  int startChar = 0;
  int curChar = 0;
  int lineCount = 0;
  int skipLines = contentScrollOffset;
  String renderStr = "";

  for (int ci = 0; ci <= contentDisplay.length(); ci++) {
    char ch = ci < contentDisplay.length() ? contentDisplay.charAt(ci) : ' ';
    if (ch == '\n' || ci == contentDisplay.length()) {
      lineCount++;
      if (lineCount > skipLines && skipLines + (int)(contentH / lineH) >= lineCount) {
        String line = contentDisplay.substring(startChar, ci);
        text(line, x2 + 8, 210 + (lineCount - skipLines - 1) * lineH);
      }
      startChar = ci + 1;
    }
  }

  // Línea de cursor si está enfocado
  if (tfContent.isFocused && frameCount / 15 % 2 == 0) {
    fill(50, 150, 255);
    float cx = x2 + 8 + textWidth(contentDisplay.substring(max(0, contentDisplay.length() - 1)));
    float cy = 210 + ((lineCount - skipLines) * lineH);
    rect(cx, cy, 8, lineH - 2);
  }

  // === PREGUNTAS ===
  fill(TEXTO_OSCURO);
  textSize(12);
  text("Preguntas (" + editingQuestions.size() + "):", x2 + 5, 270);

  int qy = 285;
  int qh = 80;
  fill(255, 255, 248);
  stroke(GRIS_BORDE);
  rect(x2 + 5, qy, ew - 10, qh, 4);

  int qVisible = qh / 28;
  int qMaxScroll = max(0, editingQuestions.size() - qVisible);
  questionScrollOffset = constrain(questionScrollOffset, 0, qMaxScroll);

  for (int i = questionScrollOffset; i < editingQuestions.size() && i < questionScrollOffset + qVisible; i++) {
    int iy = qy + (i - questionScrollOffset) * 28;
    fill(i == selectedQuestionIndex ? color(200, 230, 255) : 245);
    stroke(210);
    rect(x2 + 7, iy, ew - 14, 26);
    fill(30);
    textAlign(LEFT, CENTER);
    String qLabel = (i + 1) + ". " + editingQuestions.get(i).text;
    if (textWidth(qLabel) > ew - 20) {
      qLabel = qLabel.substring(0, min(qLabel.length(), 40)) + "...";
    }
    text(qLabel, x2 + 12, iy + 13);
  }

  int qeY = 410;
  fill(50);
  textSize(12);
  text("Texto de la pregunta:", x2 + 5, qeY);
  tfQuestionText.draw();

  fill(50);
  text("Opciones (marca la correcta):", x2 + 5, qeY + 32);
  for (int i = 0; i < 4; i++) {
    fill(50);
    textSize(11);
    String optLabel = (char)('A' + i) + ")";
    text(optLabel, x2 + 5, 455 + i * 26);
    tfOptions[i].draw();
    float rx = 645;
    float ry = 450 + i * 26;
    stroke(100);
    fill(editingCorrect == i ? color(50, 150, 50) : color(220));
    ellipse(rx, ry + 10, 14, 14);
    if (editingCorrect == i) {
      fill(255);
      ellipse(rx, ry + 10, 6, 6);
    }
  }
}

// ===== TAB: ESTUDIANTES =====

void drawEstudiantesTab() {
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(10, 55, width - 20, height - 70, 8);

  // Contar cuántos están realmente conectados
  int connectedCount = 0;
  for (Student s : students) {
    if (s.connected && s.client != null && s.client.active()) connectedCount++;
  }

  fill(TEXTO_OSCURO);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Estudiantes", 20, 60);

  fill(AZUL_ACCENTO);
  textSize(13);
  text("🟢 " + connectedCount + " conectados", 20, 80);
  fill(120);
  text("(" + students.size() + " en total)", 150, 80);

  int y = 105;
  int[] cols = {30, 60, 70, 180, 120, 100, 80};
  String[] headers = {"#", "Grado", "Nro", "Nombre", "IP", "ID", "Estado"};

  int xp = 20;
  for (int c = 0; c < headers.length; c++) {
    fill(AZUL_ACCENTO);
    textSize(12);
    textAlign(LEFT, TOP);
    text(headers[c], xp, y);
    xp += cols[c];
  }

  y += 25;
  for (int i = 0; i < students.size(); i++) {
    Student s = students.get(i);
    int rowY = y + i * 26;
    if (rowY > height - 30) break;

    // Fondo alternado
    fill(i % 2 == 0 ? CREMA_FONDO : BLANCO_TARJETA);
    noStroke();
    rect(11, rowY, width - 22, 25);

    // Indicador circular de estado
    boolean active = s.connected && s.client != null && s.client.active();
    int dotX = 15;
    int dotY = rowY + 7;
    if (active) {
      fill(#27AE60);  // verde
    } else {
      fill(#E74C3C);  // rojo
    }
    noStroke();
    ellipse(dotX, dotY, 10, 10);

    fill(TEXTO_OSCURO);
    textSize(12);
    xp = 20;
    textAlign(LEFT, TOP);
    text((i+1), xp, rowY + 4); xp += cols[0];
    text(s.grado, xp, rowY + 4); xp += cols[1];
    text(str(s.numero), xp, rowY + 4); xp += cols[2];
    text(s.nombre, xp, rowY + 4); xp += cols[3];
    text(s.ip, xp, rowY + 4); xp += cols[4];
    text(str(s.id), xp, rowY + 4); xp += cols[5];
    if (active) {
      fill(#27AE60);
      text("Conectado", xp, rowY + 4);
    } else {
      fill(#E74C3C);
      text("Desconectado", xp, rowY + 4);
    }
  }
}

// ===== TAB: NOTAS =====

void drawNotasTab() {
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(10, 90, width - 20, height - 105, 8);

  fill(TEXTO_OSCURO);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Notas de Alumnos", 20, 60);

  btnGradeFilterAll.draw();
  btnGradeFilterWorkshop.draw();

  int y = 95;
  int[] cols = {30, 60, 50, 140, 160, 60, 60};
  String[] headers = {"#", "Grado", "Nro", "Nombre", "Taller", "Nota", "Total"};

  fill(AZUL_ACCENTO);
  textSize(12);
  textAlign(LEFT, TOP);
  int xp = 20;
  for (int c = 0; c < headers.length; c++) {
    text(headers[c], xp, y);
    xp += cols[c];
  }

  y += 25;
  int displayCount = 0;
  for (int i = 0; i < grades.size(); i++) {
    Grade g = grades.get(i);
    if (gradeFilterWorkshop.length() > 0 && !g.workshopTitle.equals(gradeFilterWorkshop)) continue;
    int rowY = y + displayCount * 24;
    if (rowY > height - 30) break;
    fill(displayCount % 2 == 0 ? CREMA_FONDO : BLANCO_TARJETA);
    noStroke();
    rect(11, rowY, width - 22, 23);
    fill(TEXTO_OSCURO);
    textSize(12);
    xp = 20;
    text((displayCount+1), xp, rowY + 4); xp += cols[0];
    text(g.grado, xp, rowY + 4); xp += cols[1];
    text(str(g.numero), xp, rowY + 4); xp += cols[2];
    text(g.nombre, xp, rowY + 4); xp += cols[3];
    text(g.workshopTitle, xp, rowY + 4); xp += cols[4];
    text(str(g.score), xp, rowY + 4); xp += cols[5];
    text(str(g.total), xp, rowY + 4);
    displayCount++;
  }
}

// ===== TAB: ENVIAR TALLER =====

void drawEnviarTab() {
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(10, 55, width - 20, height - 70, 8);

  fill(TEXTO_OSCURO);
  textAlign(LEFT, TOP);
  textSize(16);
  text("Enviar Taller a Alumnos", 20, 60);

  textSize(13);
  text("Selecciona un taller de la lista y presiona Enviar:", 20, 90);

  int y = 120;
  for (int i = 0; i < workshops.size(); i++) {
    int rowY = y + i * 32;
    if (rowY > height - 60) break;
    fill(i == selectedWorkshopIndex ? color(200, 230, 255) : 245);
    stroke(200);
    rect(20, rowY, 300, 28);
    fill(30);
    textAlign(LEFT, CENTER);
    text(workshops.get(i).title + " (" + workshops.get(i).questions.size() + " preg.)", 28, rowY + 14);
  }

  if (selectedWorkshopIndex >= 0 && selectedWorkshopIndex < workshops.size()) {
    fill(50);
    textAlign(LEFT, TOP);
    text("Alumnos que recibirán el taller:", 350, 90);
    int sy = 120;
    for (int i = 0; i < students.size(); i++) {
      if (!students.get(i).connected) continue;
      fill(245);
      stroke(200);
      rect(350, sy + i * 28, 240, 24);
      fill(30);
      textAlign(LEFT, CENTER);
      text(students.get(i).grado + " - #" + students.get(i).numero + " - " + students.get(i).nombre, 358, sy + i * 28 + 12);
    }
    boolean hoverSend = mouseX >= 620 && mouseX <= 760 && mouseY >= 90 && mouseY <= 122;
    noStroke();
    fill(0, 0, 0, 15);
    rect(621, 92, 140, 32, 16);
    fill(hoverSend ? AZUL_OSCURO : AZUL_ACCENTO);
    rect(620, 90, 140, 32, 16);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(13);
    text("Enviar a Alumnos", 690, 106);
  }
}

// ===== TAB: HISTORIAL =====

void drawHistorialTab() {
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  rect(10, 55, 300, height - 70, 8);

  fill(TEXTO_OSCURO);
  textAlign(LEFT, TOP);
  textSize(14);
  text("Alumnos con pruebas:", 20, 60);

  rebuildHistStudentList();

  int ly = 85;
  int visibleCount = (height - 85 - 80) / 26;
  histStudentScroll = constrain(histStudentScroll, 0, max(0, histStudentKeys.size() - visibleCount));

  for (int i = histStudentScroll; i < histStudentKeys.size() && i < histStudentScroll + visibleCount; i++) {
    int rowY = ly + (i - histStudentScroll) * 26;
    fill(i == selectedHistStudent ? color(200, 230, 255) : 245);
    stroke(210);
    rect(15, rowY, 290, 24);
    fill(30);
    textAlign(LEFT, CENTER);
    textSize(12);
    String parts[] = split(histStudentKeys.get(i), "|");
    String g = parts.length > 0 ? parts[0] : "";
    int n = parts.length > 1 ? int(parts[1]) : 0;
    String nom = parts.length > 2 ? parts[2] : "";
    text(g + " - #" + n + " - " + nom, 22, rowY + 12);
  }

  // Scroll indicators for student list
  if (histStudentScroll > 0) {
    fill(100); textAlign(CENTER, BOTTOM); textSize(16); text("\u25B2", 145, 82);
  }
  if (histStudentScroll + visibleCount < histStudentKeys.size()) {
    fill(100); textAlign(CENTER, TOP); textSize(16); text("\u25BC", 145, height - 15);
  }

  // Right panel: selected student's history
  if (selectedHistStudent >= 0 && selectedHistStudent < histStudentKeys.size()) {
    String key = histStudentKeys.get(selectedHistStudent);
    String parts[] = split(key, "|");
    String sgrado = parts.length > 0 ? parts[0] : "";
    int snumero = parts.length > 1 ? int(parts[1]) : 0;
    String snombre = parts.length > 2 ? parts[2] : "";

    IntList gradeIndices = new IntList();
    for (int i = 0; i < grades.size(); i++) {
      Grade g = grades.get(i);
      if (g.grado.equals(sgrado) && g.numero == snumero && g.nombre.equals(snombre))
        gradeIndices.append(i);
    }

    fill(BLANCO_TARJETA);
    stroke(GRIS_BORDE);
    rect(320, 55, width - 330, height - 70, 8);

    fill(TEXTO_OSCURO);
    textAlign(LEFT, TOP);
    textSize(15);
    text("Historial de: " + sgrado + " - #" + snumero + " - " + snombre, 330, 60);

    textSize(12);
    fill(100);
    text("Intentos: " + gradeIndices.size(), 330, 82);

    int visibleGrades = (height - 130) / 28;
    histGradeScroll = constrain(histGradeScroll, 0, max(0, gradeIndices.size() - visibleGrades));

    int hgy = 105;
    int[] hcols = {140, 60, 60, 60};
    String[] hheaders = {"Taller", "Nota", "Total", "%"};
    int hxp = 330;
    for (int c = 0; c < hheaders.length; c++) {
      fill(60); textSize(12); textAlign(LEFT, TOP);
      text(hheaders[c], hxp, hgy);
      hxp += hcols[c];
    }

    hgy += 22;
    for (int gi = histGradeScroll; gi < gradeIndices.size() && gi < histGradeScroll + visibleGrades; gi++) {
      int idx = gradeIndices.get(gi);
      Grade gd = grades.get(idx);
      int rowY = hgy + (gi - histGradeScroll) * 28;
      fill(gi == selectedHistGrade ? color(220, 240, 255) : (gi % 2 == 0 ? 245 : 255));
      noStroke();
      rect(321, rowY, width - 332, 26);
      fill(30);
      textSize(12);
      hxp = 330;
      text(gd.workshopTitle, hxp, rowY + 6); hxp += hcols[0];
      text(str(gd.score), hxp, rowY + 6); hxp += hcols[1];
      text(str(gd.total), hxp, rowY + 6); hxp += hcols[2];
      int pct = gd.total > 0 ? gd.score * 100 / gd.total : 0;
      text(pct + "%", hxp, rowY + 6);
    }

    // Grade detail
    if (selectedHistGrade >= 0 && selectedHistGrade < gradeIndices.size()) {
      Grade gd = grades.get(gradeIndices.get(selectedHistGrade));
      Workshop ws = findWorkshop(gd.workshopTitle);
      int detailY = max(hgy + min(gradeIndices.size() - histGradeScroll, visibleGrades) * 28 + 10, 250);
      fill(250);
      stroke(200);
      rect(330, detailY, width - 350, height - detailY - 30);

      fill(50);
      textAlign(LEFT, TOP);
      textSize(12);
      text("Detalle de respuestas:", 340, detailY + 5);

      if (ws != null && gd.answers != null) {
        for (int qi = 0; qi < ws.questions.size() && qi < gd.answers.length; qi++) {
          int rowY2 = detailY + 25 + qi * 24;
          if (rowY2 > height - 40) break;
          boolean correct = gd.answers[qi] == ws.questions.get(qi).correctIndex;
          fill(correct ? color(220, 255, 220) : color(255, 220, 220));
          noStroke();
          rect(332, rowY2, width - 354, 22);
          fill(correct ? color(30, 120, 30) : color(180, 30, 30));
          textSize(11);
          textAlign(LEFT, CENTER);
          String icon = correct ? "\u2713" : "\u2717";
          String ansText = gd.answers[qi] >= 0 && gd.answers[qi] < ws.questions.get(qi).options.length
            ? ws.questions.get(qi).options[gd.answers[qi]] : "N/A";
          text(icon + " P" + (qi+1) + ": " + ws.questions.get(qi).text + "  (" + ansText + ")", 340, rowY2 + 11);
        }
      }
    }
  }
}

void rebuildHistStudentList() {
  histStudentKeys.clear();
  // Build unique student list from grades
  for (int i = 0; i < grades.size(); i++) {
    Grade g = grades.get(i);
    String key = g.grado + "|" + g.numero + "|" + g.nombre;
    boolean found = false;
    for (String k : histStudentKeys) {
      if (k.equals(key)) { found = true; break; }
    }
    if (!found) histStudentKeys.add(key);
  }
}

// ===== NETWORKING =====

void handleNetwork() {
  // Procesar TODOS los mensajes pendientes de TODOS los clientes
  int maxIter = 100; // seguridad anti-bucle infinito
  Client c = server.available();
  while (c != null && maxIter > 0) {
    maxIter--;
    String msg = c.readStringUntil('\n');
    if (msg != null) {
      msg = msg.trim();
      if (msg.length() > 0) processMessage(c, msg);
    }
    c = server.available();
  }

  // Eliminar estudiantes que se desconectaron abruptamente
  for (int i = students.size() - 1; i >= 0; i--) {
    Student s = students.get(i);
    if (s.client != null && !s.client.active()) {
      setStatus(s.nombre + " (" + s.grado + " - #" + s.numero + ") se ha desconectado");
      students.remove(i);
    }
  }
}

void processMessage(Client c, String msg) {
  try {
    JSONObject json = JSONObject.parse(msg);
    String type = json.getString("type", "");

    if (type.equals("connect")) {
      String nombre = json.getString("nombre", "Desconocido");
      String grado = json.getString("grado", "");
      int numero = json.getInt("numero", 0);

      // Buscar si ya existe (reconexión)
      Student s = findStudent(grado, numero, nombre);
      boolean isReconnect = (s != null);
      if (s == null) {
        s = new Student();
        students.add(s);
      }
      s.nombre = nombre;
      s.grado = grado;
      s.numero = numero;
      s.ip = c.ip();
      s.client = c;
      s.connected = true;
      if (!isReconnect) s.id = nextClientId++;

      JSONObject response = new JSONObject();
      response.setString("type", "connected");
      response.setInt("id", s.id);
      response.setString("nombre", s.nombre);
      c.write(response.toString() + "\n");
      setStatus((isReconnect ? "Reconectado" : "Alumno conectado") + ": " + grado + " - #" + numero + " - " + nombre);

      // Enviar automáticamente talleres al alumno (escapando \\n para TCP)
      JSONArray wList = new JSONArray();
      JSONArray cList = new JSONArray();
      JSONArray qCountList = new JSONArray();
      for (int i = 0; i < workshops.size(); i++) {
        wList.setString(i, workshops.get(i).title);
        cList.setString(i, workshops.get(i).content.replace("\n", "[nl]").replace("\r", ""));
        qCountList.setInt(i, workshops.get(i).questions.size());
      }
      JSONObject wsMsg = new JSONObject();
      wsMsg.setString("type", "workshop_list");
      wsMsg.setJSONArray("workshops", wList);
      wsMsg.setJSONArray("contents", cList);
      wsMsg.setJSONArray("questionCounts", qCountList);
      c.write(wsMsg.toString() + "\n");

    } else if (type.equals("list_workshops")) {
      JSONArray wList = new JSONArray();
      JSONArray cList = new JSONArray();
      JSONArray qCountList = new JSONArray();
      for (int i = 0; i < workshops.size(); i++) {
        wList.setString(i, workshops.get(i).title);
        // Escapar saltos de línea para no romper protocolo TCP
        cList.setString(i, workshops.get(i).content.replace("\n", "[nl]").replace("\r", ""));
        qCountList.setInt(i, workshops.get(i).questions.size());
      }
      JSONObject response = new JSONObject();
      response.setString("type", "workshop_list");
      response.setJSONArray("workshops", wList);
      response.setJSONArray("contents", cList);
      response.setJSONArray("questionCounts", qCountList);
      c.write(response.toString() + "\n");

    } else if (type.equals("request_quiz")) {
      String wTitle = json.getString("workshop", "");
      Workshop ws = findWorkshop(wTitle);
      if (ws != null) {
        JSONArray qArr = new JSONArray();
        for (int i = 0; i < ws.questions.size(); i++) {
          Question q = ws.questions.get(i);
          JSONObject qObj = new JSONObject();
          qObj.setString("text", q.text);
          JSONArray optArr = new JSONArray();
          for (int j = 0; j < q.options.length; j++) {
            optArr.setString(j, q.options[j]);
          }
          qObj.setJSONArray("options", optArr);
          qArr.setJSONObject(i, qObj);
        }
        JSONObject response = new JSONObject();
        response.setString("type", "quiz_data");
        response.setString("workshop", ws.title);
        response.setString("content", ws.content.replace("\n", "[nl]").replace("\r", ""));  // Contenido de estudio
        response.setJSONArray("questions", qArr);
        c.write(response.toString() + "\n");
      }

    } else if (type.equals("submit_answers")) {
      String wTitle = json.getString("workshop", "");
      JSONArray ansArr = json.getJSONArray("answers");
      Workshop ws = findWorkshop(wTitle);
      if (ws != null && ansArr != null) {
        int score = 0;
        int total = ws.questions.size();
        JSONArray resultsArr = new JSONArray();
        for (int i = 0; i < total && i < ansArr.size(); i++) {
          int studentAns = ansArr.getInt(i);
          boolean correct = (studentAns == ws.questions.get(i).correctIndex);
          resultsArr.setBoolean(i, correct);
          if (correct) score++;
        }

        String nombre = "", grado = "";
        int numero = 0;
        for (Student s : students) {
          if (s.client == c) {
            nombre = s.nombre; grado = s.grado; numero = s.numero;
            break;
          }
        }

        Grade gd = new Grade();
        gd.nombre = nombre;
        gd.grado = grado;
        gd.numero = numero;
        gd.workshopTitle = wTitle;
        gd.score = score;
        gd.total = total;
        gd.timestamp = System.currentTimeMillis();
        gd.answers = new int[ansArr.size()];
        for (int i = 0; i < ansArr.size(); i++) gd.answers[i] = ansArr.getInt(i);
        grades.add(gd);
        saveGrades();

        JSONObject response = new JSONObject();
        response.setString("type", "quiz_result");
        response.setString("workshop", wTitle);
        response.setInt("score", score);
        response.setInt("total", total);
        response.setJSONArray("results", resultsArr);
        c.write(response.toString() + "\n");

        setStatus(nombre + " (" + grado + " - #" + numero + ") obtuvo " + score + "/" + total + " en '" + wTitle + "'");
      }
    }
  } catch (Exception e) {
    println("Error parsing message: " + e.getMessage());
  }
}

void sendWorkshopToAll(int workshopIndex) {
  if (workshopIndex < 0 || workshopIndex >= workshops.size()) return;
  Workshop ws = workshops.get(workshopIndex);

  JSONArray qArr = new JSONArray();
  for (int i = 0; i < ws.questions.size(); i++) {
    Question q = ws.questions.get(i);
    JSONObject qObj = new JSONObject();
    qObj.setString("text", q.text);
    JSONArray optArr = new JSONArray();
    for (int j = 0; j < q.options.length; j++) {
      optArr.setString(j, q.options[j]);
    }
    qObj.setJSONArray("options", optArr);
    qArr.setJSONObject(i, qObj);
  }

  JSONObject msg = new JSONObject();
  msg.setString("type", "quiz_data");
  msg.setString("workshop", ws.title);
  msg.setString("content", ws.content.replace("\n", "[nl]").replace("\r", ""));  // Contenido de estudio
  msg.setJSONArray("questions", qArr);
  String msgStr = msg.toString() + "\n";

  int sentCount = 0;
  for (Student s : students) {
    if (s.connected && s.client != null && s.client.active()) {
      s.client.write(msgStr);
      sentCount++;
    }
  }
  setStatus("Taller '" + ws.title + "' enviado a " + sentCount + " alumnos");
}

// ===== DATA PERSISTENCE =====

// Busca un estudiante por grado, número y nombre (para reconexión)
Student findStudent(String grado, int numero, String nombre) {
  for (Student s : students) {
    if (s.grado.equals(grado) && s.numero == numero && s.nombre.equals(nombre)) {
      return s;
    }
  }
  return null;
}

void loadWorkshops() {
  workshops.clear();
  try {
    String[] lines = loadStrings("data/workshops.json");
    if (lines != null) {
      String json = join(lines, "\n");
      JSONObject data = JSONObject.parse(json);
      JSONArray arr = data.getJSONArray("workshops");
      for (int i = 0; i < arr.size(); i++) {
        JSONObject wObj = arr.getJSONObject(i);
        Workshop w = new Workshop();
        w.title = wObj.getString("title");
        w.content = wObj.getString("content", "");  // Cargar contenido
        // Las preguntas son opcionales (taller solo lectura)
        if (wObj.hasKey("questions")) {
          JSONArray qArr = wObj.getJSONArray("questions");
          for (int j = 0; j < qArr.size(); j++) {
            JSONObject qObj = qArr.getJSONObject(j);
            Question q = new Question();
            q.text = qObj.getString("text");
            q.correctIndex = qObj.getInt("correctIndex", 0);
            JSONArray optArr = qObj.getJSONArray("options");
            q.options = new String[optArr.size()];
            for (int k = 0; k < optArr.size(); k++) q.options[k] = optArr.getString(k);
            w.questions.add(q);
          }
        }
        workshops.add(w);
      }
    }
  } catch (Exception e) {
    println("No se pudieron cargar talleres: " + e.getMessage());
  }
}

void saveWorkshopsToFile() {
  JSONArray wArr = new JSONArray();
  for (int i = 0; i < workshops.size(); i++) {
    Workshop w = workshops.get(i);
    JSONObject wObj = new JSONObject();
    wObj.setString("title", w.title);
    wObj.setString("content", w.content);  // Guardar contenido
    JSONArray qArr = new JSONArray();
    for (int j = 0; j < w.questions.size(); j++) {
      Question q = w.questions.get(j);
      JSONObject qObj = new JSONObject();
      qObj.setString("text", q.text);
      qObj.setInt("correctIndex", q.correctIndex);
      JSONArray optArr = new JSONArray();
      for (int k = 0; k < q.options.length; k++) optArr.setString(k, q.options[k]);
      qObj.setJSONArray("options", optArr);
      qArr.setJSONObject(j, qObj);
    }
    wObj.setJSONArray("questions", qArr);
    wArr.setJSONObject(i, wObj);
  }
  JSONObject data = new JSONObject();
  data.setJSONArray("workshops", wArr);
  saveJSONObject(data, "data/workshops.json");
}

void loadGrades() {
  grades.clear();
  try {
    String[] lines = loadStrings("data/grades.json");
    if (lines != null) {
      String json = join(lines, "\n");
      JSONObject data = JSONObject.parse(json);
      JSONArray arr = data.getJSONArray("grades");
      for (int i = 0; i < arr.size(); i++) {
        JSONObject gObj = arr.getJSONObject(i);
        Grade gd = new Grade();
        gd.nombre = gObj.getString("nombre", "");
        gd.grado = gObj.getString("grado", "");
        gd.numero = gObj.getInt("numero", 0);
        gd.workshopTitle = gObj.getString("workshopTitle", "");
        gd.score = gObj.getInt("score", 0);
        gd.total = gObj.getInt("total", 0);
        gd.timestamp = gObj.getLong("timestamp", 0L);
        JSONArray aArr = gObj.getJSONArray("answers");
        if (aArr != null) {
          gd.answers = new int[aArr.size()];
          for (int j = 0; j < aArr.size(); j++) gd.answers[j] = aArr.getInt(j);
        }
        grades.add(gd);
      }
    }
  } catch (Exception e) {
    println("No se pudieron cargar notas: " + e.getMessage());
  }
}

void saveGrades() {
  JSONArray gArr = new JSONArray();
  for (int i = 0; i < grades.size(); i++) {
    Grade gd = grades.get(i);
    JSONObject gObj = new JSONObject();
    gObj.setString("nombre", gd.nombre);
    gObj.setString("grado", gd.grado);
    gObj.setInt("numero", gd.numero);
    gObj.setString("workshopTitle", gd.workshopTitle);
    gObj.setInt("score", gd.score);
    gObj.setInt("total", gd.total);
    gObj.setLong("timestamp", gd.timestamp);
    JSONArray aArr = new JSONArray();
    if (gd.answers != null) {
      for (int j = 0; j < gd.answers.length; j++) aArr.setInt(j, gd.answers[j]);
    }
    gObj.setJSONArray("answers", aArr);
    gArr.setJSONObject(i, gObj);
  }
  JSONObject data = new JSONObject();
  data.setJSONArray("grades", gArr);
  saveJSONObject(data, "data/grades.json");
}

// ===== HELPERS =====

Workshop findWorkshop(String title) {
  for (Workshop w : workshops) {
    if (w.title.equals(title)) return w;
  }
  return null;
}

void setStatus(String msg) {
  statusMessage = msg;
  statusTimer = 300;
  println(msg);
}

// ===== MOUSE =====

void mousePressed() {
  for (int i = 0; i < tabButtons.length; i++) {
    if (tabButtons[i].isMouseOver()) {
      currentTab = tabButtons[i].label.toLowerCase().replace(" ", "");
      return;
    }
  }

  if (currentTab.equals("talleres")) handleTalleresMouse();
  else if (currentTab.equals("notas")) handleNotasMouse();
  else if (currentTab.equals("enviartaller")) handleEnviarMouse();
  else if (currentTab.equals("historial")) handleHistorialMouse();

  tfTitle.handleMouse();
  tfQuestionText.handleMouse();
  for (int i = 0; i < 4; i++) tfOptions[i].handleMouse();
}

void handleTalleresMouse() {
  int ly = 152;
  int visibleCount = (height - 152 - 30) / 28;
  for (int i = scrollOffset; i < workshops.size() && i < scrollOffset + visibleCount; i++) {
    int iy = ly + (i - scrollOffset) * 28;
    if (mouseX >= 12 && mouseX <= 232 && mouseY >= iy && mouseY <= iy + 26) {
      selectWorkshop(i); return;
    }
  }

  // Click en área de contenido para enfocar el TextField
  if (mouseX >= 245 && mouseX <= 645 && mouseY >= 208 && mouseY <= 263) {
    tfContent.isFocused = true;
    tfTitle.isFocused = false;
    tfQuestionText.isFocused = false;
    for (int i = 0; i < 4; i++) tfOptions[i].isFocused = false;
    return;
  }

  int qy = 285, qh = 80;
  int qVisible = qh / 28;
  for (int i = questionScrollOffset; i < editingQuestions.size() && i < questionScrollOffset + qVisible; i++) {
    int iy = qy + (i - questionScrollOffset) * 28;
    if (mouseX >= 245 && mouseX <= 665 && mouseY >= iy && mouseY <= iy + 26) {
      selectedQuestionIndex = i; loadQuestionIntoEditor(i); return;
    }
  }

  for (int i = 0; i < 4; i++) {
    float rx = 645, ry = 450 + i * 26;
    if (dist(mouseX, mouseY, rx, ry + 10) < 10) {
      editingCorrect = i; updateCurrentQuestionCorrect(); return;
    }
  }

  if (btnNewWorkshop.isMouseOver()) { newWorkshop(); }
  else if (btnSaveWorkshop.isMouseOver() && editingTitle.length() > 0) { saveCurrentWorkshop(); }
  else if (btnDeleteWorkshop.isMouseOver() && selectedWorkshopIndex >= 0) { deleteCurrentWorkshop(); }
  else if (btnAddQuestion.isMouseOver()) { addQuestion(); }
  else if (btnRemoveQuestion.isMouseOver() && selectedQuestionIndex >= 0) { removeQuestion(); }
  else if (btnMoveQuestionUp.isMouseOver() && selectedQuestionIndex > 0) { moveQuestion(-1); }
  else if (btnMoveQuestionDown.isMouseOver() && selectedQuestionIndex >= 0 && selectedQuestionIndex < editingQuestions.size() - 1) { moveQuestion(1); }
  else if (btnWorkshopListUp.isMouseOver()) { scrollOffset = max(0, scrollOffset - 1); }
  else if (btnWorkshopListDown.isMouseOver()) { scrollOffset++; }
}

void handleNotasMouse() {
  if (btnGradeFilterAll.isMouseOver()) gradeFilterWorkshop = "";
  else if (btnGradeFilterWorkshop.isMouseOver()) {
    if (selectedWorkshopIndex >= 0 && selectedWorkshopIndex < workshops.size())
      gradeFilterWorkshop = workshops.get(selectedWorkshopIndex).title;
  }
}

void handleEnviarMouse() {
  int y = 120;
  for (int i = 0; i < workshops.size(); i++) {
    int rowY = y + i * 32;
    if (mouseX >= 20 && mouseX <= 320 && mouseY >= rowY && mouseY <= rowY + 28) {
      selectedWorkshopIndex = i; return;
    }
  }
  if (mouseX >= 620 && mouseX <= 760 && mouseY >= 90 && mouseY <= 122 && selectedWorkshopIndex >= 0) {
    sendWorkshopToAll(selectedWorkshopIndex);
  }
}

void handleHistorialMouse() {
  int ly = 85;
  int visibleCount = (height - 85 - 80) / 26;

  // Student list click
  for (int i = histStudentScroll; i < histStudentKeys.size() && i < histStudentScroll + visibleCount; i++) {
    int rowY = ly + (i - histStudentScroll) * 26;
    if (mouseX >= 15 && mouseX <= 305 && mouseY >= rowY && mouseY <= rowY + 24) {
      selectedHistStudent = i;
      selectedHistGrade = -1;
      return;
    }
  }

  if (selectedHistStudent < 0 || selectedHistStudent >= histStudentKeys.size()) return;

  String key = histStudentKeys.get(selectedHistStudent);
  String parts[] = split(key, "|");
  String sgrado = parts.length > 0 ? parts[0] : "";
  int snumero = parts.length > 1 ? int(parts[1]) : 0;
  String snombre = parts.length > 2 ? parts[2] : "";

  IntList gradeIndices = new IntList();
  for (int i = 0; i < grades.size(); i++) {
    Grade g = grades.get(i);
    if (g.grado.equals(sgrado) && g.numero == snumero && g.nombre.equals(snombre))
      gradeIndices.append(i);
  }

  int visibleGrades = (height - 130) / 28;
  int hgy = 127;

  // Grade list click
  for (int gi = histGradeScroll; gi < gradeIndices.size() && gi < histGradeScroll + visibleGrades; gi++) {
    int rowY = hgy + (gi - histGradeScroll) * 28;
    if (mouseX >= 321 && mouseX <= width - 12 && mouseY >= rowY && mouseY <= rowY + 26) {
      selectedHistGrade = gi;
      return;
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if (currentTab.equals("talleres")) {
    if (mouseX >= 12 && mouseX <= 232) {
      scrollOffset += (int)e;
    } else if (mouseX >= 245 && mouseX <= 665 && mouseY >= 208 && mouseY <= 263) {
      // Scroll del contenido de lectura
      contentScrollOffset = max(0, contentScrollOffset + (int)e);
    } else if (mouseX >= 245 && mouseX <= 665 && mouseY >= 285 && mouseY <= 365) {
      questionScrollOffset += (int)e;
    }
  } else if (currentTab.equals("historial")) {
    if (mouseX >= 15 && mouseX <= 305) {
      histStudentScroll += (int)e;
    } else if (mouseX > 320) {
      histGradeScroll += (int)e;
    }
  }
}

// ===== KEYBOARD =====

void keyPressed() {
  if (tfTitle.isFocused) {
    if (key == BACKSPACE && tfTitle.text.length() > 0) tfTitle.text = tfTitle.text.substring(0, tfTitle.text.length() - 1);
    else if (key != BACKSPACE && key != TAB && key != ENTER && key != RETURN && key != CODED) tfTitle.text += key;
    editingTitle = tfTitle.text;
    return;
  }
  if (tfContent.isFocused) {
    // Contenido multi-línea: Enter agrega salto de línea
    if (key == BACKSPACE && tfContent.text.length() > 0) {
      tfContent.text = tfContent.text.substring(0, tfContent.text.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      tfContent.text += '\n';
    } else if (key != BACKSPACE && key != TAB && key != ENTER && key != RETURN && key != CODED) {
      tfContent.text += key;
    }
    editingContent = tfContent.text;
    return;
  }
  if (tfQuestionText.isFocused) {
    if (key == BACKSPACE && tfQuestionText.text.length() > 0) tfQuestionText.text = tfQuestionText.text.substring(0, tfQuestionText.text.length() - 1);
    else if (key != BACKSPACE && key != TAB && key != ENTER && key != RETURN && key != CODED) tfQuestionText.text += key;
    return;
  }
  for (int i = 0; i < 4; i++) {
    if (tfOptions[i].isFocused) {
      if (key == BACKSPACE && tfOptions[i].text.length() > 0) tfOptions[i].text = tfOptions[i].text.substring(0, tfOptions[i].text.length() - 1);
      else if (key != BACKSPACE && key != TAB && key != ENTER && key != RETURN && key != CODED) tfOptions[i].text += key;
      if (selectedQuestionIndex >= 0 && selectedQuestionIndex < editingQuestions.size()) {
        editingQuestions.get(selectedQuestionIndex).options[i] = tfOptions[i].text;
      }
      return;
    }
  }
}

// ===== WORKSHOP EDITING HELPERS =====

void selectWorkshop(int index) {
  selectedWorkshopIndex = index;
  editingWorkshopIndex = index;
  Workshop w = workshops.get(index);
  editingTitle = w.title;
  editingContent = w.content;
  tfTitle.text = w.title;
  tfContent.text = w.content;
  editingQuestions = new ArrayList<Question>();
  for (Question q : w.questions) {
    Question copy = new Question();
    copy.text = q.text; copy.correctIndex = q.correctIndex; copy.options = q.options.clone();
    editingQuestions.add(copy);
  }
  selectedQuestionIndex = -1;
  editingQuestionText = "";
  editingCorrect = 0;
  tfQuestionText.text = "";
  for (int i = 0; i < 4; i++) tfOptions[i].text = "";
  contentScrollOffset = 0;
}

void newWorkshop() {
  editingWorkshopIndex = -1;
  selectedWorkshopIndex = -1;
  editingTitle = "Nuevo Taller";
  editingContent = "";
  tfTitle.text = "Nuevo Taller";
  tfContent.text = "";
  editingQuestions = new ArrayList<Question>();
  selectedQuestionIndex = -1;
  editingCorrect = 0;
  tfQuestionText.text = "";
  for (int i = 0; i < 4; i++) tfOptions[i].text = "";
  contentScrollOffset = 0;
}

void saveCurrentWorkshop() {
  Workshop w = new Workshop();
  w.title = editingTitle;
  w.content = editingContent;
  w.questions = new ArrayList<Question>();
  for (Question q : editingQuestions) {
    Question copy = new Question();
    copy.text = q.text; copy.correctIndex = q.correctIndex; copy.options = q.options.clone();
    w.questions.add(copy);
  }
  if (editingWorkshopIndex >= 0 && editingWorkshopIndex < workshops.size())
    workshops.set(editingWorkshopIndex, w);
  else {
    workshops.add(w);
    editingWorkshopIndex = workshops.size() - 1;
    selectedWorkshopIndex = editingWorkshopIndex;
  }
  saveWorkshopsToFile();
  setStatus("Taller '" + editingTitle + "' guardado (" + w.questions.size() + " preguntas)");
}

void deleteCurrentWorkshop() {
  if (selectedWorkshopIndex >= 0 && selectedWorkshopIndex < workshops.size()) {
    workshops.remove(selectedWorkshopIndex);
    selectedWorkshopIndex = -1;
    editingWorkshopIndex = -1;
    editingTitle = "";
    tfTitle.text = "";
    editingQuestions.clear();
    saveWorkshopsToFile();
    setStatus("Taller eliminado");
  }
}

void addQuestion() {
  if (tfQuestionText.text.length() == 0) return;
  Question q = new Question();
  q.text = tfQuestionText.text;
  q.options = new String[4];
  for (int i = 0; i < 4; i++) q.options[i] = tfOptions[i].text.length() > 0 ? tfOptions[i].text : "Opción " + (char)('A' + i);
  q.correctIndex = editingCorrect;
  editingQuestions.add(q);
  selectedQuestionIndex = editingQuestions.size() - 1;
  tfQuestionText.text = "";
  for (int i = 0; i < 4; i++) tfOptions[i].text = "";
  editingCorrect = 0;
}

void removeQuestion() {
  if (selectedQuestionIndex >= 0 && selectedQuestionIndex < editingQuestions.size()) {
    editingQuestions.remove(selectedQuestionIndex);
    selectedQuestionIndex = min(selectedQuestionIndex, editingQuestions.size() - 1);
  }
}

void moveQuestion(int dir) {
  if (selectedQuestionIndex < 0 || selectedQuestionIndex >= editingQuestions.size()) return;
  int newIndex = selectedQuestionIndex + dir;
  if (newIndex < 0 || newIndex >= editingQuestions.size()) return;
  Question temp = editingQuestions.get(selectedQuestionIndex);
  editingQuestions.set(selectedQuestionIndex, editingQuestions.get(newIndex));
  editingQuestions.set(newIndex, temp);
  selectedQuestionIndex = newIndex;
}

void loadQuestionIntoEditor(int index) {
  if (index < 0 || index >= editingQuestions.size()) return;
  Question q = editingQuestions.get(index);
  editingQuestionText = q.text;
  tfQuestionText.text = q.text;
  editingCorrect = q.correctIndex;
  for (int i = 0; i < 4 && i < q.options.length; i++) tfOptions[i].text = q.options[i];
}

void updateCurrentQuestionCorrect() {
  if (selectedQuestionIndex >= 0 && selectedQuestionIndex < editingQuestions.size())
    editingQuestions.get(selectedQuestionIndex).correctIndex = editingCorrect;
}

// ===== DATA CLASSES =====

class Question {
  String text;
  String[] options;
  int correctIndex;
}

class Workshop {
  String title;
  String content = "";  // Texto de estudio/lectura del taller
  ArrayList<Question> questions = new ArrayList<Question>();
}

class Student {
  String nombre;
  String grado;
  int numero;
  String ip;
  int id;
  Client client;
  boolean connected;
}

class Grade {
  String nombre;
  String grado;
  int numero;
  String workshopTitle;
  int score;
  int total;
  long timestamp;
  int[] answers;
}
