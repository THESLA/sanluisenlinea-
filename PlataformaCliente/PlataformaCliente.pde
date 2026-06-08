import processing.net.*;
import processing.data.*;

// Network
Client client;
String serverIP = "127.0.0.1";
int serverPort = 5204;
boolean isConnected = false;
int studentId = 0;

// Student data
String studentGrado = "", studentNumero = "", studentNombre = "";

// Screens
String currentScreen = "conectar";

// Data received from server
StringList workshopTitles = new StringList();
ArrayList<QuizQuestion> currentQuiz = new ArrayList<QuizQuestion>();
String currentWorkshopTitle = "";
String currentWorkshopContent = "";  // Contenido de lectura del taller
int currentQuestionIndex = 0;
int[] studentAnswers;
boolean quizSubmitted = false;
int quizScore = 0, quizTotal = 0;
boolean[] quizResults;
int readingScrollOffset = 0;  // Scroll vertical en pantalla de lectura

// Reconnection
boolean wasConnected = false;
int reconnectAttempts = 0;
int lastReconnectTry = 0;
final int RECONNECT_INTERVAL = 60; // frames (~1s at 60fps)
String savedServerIP = "";
int savedServerPort = 5204;
String savedGrado = "", savedNumero = "", savedNombre = "";

// Local persistence buffer (guardar respuestas si no hay conexión)
final String BUFFER_FILE = "data/respuestas_pendientes.json";

// UI Controls
Button btnConnect, btnDisconnect, btnPrevQuestion, btnNextQuestion, btnSubmitQuiz, btnBackToWorkshops, btnStartQuiz;
TextField tfServerIP, tfPort, tfGrado, tfNumero, tfNombre;
String statusMessage = "Ingresa tus datos para conectarte";
int statusTimer = 300;
int wsScrollOffset = 0;

void settings() {
  fullScreen();
}

void setup() {
  surface.setTitle("Plataforma Educativa - Alumno");

  tfServerIP = new TextField(0, 0, 0, 0);
  tfServerIP.text = serverIP;
  tfPort = new TextField(0, 0, 0, 0);
  tfPort.text = str(serverPort);
  tfGrado = new TextField(0, 0, 0, 0);
  tfNumero = new TextField(0, 0, 0, 0);
  tfNombre = new TextField(0, 0, 0, 0);

  btnConnect = new Button(0, 0, 0, 0, "Conectar");
  btnDisconnect = new Button(0, 0, 0, 0, "Desconectar");
  btnPrevQuestion = new Button(0, 0, 0, 0, "Anterior");
  btnNextQuestion = new Button(0, 0, 0, 0, "Siguiente");
  btnSubmitQuiz = new Button(0, 0, 0, 0, "Enviar");
  btnBackToWorkshops = new Button(0, 0, 0, 0, "Volver a Talleres");
  btnStartQuiz = new Button(0, 0, 0, 0, "Comenzar Evaluación");
}

void draw() {
  layout();

  // Fondo según pantalla
  if (currentScreen.equals("conectar")) {
    background(AZUL_ACCENTO);
  } else {
    background(CREMA_FONDO);
  }

  if (isConnected) {
    handleNetwork();
    wasConnected = true;
  } else if (wasConnected) {
    handleReconnection();
  }

  if (currentScreen.equals("conectar")) drawLoginScreen();
  else if (currentScreen.equals("talleres")) drawWorkshopsScreen();
  else if (currentScreen.equals("lectura")) drawLecturaScreen();
  else if (currentScreen.equals("quiz")) drawQuizScreen();
  else if (currentScreen.equals("resultados")) drawResultsScreen();

  // Barra de estado inferior
  if (statusTimer > 0) {
    fill(0, 0, 0, 60);
    noStroke();
    rect(width/2 - 120, height - 40, 240, 28, 14);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(statusMessage, width/2, height - 26);
    statusTimer--;
  }
}

void layout() {
  float cx = width / 2;
  float fs = width < 600 ? 11 : 13;

  // Login screen positions (tarjeta blanca centrada)
  float tarjetaW = constrain(width * 0.5, 280, 420);
  float tarjetaX = cx - tarjetaW / 2;
  float tarjetaY = height * 0.15;
  float campoW = tarjetaW - 60;
  float campoH = 32;
  float gap = campoH + 14;
  float lx = tarjetaX + 30;

  float formY = tarjetaY + 90;
  setTF(tfServerIP, lx, formY + 16, campoW * 0.55, campoH);
  setTF(tfPort, lx + campoW * 0.6, formY + 16, campoW * 0.35, campoH);

  // Separador visual
  float sepY = formY + gap;
  float alumnoY = sepY + 16;
  float campoY = alumnoY + 22;
  setTF(tfGrado, lx, campoY + 14, campoW, campoH);
  setTF(tfNumero, lx, campoY + gap + 14, campoW, campoH);
  setTF(tfNombre, lx, campoY + gap * 2 + 14, campoW, campoH);

  // Botón conectar (se reposiciona en drawLoginScreen)
  float btnW = constrain(width * 0.3, 160, 240);
  float btnY = campoY + gap * 3 + 22;
  setBtn(btnConnect, cx - btnW/2, btnY, btnW, 40);

  // Workshop screen
  setBtn(btnDisconnect, width - 150, 12, 130, 30);

  // Quiz bottom buttons
  float bby = height - 55;
  float bbw = constrain(width * 0.16, 90, 140);
  float bbh = 36;
  setBtn(btnPrevQuestion, width * 0.04, bby, bbw, bbh);
  setBtn(btnNextQuestion, width * 0.04 + bbw + 15, bby, bbw, bbh);
  setBtn(btnSubmitQuiz, width * 0.04 + (bbw + 15) * 2, bby, bbw, bbh);

  // Results button
  setBtn(btnBackToWorkshops, width * 0.04, bby, constrain(width * 0.25, 150, 220), bbh);

  // Reading screen button (más ancho para "Comenzar Evaluación")
  setBtn(btnStartQuiz, width * 0.04 + constrain(width * 0.25, 150, 220) + 15, bby, constrain(width * 0.25, 160, 220), bbh);

  textSize(fs);
}

void setTF(TextField tf, float x, float y, float w, float h) {
  tf.x = x; tf.y = y; tf.w = w; tf.h = h;
}
void setBtn(Button b, float x, float y, float w, float h) {
  b.x = x; b.y = y; b.w = w; b.h = h;
}

// ===== LOGIN SCREEN =====
// Fondo azul sólido, tarjeta blanca centrada, icono line-art

void drawLoginScreen() {
  float cx = width / 2;
  float tarjetaW = constrain(width * 0.5, 280, 420);
  float tarjetaH = constrain(height * 0.65, 380, 520);
  float tarjetaX = cx - tarjetaW / 2;
  float tarjetaY = height * 0.15;

  // Icono decorativo line-art (libro/graduación)
  float iconY = tarjetaY - 40;
  drawBookIcon(cx, iconY, 36);

  // Tarjeta blanca con bordes redondeados
  noStroke();
  fill(0, 0, 0, 30);
  rect(tarjetaX + 3, tarjetaY + 5, tarjetaW, tarjetaH, 20);
  fill(BLANCO_TARJETA);
  rect(tarjetaX, tarjetaY, tarjetaW, tarjetaH, 20);

  // Título dentro de la tarjeta
  fill(AZUL_ACCENTO);
  textAlign(CENTER, TOP);
  float tituloSize = constrain(width * 0.028, 18, 26);
  textSize(tituloSize);
  text("San Luis en línea", cx, tarjetaY + 24);
  textSize(tituloSize * 0.55);
  fill(TEXTO_SUAVE);
  text("Alumno", cx, tarjetaY + 52);

  // Línea divisoria
  stroke(CREMA_FONDO);
  strokeWeight(1);
  line(tarjetaX + 30, tarjetaY + 78, tarjetaX + tarjetaW - 30, tarjetaY + 78);

  // Campos del formulario
  float formY = tarjetaY + 90;
  float campoW = tarjetaW - 60;
  float campoH = 34;
  float gap = campoH + 14;
  float lx = tarjetaX + 30;
  float labelSize = constrain(width * 0.015, 11, 13);

  // Etiquetas y campos
  textAlign(LEFT, TOP);
  fill(TEXTO_SUAVE);
  textSize(labelSize);

  // Servidor
  text("Servidor", lx, formY);
  tfServerIP.setPlaceholder("127.0.0.1");
  tfServerIP.draw();
  // Puerto
  text("Puerto", lx + campoW * 0.6, formY);
  tfPort.setPlaceholder("5204");
  tfPort.draw();

  // Separador visual
  float sepY = formY + gap;
  stroke(CREMA_FONDO);
  strokeWeight(1);
  line(lx, sepY + 8, lx + campoW - 10, sepY + 8);

  // Datos del alumno
  float alumnoY = sepY + 16;
  fill(AZUL_ACCENTO);
  textAlign(CENTER, TOP);
  textSize(labelSize * 1.1);
  text("Datos del Alumno", cx, alumnoY);
  textSize(labelSize);
  fill(TEXTO_SUAVE);
  textAlign(LEFT, TOP);

  float campoY = alumnoY + 22;
  text("Grado / Sección", lx, campoY);
  tfGrado.setPlaceholder("Ej: 5A");
  tfGrado.draw();
  text("Número en lista", lx, campoY + gap);
  tfNumero.setPlaceholder("Ej: 12");
  tfNumero.draw();
  text("Primer nombre", lx, campoY + gap * 2);
  tfNombre.setPlaceholder("Ej: Juan");
  tfNombre.draw();

  // Botón conectar
  float btnY = campoY + gap * 3 + 8;
  float btnW = constrain(width * 0.3, 160, 240);
  setBtn(btnConnect, cx - btnW/2, btnY, btnW, 40);
  btnConnect.draw(AZUL_ACCENTO, AZUL_OSCURO);
}

// Dibuja icono de libro en estilo line-art
void drawBookIcon(float cx, float y, float size) {
  noFill();
  stroke(255);
  strokeWeight(2.5);
  float s = size;

  // Libro abierto
  arc(cx - s * 0.35, y + s * 0.1, s * 0.5, s * 0.7, PI * 0.15, PI * 0.85);
  arc(cx + s * 0.35, y + s * 0.1, s * 0.5, s * 0.7, PI * 1.15, PI * 1.85);

  // Páginas (líneas horizontales)
  for (int i = 0; i < 3; i++) {
    float ly = y + s * 0.1 + (i + 1) * s * 0.15;
    line(cx - s * 0.2, ly, cx + s * 0.2, ly);
  }

  // Estrella/brillo decorativo
  strokeWeight(1.5);
  float starX = cx + s * 0.5;
  float starY = y - s * 0.2;
  line(starX - 4, starY, starX + 4, starY);
  line(starX, starY - 4, starX, starY + 4);
}

// ===== WORKSHOPS SCREEN =====

void drawWorkshopsScreen() {
  // Header azul
  noStroke();
  fill(AZUL_ACCENTO); rect(0, 0, width, 56);
  float titleSize = constrain(width * 0.024, 17, 22);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text("Talleres Disponibles", 22, 28);

  // Info del alumno a la derecha
  textSize(titleSize * 0.65);
  fill(255, 220);
  textAlign(RIGHT, CENTER);
  text(studentGrado + " · #" + studentNumero + " · " + studentNombre, width - 160, 18);
  textSize(11);
  fill(255, 160);
  text("Conectado", width - 160, 40);

  // Botón desconectar (redondo, pequeño)
  setBtn(btnDisconnect, width - 48, 14, 34, 28);
  btnDisconnect.cornerRadius = 14;
  btnDisconnect.draw(color(200, 60, 60), color(220, 40, 40));

  // Lista de talleres como cards
  float pad = width * 0.05;
  float itemH = constrain(height * 0.085, 50, 72);
  float cardGap = 10;
  float availableH = height - 76 - 10;
  int visibleCount = max(1, floor(availableH / (itemH + cardGap)));
  wsScrollOffset = constrain(wsScrollOffset, 0, max(0, workshopTitles.size() - visibleCount));

  for (int i = wsScrollOffset; i < workshopTitles.size() && i < wsScrollOffset + visibleCount; i++) {
    float cardY = 70 + (i - wsScrollOffset) * (itemH + cardGap);
    boolean hovered = mouseX >= pad && mouseX <= width - pad && mouseY >= cardY && mouseY <= cardY + itemH;

    // Sombra de la card
    noStroke();
    fill(0, 0, 0, hovered ? 25 : 12);
    rect(pad + 2, cardY + 3, width - pad * 2, itemH, 14);

    // Card blanca
    fill(hovered ? color(252, 250, 248) : BLANCO_TARJETA);
    stroke(hovered ? AZUL_CLARO : GRIS_BORDE);
    strokeWeight(hovered ? 2 : 1);
    rect(pad, cardY, width - pad * 2, itemH, 14);

    // Icono de libro pequeño (decoración)
    noStroke();
    fill(AZUL_CLARO);
    ellipse(pad + 26, cardY + itemH/2, 28, 28);
    fill(AZUL_ACCENTO);
    textAlign(CENTER, CENTER);
    textSize(14);
    text("📖", pad + 26, cardY + itemH/2);

    // Título del taller
    fill(TEXTO_OSCURO);
    textAlign(LEFT, CENTER);
    textSize(constrain(width * 0.02, 14, 18));
    text(workshopTitles.get(i), pad + 48, cardY + itemH * 0.45);

    // Indicador "Clic para iniciar"
    textSize(constrain(width * 0.013, 10, 12));
    fill(TEXTO_SUAVE);
    text("Toca para iniciar →", pad + 48, cardY + itemH * 0.78);

    // Flecha indicadora
    if (hovered) {
      fill(AZUL_ACCENTO);
      textAlign(RIGHT, CENTER);
      textSize(18);
      text("→", width - pad - 16, cardY + itemH/2);
    }
  }

  // Scroll arrows minimalistas
  float arrSize = constrain(width * 0.022, 12, 18);
  if (wsScrollOffset > 0) {
    fill(AZUL_ACCENTO, 150); textAlign(CENTER, TOP); textSize(arrSize);
    text("▲", width/2, 58);
  }
  if (wsScrollOffset + visibleCount < workshopTitles.size()) {
    fill(AZUL_ACCENTO, 150); textAlign(CENTER, BOTTOM); textSize(arrSize);
    text("▼", width/2, height - 8);
  }
}

// ===== READING SCREEN (LECTURA) =====

void drawLecturaScreen() {
  // Header azul
  noStroke();
  fill(AZUL_ACCENTO); rect(0, 0, width, 56);
  float titleSize = constrain(width * 0.022, 15, 20);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text(currentWorkshopTitle, 20, 28);

  // Botón "Volver" estilo píldora
  float backW = 90;
  float backH = 30;
  noStroke();
  fill(255, 255, 255, 200);
  rect(width - backW - 14, 13, backW, backH, backH/2);
  fill(AZUL_ACCENTO); textAlign(CENTER, CENTER); textSize(13);
  text("← Volver", width - backW - 14 + backW/2, 13 + backH/2);
  textAlign(RIGHT, CENTER);
  fill(255, 200);
  textSize(titleSize * 0.7);
  text("Lectura", width - backW - 120, 28);

  // Área de contenido con tipografía grande y legible
  float padX = width * 0.05;
  float padY = 72;
  float contentW = width - padX * 2;
  float contentH = height - padY - 82;

  // Fondo blanco para el contenido con borde sutil
  noStroke();
  fill(0, 0, 0, 10);
  rect(padX + 2, padY + 3, contentW, contentH, 14);
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  strokeWeight(1);
  rect(padX, padY, contentW, contentH, 14);

  // Tipografía grande para lectura
  float readingSize = constrain(width * 0.022, 17, 30);
  textSize(readingSize);
  textAlign(LEFT, TOP);
  fill(TEXTO_OSCURO);

  // Si no hay contenido, mostrar mensaje
  if (currentWorkshopContent == null || currentWorkshopContent.length() == 0) {
    fill(TEXTO_SUAVE);
    textSize(readingSize * 0.9);
    textAlign(CENTER, CENTER);
    text("No hay contenido de lectura\npara este taller.\n\nPresiona \"Comenzar Evaluación\"\npara ir a las preguntas.", width/2, height/2 - 40);
    return;
  }

  // Renderizar contenido con word-wrap y scroll
  String[] paragraphs = split(currentWorkshopContent, '\n');
  float lineH = readingSize * 1.6;
  float contentInnerW = contentW - 20;

  // Calcular altura total del contenido
  float totalContentH = 0;
  for (String para : paragraphs) {
    if (para.trim().length() == 0) {
      totalContentH += lineH * 0.5;
    } else {
      float paraW = textWidth(para);
      int lines = max(1, ceil(paraW / contentInnerW));
      totalContentH += lines * lineH;
      totalContentH += lineH * 0.2;
    }
  }

  // Limitar scroll
  int maxScroll = max(0, (int)((totalContentH - contentH + 20) / lineH));
  readingScrollOffset = constrain(readingScrollOffset, 0, maxScroll);

  // Dibujar contenido visible con scroll
  float drawY = padY + 10;
  int lineCount = 0;
  int skipLines = readingScrollOffset;
  boolean started = false;

  for (String para : paragraphs) {
    if (para.trim().length() == 0) {
      if (started) {
        lineCount++;
        if (lineCount > skipLines && drawY + lineH <= padY + contentH) {
          drawY += lineH * 0.5;
        }
      }
      continue;
    }
    started = true;

    String[] words = split(para, ' ');
    String currentLine = "";
    for (String w : words) {
      String testLine = currentLine.length() == 0 ? w : currentLine + " " + w;
      if (textWidth(testLine) > contentInnerW && currentLine.length() > 0) {
        lineCount++;
        if (lineCount > skipLines && drawY + lineH <= padY + contentH - 10) {
          text(currentLine, padX + 10, drawY, contentInnerW, lineH);
          drawY += lineH;
        }
        currentLine = w;
      } else {
        currentLine = testLine;
      }
    }
    if (currentLine.length() > 0) {
      lineCount++;
      if (lineCount > skipLines && drawY + lineH <= padY + contentH - 10) {
        text(currentLine, padX + 10, drawY, contentInnerW, lineH);
        drawY += lineH;
      }
    }
    lineCount++;
    if (lineCount > skipLines) {
      drawY += lineH * 0.2;
    }
  }

  // Indicadores de scroll minimalistas
  float arrSize = constrain(width * 0.022, 12, 18);
  if (readingScrollOffset > 0) {
    fill(AZUL_ACCENTO, 180); textAlign(CENTER, TOP); textSize(arrSize);
    text("▲", width/2, padY + 2);
  }
  if (readingScrollOffset < maxScroll) {
    fill(AZUL_ACCENTO, 180); textAlign(CENTER, BOTTOM); textSize(arrSize);
    text("▼", width/2, padY + contentH - 4);
  }

  // Botón "Comenzar Evaluación" verde al fondo
  float bby = height - 55;
  btnStartQuiz.draw(VERDE_ACIERTO, color(35, 120, 70));
  fill(TEXTO_SUAVE); textAlign(LEFT, CENTER);
  textSize(constrain(width * 0.014, 11, 13));
  text(currentQuiz.size() + " preguntas", btnStartQuiz.x + btnStartQuiz.w + 12, bby + btnStartQuiz.h/2);
}

// ===== QUIZ SCREEN =====
// Opciones tipo píldora, selección azul cobalto, progreso visual

void drawQuizScreen() {
  // Header azul
  noStroke();
  fill(AZUL_ACCENTO); rect(0, 0, width, 56);
  float titleSize = constrain(width * 0.02, 14, 18);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text(currentWorkshopTitle, 20, 28);

  // Indicador de progreso
  textSize(titleSize * 0.7);
  fill(255, 200);
  textAlign(RIGHT, CENTER);
  text("Pregunta " + (currentQuestionIndex + 1) + " de " + currentQuiz.size(), width - 20, 22);

  // Barra de progreso
  float barY = 48;
  float barW = width - 40;
  float barH = 4;
  fill(0, 0, 0, 30);
  rect(20, barY, barW, barH, 2);
  fill(255, 200);
  float progress = (currentQuestionIndex + 1.0) / currentQuiz.size();
  rect(20, barY, barW * progress, barH, 2);

  if (currentQuiz.size() == 0) return;
  QuizQuestion q = currentQuiz.get(currentQuestionIndex);

  // Pregunta en card blanca
  float qy = 68;
  float qTextSize = constrain(width * 0.02, 15, 20);
  float qPad = width * 0.04;

  noStroke();
  fill(0, 0, 0, 8);
  rect(qPad + 2, qy + 3, width - qPad * 2, 70, 12);
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  strokeWeight(1);
  rect(qPad, qy, width - qPad * 2, 70, 12);

  fill(TEXTO_OSCURO);
  textAlign(LEFT, CENTER);
  textSize(qTextSize);
  text(q.text, qPad + 16, qy + 35, width - qPad * 2 - 32, 60);

  // Opciones como píldoras
  float optY0 = qy + 84;
  float optH = constrain(height * 0.07, 40, 56);
  float optGap = 8;
  float optSize = constrain(width * 0.017, 12, 15);
  float optPad = width * 0.06;

  for (int i = 0; i < q.options.length; i++) {
    float optY = optY0 + i * (optH + optGap);
    boolean selected = (studentAnswers[currentQuestionIndex] == i);

    // Sombra
    noStroke();
    fill(0, 0, 0, selected ? 20 : 8);
    rect(optPad + 1, optY + 2, width - optPad * 2, optH, optH/2);

    // Fondo de la opción
    if (selected) {
      fill(AZUL_ACCENTO);
      noStroke();
      rect(optPad, optY, width - optPad * 2, optH, optH/2);
    } else {
      fill(BLANCO_TARJETA);
      stroke(GRIS_BORDE);
      strokeWeight(1);
      rect(optPad, optY, width - optPad * 2, optH, optH/2);
    }

    // Letra (A, B, C, D) como badge circular
    float badgeR = optH * 0.32;
    float badgeX = optPad + optH * 0.25;
    float badgeY = optY + optH / 2;
    if (selected) {
      fill(255, 255, 255, 200);
      noStroke();
      ellipse(badgeX, badgeY, badgeR * 2, badgeR * 2);
      fill(AZUL_ACCENTO);
    } else {
      fill(CREMA_FONDO);
      stroke(GRIS_BORDE);
      strokeWeight(1);
      ellipse(badgeX, badgeY, badgeR * 2, badgeR * 2);
      fill(TEXTO_SUAVE);
    }
    textAlign(CENTER, CENTER);
    textSize(optSize * 0.9);
    noStroke();
    text((char)('A' + i), badgeX, badgeY);

    // Texto de la opción
    fill(selected ? 255 : TEXTO_OSCURO);
    textAlign(LEFT, CENTER);
    textSize(optSize);
    text(q.options[i], badgeX + badgeR + 16, optY + optH / 2, width - optPad * 2 - badgeR - 32, optH);
  }

  // Bottom navigation buttons (píldoras)
  float bby = height - 58;
  if (currentQuestionIndex > 0) btnPrevQuestion.draw();
  if (currentQuestionIndex < currentQuiz.size() - 1) btnNextQuestion.draw();
  if (!quizSubmitted) {
    // Botón enviar con color especial en la última pregunta
    if (currentQuestionIndex == currentQuiz.size() - 1) {
      btnSubmitQuiz.draw(VERDE_ACIERTO, color(35, 150, 70));
      fill(TEXTO_SUAVE);
      textAlign(LEFT, CENTER);
      textSize(constrain(width * 0.013, 10, 12));
      text("Última pregunta", btnSubmitQuiz.x + btnSubmitQuiz.w + 10, bby + btnSubmitQuiz.h/2);
    } else {
      btnSubmitQuiz.draw(AZUL_ACCENTO, AZUL_OSCURO);
    }
  }
}

// ===== RESULTS SCREEN =====
// Score circular, feedback visual con iconos

void drawResultsScreen() {
  // Header azul
  noStroke();
  fill(AZUL_ACCENTO); rect(0, 0, width, 56);
  float titleSize = constrain(width * 0.022, 15, 20);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text("Resultados", 20, 28);
  textSize(titleSize * 0.65);
  fill(255, 200);
  text(currentWorkshopTitle, 20, 44);

  // Score circular grande
  float cx = width / 2;
  float circleR = constrain(width * 0.13, 60, 100);
  float circleY = 80 + circleR;

  // Círculo exterior
  noStroke();
  fill(0, 0, 0, 15);
  ellipse(cx + 2, circleY + 3, circleR * 2, circleR * 2);
  fill(BLANCO_TARJETA);
  stroke(GRIS_BORDE);
  strokeWeight(2);
  ellipse(cx, circleY, circleR * 2, circleR * 2);

  // Porcentaje de acierto
  float pct = quizTotal > 0 ? (float)quizScore / quizTotal : 0;
  String mensaje = pct >= 0.8 ? "¡Excelente!" : (pct >= 0.6 ? "¡Bien!" : (pct >= 0.4 ? "Puedes mejorar" : "Sigue practicando"));

  fill(AZUL_ACCENTO);
  textAlign(CENTER, CENTER);
  textSize(constrain(width * 0.055, 32, 52));
  text(quizScore + "/" + quizTotal, cx, circleY - 4);
  textSize(constrain(width * 0.016, 11, 14));
  fill(TEXTO_SUAVE);
  text("correctas", cx, circleY + 20);
  textSize(constrain(width * 0.018, 13, 16));
  fill(pct >= 0.6 ? VERDE_ACIERTO : ROJO_ERROR);
  text(mensaje, cx, circleY + 40);

  // Detalle de respuestas en cards
  float detailY = circleY + circleR + 20;
  float rh = constrain(height * 0.05, 28, 36);

  for (int i = 0; i < currentQuiz.size() && i < quizResults.length; i++) {
    boolean correct = quizResults[i];
    float rowY = detailY + i * (rh + 5);
    if (rowY > height - 70) break;

    // Card de respuesta
    noStroke();
    fill(0, 0, 0, 8);
    rect(width * 0.05 + 1, rowY + 2, width * 0.9, rh, rh/2);
    fill(correct ? color(235, 250, 235) : color(255, 235, 235));
    stroke(correct ? color(180, 220, 180) : color(220, 180, 180));
    strokeWeight(1);
    rect(width * 0.05, rowY, width * 0.9, rh, rh/2);

    // Icono y texto
    fill(correct ? VERDE_ACIERTO : ROJO_ERROR);
    textAlign(LEFT, CENTER);
    textSize(constrain(width * 0.016, 11, 14));
    String icon = correct ? "✓" : "✗";
    text(icon + "  P" + (i+1) + ": " + currentQuiz.get(i).text, width * 0.08, rowY + rh/2, width * 0.84, rh);
  }

  // Botón volver a talleres
  float bby = height - 55;
  btnBackToWorkshops.draw(AZUL_ACCENTO, AZUL_OSCURO);
  // Indicador de vuelta
  fill(TEXTO_SUAVE);
  textAlign(LEFT, CENTER);
  textSize(11);
  text("← Volver a lista de talleres", btnBackToWorkshops.x + btnBackToWorkshops.w + 10, bby + btnBackToWorkshops.h/2);
}

// ===== NETWORKING =====

void connectToServer() {
  if (client != null) { client.stop(); client = null; }
  isConnected = false;
  try {
    savedServerIP = tfServerIP.text;
    savedServerPort = parseInt(tfPort.text);
    savedGrado = tfGrado.text;
    savedNumero = tfNumero.text;
    savedNombre = tfNombre.text;
    serverIP = savedServerIP;
    serverPort = savedServerPort;
    studentGrado = savedGrado;
    studentNumero = savedNumero;
    studentNombre = savedNombre;

    if (studentGrado.length() == 0 || studentNumero.length() == 0 || studentNombre.length() == 0) {
      setStatus("Completa todos los campos"); return;
    }
    int nro = parseInt(studentNumero);
    if (nro <= 0) { setStatus("Número en lista inválido"); return; }

    client = new Client(this, serverIP, serverPort);
    if (client.active()) {
      wasConnected = true;
      reconnectAttempts = 0;
      isConnected = true;
      currentScreen = "talleres";
      setStatus("Conectado al servidor");

      JSONObject msg = new JSONObject();
      msg.setString("type", "connect");
      msg.setString("nombre", studentNombre);
      msg.setString("grado", studentGrado);
      msg.setInt("numero", nro);
      sendMessage(msg);

      delay(200);
      JSONObject req = new JSONObject();
      req.setString("type", "list_workshops");
      sendMessage(req);
    } else {
      setStatus("No se pudo conectar al servidor");
    }
  } catch (Exception e) {
    setStatus("Error: " + e.getMessage());
  }
}

void disconnect() {
  if (client != null) { client.stop(); client = null; }
  isConnected = false;
  wasConnected = false;
  reconnectAttempts = 0;
  currentScreen = "conectar";
  currentQuiz.clear();
  workshopTitles.clear();
  setStatus("Desconectado");
}

void handleNetwork() {
  if (client == null || !client.active()) {
    isConnected = false;
    return;
  }
  String msg = client.readStringUntil('\n');
  if (msg != null) {
    msg = msg.trim();
    if (msg.length() > 0) processServerMessage(msg);
  }
}

void handleReconnection() {
  if (frameCount - lastReconnectTry < RECONNECT_INTERVAL) return;
  lastReconnectTry = frameCount;
  reconnectAttempts++;

  setStatus("Reconectando... (" + reconnectAttempts + "/10)");

  if (reconnectAttempts > 10) {
    wasConnected = false;
    currentScreen = "conectar";
    setStatus("Conexión perdida. Vuelve a conectar manualmente.");
    return;
  }

  try {
    if (client != null) { client.stop(); client = null; }
    client = new Client(this, savedServerIP, savedServerPort);
    if (client.active()) {
      isConnected = true;
      wasConnected = true;
      reconnectAttempts = 0;
      setStatus("Reconectado al servidor");

      JSONObject msg = new JSONObject();
      msg.setString("type", "connect");
      msg.setString("nombre", savedNombre);
      msg.setString("grado", savedGrado);
      msg.setInt("numero", parseInt(savedNumero));
      sendMessage(msg);

      delay(100);
      JSONObject req = new JSONObject();
      req.setString("type", "list_workshops");
      sendMessage(req);

      if (currentScreen.equals("conectar")) currentScreen = "talleres";

      // Al reconectar, verificar si hay respuestas pendientes por enviar
      checkPendingOnReconnect();
    }
  } catch (Exception e) {
    println("Reintento fallido: " + e.getMessage());
  }
}

void processServerMessage(String msg) {
  try {
    JSONObject json = JSONObject.parse(msg);
    String type = json.getString("type", "");
    if (type.equals("connected")) {
      studentId = json.getInt("id", 0);
    } else if (type.equals("workshop_list")) {
      workshopTitles.clear();
      JSONArray arr = json.getJSONArray("workshops");
      for (int i = 0; i < arr.size(); i++) workshopTitles.append(arr.getString(i));
    } else if (type.equals("quiz_data")) {
      currentWorkshopTitle = json.getString("workshop", "");
      currentWorkshopContent = json.getString("content", "");
      JSONArray qArr = json.getJSONArray("questions");
      currentQuiz.clear();
      for (int i = 0; i < qArr.size(); i++) {
        JSONObject qObj = qArr.getJSONObject(i);
        QuizQuestion q = new QuizQuestion();
        q.text = qObj.getString("text", "");
        JSONArray optArr = qObj.getJSONArray("options");
        q.options = new String[optArr.size()];
        for (int j = 0; j < optArr.size(); j++) q.options[j] = optArr.getString(j, "");
        currentQuiz.add(q);
      }
      studentAnswers = new int[currentQuiz.size()];
      for (int i = 0; i < studentAnswers.length; i++) studentAnswers[i] = -1;
      currentQuestionIndex = 0;
      quizSubmitted = false;
      readingScrollOffset = 0;
      // Primero mostrar pantalla de lectura, luego el quiz
      currentScreen = "lectura";
    } else if (type.equals("quiz_result")) {
      quizScore = json.getInt("score", 0);
      quizTotal = json.getInt("total", 0);
      JSONArray rArr = json.getJSONArray("results");
      quizResults = new boolean[rArr.size()];
      for (int i = 0; i < rArr.size(); i++) quizResults[i] = rArr.getBoolean(i);
      quizSubmitted = true;
      currentScreen = "resultados";
      setStatus("Nota: " + quizScore + "/" + quizTotal);
      // Si estas respuestas venían del buffer local, lo limpiamos
      clearPendingAnswers();
    }
  } catch (Exception e) {
    println("Error parsing: " + e.getMessage());
  }
}

void sendMessage(JSONObject msg) {
  if (client != null && client.active()) client.write(msg.toString() + "\n");
}

void requestWorkshopList() {
  JSONObject req = new JSONObject(); req.setString("type", "list_workshops"); sendMessage(req);
}

void requestQuiz(String title) {
  JSONObject req = new JSONObject();
  req.setString("type", "request_quiz"); req.setString("workshop", title); sendMessage(req);
}

void submitAnswers() {
  JSONArray ansArr = new JSONArray();
  for (int i = 0; i < studentAnswers.length; i++)
    ansArr.setInt(i, studentAnswers[i] >= 0 ? studentAnswers[i] : 0);

  // Si no hay conexión, guardamos en buffer local
  if (!isConnected) {
    savePendingAnswers();
    setStatus("Sin conexión. Respuestas guardadas. Se enviarán al reconectar.");
    return;
  }

  JSONObject msg = new JSONObject();
  msg.setString("type", "submit_answers");
  msg.setString("workshop", currentWorkshopTitle);
  msg.setJSONArray("answers", ansArr);
  sendMessage(msg);
}

void setStatus(String msg) {
  statusMessage = msg; statusTimer = 300; println(msg);
}

// ===== LOCAL PERSISTENCE BUFFER =====
// Guarda las respuestas actuales en un archivo local para no perder
// el progreso si la conexión falla o se apaga la computadora.

void savePendingAnswers() {
  try {
    JSONObject buffer = new JSONObject();
    buffer.setString("workshopTitle", currentWorkshopTitle);
    JSONArray ansArr = new JSONArray();
    for (int i = 0; i < studentAnswers.length; i++)
      ansArr.setInt(i, studentAnswers[i]);
    buffer.setJSONArray("answers", ansArr);
    buffer.setInt("currentQuestion", currentQuestionIndex);
    saveJSONObject(buffer, BUFFER_FILE);
    println("[Buffer] Respuestas guardadas en: " + BUFFER_FILE);
  } catch (Exception e) {
    println("[Buffer] Error al guardar: " + e.getMessage());
  }
}

boolean hasPendingAnswers() {
  try {
    String[] lines = loadStrings(BUFFER_FILE);
    if (lines == null || lines.length == 0) return false;
    String content = join(lines, "").trim();
    return content.length() > 0 && !content.equals("{}");
  } catch (Exception e) {
    return false;
  }
}

JSONObject loadPendingAnswers() {
  try {
    String[] lines = loadStrings(BUFFER_FILE);
    if (lines != null) {
      String json = join(lines, "\n");
      if (json.trim().length() > 0) return JSONObject.parse(json);
    }
  } catch (Exception e) {
    println("[Buffer] Error al cargar: " + e.getMessage());
  }
  return null;
}

void clearPendingAnswers() {
  try {
    saveJSONObject(new JSONObject(), BUFFER_FILE);
    println("[Buffer] Archivo de respuestas pendientes limpiado");
  } catch (Exception e) {
    println("[Buffer] Error al limpiar: " + e.getMessage());
  }
}

// Envía las respuestas guardadas en el buffer al servidor
void submitPendingFromBuffer() {
  JSONObject buffer = loadPendingAnswers();
  if (buffer == null) {
    println("[Buffer] No hay respuestas pendientes para enviar");
    return;
  }

  String workshopTitle = buffer.getString("workshopTitle", "");
  JSONArray ansArr = buffer.getJSONArray("answers");

  if (workshopTitle.length() == 0 || ansArr == null) {
    println("[Buffer] Buffer corrupto, limpiando...");
    clearPendingAnswers();
    return;
  }

  // Mostrar mensaje al alumno
  setStatus("Enviando respuestas guardadas del taller: " + workshopTitle);

  // Cargar el taller en el cliente para que el alumno vea el resultado
  currentWorkshopTitle = workshopTitle;
  currentQuestionIndex = buffer.getInt("currentQuestion", 0);
  studentAnswers = new int[ansArr.size()];
  for (int i = 0; i < ansArr.size(); i++)
    studentAnswers[i] = ansArr.getInt(i);

  // Enviar al servidor
  JSONObject msg = new JSONObject();
  msg.setString("type", "submit_answers");
  msg.setString("workshop", workshopTitle);
  msg.setJSONArray("answers", ansArr);
  sendMessage(msg);
  println("[Buffer] Enviando respuestas pendientes: " + workshopTitle);
}

// Verifica al reconectar si hay respuestas pendientes y las envía
void checkPendingOnReconnect() {
  if (hasPendingAnswers()) {
    println("[Buffer] Detectadas respuestas pendientes al reconectar");
    // Solo auto-enviamos si no estamos en medio de un quiz
    if (currentScreen.equals("talleres") || currentScreen.equals("conectar")) {
      submitPendingFromBuffer();
    }
  }
}

// ===== MOUSE & KEYBOARD =====

void mousePressed() {
  if (currentScreen.equals("conectar")) {
    tfServerIP.handleMouse();
    tfPort.handleMouse();
    tfGrado.handleMouse();
    tfNumero.handleMouse();
    tfNombre.handleMouse();
    if (btnConnect.isMouseOver()) connectToServer();

  } else if (currentScreen.equals("talleres")) {
    if (btnDisconnect.isMouseOver()) { disconnect(); return; }
    float pad = width * 0.05;
    float itemH = constrain(height * 0.075, 40, 60);
    int visibleCount = floor((height - 100) / itemH);
    for (int i = wsScrollOffset; i < workshopTitles.size() && i < wsScrollOffset + visibleCount; i++) {
      float rowY = 70 + (i - wsScrollOffset) * itemH;
      if (mouseX >= pad && mouseX <= width - pad && mouseY >= rowY && mouseY <= rowY + itemH - 6) {
        requestQuiz(workshopTitles.get(i)); return;
      }
    }

  } else if (currentScreen.equals("lectura")) {
    // Botón "Volver" en el header
    if (mouseX >= width - 110 && mouseX <= width - 10 && mouseY >= 10 && mouseY <= 40) {
      currentScreen = "talleres"; requestWorkshopList(); return;
    }
    if (btnDisconnect.isMouseOver()) { disconnect(); return; }
    if (btnStartQuiz.isMouseOver()) {
      // Ir al quiz si hay preguntas
      if (currentQuiz.size() > 0) {
        currentScreen = "quiz";
        currentQuestionIndex = 0;
      } else {
        setStatus("Este taller no tiene preguntas");
      }
      return;
    }

  } else if (currentScreen.equals("quiz")) {
    if (currentQuiz.size() == 0) return;
    QuizQuestion q = currentQuiz.get(currentQuestionIndex);
    float qy = 75;
    float qh = textWidth(q.text) > width * 0.75 ? 120 : 60;
    float pad = width * 0.075;
    float optH = constrain(height * 0.065, 34, 48);
    float optY0 = qy + qh + 15;

    for (int i = 0; i < q.options.length; i++) {
      float optY = optY0 + i * (optH + 8);
      if (mouseX >= pad && mouseX <= width - pad && mouseY >= optY && mouseY <= optY + optH) {
        studentAnswers[currentQuestionIndex] = i; return;
      }
    }
    if (btnPrevQuestion.isMouseOver() && currentQuestionIndex > 0) currentQuestionIndex--;
    else if (btnNextQuestion.isMouseOver() && currentQuestionIndex < currentQuiz.size() - 1) currentQuestionIndex++;
    else if (btnSubmitQuiz.isMouseOver() && !quizSubmitted) submitAnswers();

  } else if (currentScreen.equals("resultados")) {
    if (btnBackToWorkshops.isMouseOver()) {
      currentScreen = "talleres"; requestWorkshopList();
    }
  }
}

void keyPressed() {
  if (currentScreen.equals("conectar")) {
    if (tfServerIP.isFocused) handleKey(tfServerIP);
    else if (tfPort.isFocused) handleKey(tfPort);
    else if (tfGrado.isFocused) handleKey(tfGrado);
    else if (tfNumero.isFocused) handleKey(tfNumero);
    else if (tfNombre.isFocused) handleKey(tfNombre);
  }
}

void handleKey(TextField tf) {
  if (key == BACKSPACE && tf.text.length() > 0)
    tf.text = tf.text.substring(0, tf.text.length() - 1);
  else if (key == ENTER || key == RETURN) {
    tf.isFocused = false;
    if (tf == tfNombre) connectToServer();
  } else if (key != BACKSPACE && key != TAB && key != ENTER && key != RETURN && key != CODED) {
    tf.text += key;
  }
}

void mouseWheel(MouseEvent event) {
  if (currentScreen.equals("talleres")) wsScrollOffset += (int)event.getCount();
  else if (currentScreen.equals("lectura")) readingScrollOffset += (int)event.getCount();
}

// ===== DATA =====

class QuizQuestion {
  String text;
  String[] options;
}
