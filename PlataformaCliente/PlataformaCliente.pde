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
  background(235);

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

  if (statusTimer > 0) {
    fill(0);
    textAlign(CENTER, TOP);
    text(statusMessage, width/2, height - 30);
    statusTimer--;
  }
}

void layout() {
  float cx = width / 2;
  float fw = constrain(width * 0.4, 200, 400);
  float fh = 28;
  float fs = width < 600 ? 11 : 13;
  float ts = width < 600 ? 20 : 28;

  // Login screen positions
  float ly0 = height * 0.08;
  float ly1 = height * 0.135;
  float rowY = height * 0.22;
  float rowGap = 62;

  // -- Login fields --
  setTF(tfServerIP, cx - fw / 2, rowY + 22, fw, fh);
  setTF(tfPort, cx - fw / 2, rowY + rowGap + 22, fw, fh);

  float dataY = rowY + rowGap * 2 + 10;
  setTF(tfGrado, cx - fw / 2, dataY + rowGap + 2, fw, fh);
  setTF(tfNumero, cx - fw / 2, dataY + rowGap * 2 + 2, fw, fh);
  setTF(tfNombre, cx - fw / 2, dataY + rowGap * 3 + 2, fw, fh);

  float btnW = constrain(width * 0.18, 100, 160);
  float btnH = constrain(height * 0.055, 30, 42);
  setBtn(btnConnect, cx - btnW / 2, dataY + rowGap * 4 + 10, btnW, btnH);

  // Workshop screen
  setBtn(btnDisconnect, width - 150, 12, 130, 30);

  // Quiz bottom buttons
  float bby = height - 55;
  float bbw = constrain(width * 0.16, 90, 140);
  float bbh = 30;
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

void drawLoginScreen() {
  fill(60);
  noStroke();
  rect(0, 0, width, height);

  float cx = width / 2;
  float fw = constrain(width * 0.4, 200, 400);
  float rowGap = 62;
  float rowY = height * 0.22;
  float dataY = rowY + rowGap * 2 + 10;

  fill(255);
  textAlign(CENTER, TOP);
  float titleSize = constrain(width * 0.035, 20, 30);
  textSize(titleSize);
  text("Plataforma Educativa", cx, height * 0.07);
  textSize(titleSize * 0.6);
  text("Alumno", cx, height * 0.12);

  float labelSize = constrain(width * 0.017, 11, 14);
  textSize(labelSize);
  textAlign(LEFT, TOP);

  float lx = cx - fw / 2;
  fill(200);
  text("Dirección del servidor:", lx, rowY);
  tfServerIP.draw();

  text("Puerto:", lx, rowY + rowGap);
  tfPort.draw();

  fill(255, 230, 140);
  textSize(labelSize * 1.05);
  text("-- Datos del Alumno --", lx, dataY);
  textSize(labelSize);
  fill(200);

  text("Grado / Sección:", lx, dataY + rowGap - 20);
  tfGrado.draw();
  text("Número en lista:", lx, dataY + rowGap * 2 - 20);
  tfNumero.draw();
  text("Primer nombre:", lx, dataY + rowGap * 3 - 20);
  tfNombre.draw();

  btnConnect.draw(color(50, 130, 200), color(80, 170, 240));
}

// ===== WORKSHOPS SCREEN =====

void drawWorkshopsScreen() {
  // Header
  fill(60); noStroke(); rect(0, 0, width, 50);
  float titleSize = constrain(width * 0.022, 15, 20);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text("Talleres Disponibles", 20, 25);
  textAlign(RIGHT, CENTER);
  textSize(titleSize * 0.75);
  text(studentGrado + " - #" + studentNumero + " - " + studentNombre, width - 160, 25);
  btnDisconnect.draw();

  float pad = width * 0.05;
  float itemH = constrain(height * 0.075, 40, 60);
  int visibleCount = floor((height - 100) / itemH);
  wsScrollOffset = constrain(wsScrollOffset, 0, max(0, workshopTitles.size() - visibleCount));

  for (int i = wsScrollOffset; i < workshopTitles.size() && i < wsScrollOffset + visibleCount; i++) {
    float rowY = 70 + (i - wsScrollOffset) * itemH;
    fill(255); stroke(200); rect(pad, rowY, width - pad * 2, itemH - 6, 6);
    fill(30); textAlign(LEFT, CENTER);
    textSize(constrain(width * 0.02, 13, 17));
    text(workshopTitles.get(i), pad + 15, rowY + (itemH - 6) * 0.4);
    textSize(constrain(width * 0.014, 10, 12));
    fill(120);
    text("Haz clic para iniciar", pad + 15, rowY + (itemH - 6) * 0.78);
  }
  // Scroll arrows
  float arrSize = constrain(width * 0.025, 14, 22);
  if (wsScrollOffset > 0) {
    fill(100); textAlign(CENTER, TOP); textSize(arrSize); text("\u25B2", width/2, 56);
  }
  if (wsScrollOffset + visibleCount < workshopTitles.size()) {
    fill(100); textAlign(CENTER, BOTTOM); textSize(arrSize); text("\u25BC", width/2, height - 5);
  }
}

// ===== READING SCREEN (LECTURA) =====

void drawLecturaScreen() {
  // Header con título y botón volver
  fill(60); noStroke(); rect(0, 0, width, 50);
  float titleSize = constrain(width * 0.022, 15, 20);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text(currentWorkshopTitle, 20, 25);
  // Botón "Volver" en el extremo derecho del header
  float backH = 30;
  float backW = 100;
  fill(80, 130, 180); stroke(60, 100, 150);
  rect(width - backW - 10, 10, backW, backH, 4);
  fill(255); textAlign(CENTER, CENTER); textSize(13);
  text("← Volver", width - backW - 10 + backW/2, 10 + backH/2);
  textAlign(RIGHT, CENTER);
  textSize(titleSize * 0.8);
  text("Lectura", width - backW - 30, 25);

  // Área de contenido con tipografía grande y legible
  float padX = width * 0.06;
  float padY = 70;
  float contentW = width - padX * 2;
  float contentH = height - padY - 80;

  // Fondo blanco para el contenido
  fill(255);
  stroke(200);
  rect(padX - 5, padY - 5, contentW + 10, contentH + 10, 8);

  // Tipografía grande para lectura (mínimo 16px, escala con pantalla)
  float readingSize = constrain(width * 0.022, 16, 28);
  textSize(readingSize);
  textAlign(LEFT, TOP);
  fill(30);

  // Si no hay contenido, mostrar mensaje
  if (currentWorkshopContent == null || currentWorkshopContent.length() == 0) {
    fill(150);
    textSize(readingSize * 1.2);
    textAlign(CENTER, CENTER);
    text("No hay contenido de lectura\npara este taller.\n\nPresiona \"Comenzar Evaluación\"\npara ir a las preguntas.", width/2, height/2 - 40);
    return;
  }

  // Renderizar contenido con word-wrap y scroll
  String[] paragraphs = split(currentWorkshopContent, '\n');
  float lineH = readingSize * 1.5;
  float yPos = padY;

  // Calcular altura total del contenido
  float totalContentH = 0;
  for (String para : paragraphs) {
    if (para.trim().length() == 0) {
      totalContentH += lineH * 0.5;  // Espacio entre párrafos
    } else {
      // Calcular cuántas líneas ocupa este párrafo
      float paraW = textWidth(para);
      int lines = max(1, ceil(paraW / contentW));
      totalContentH += lines * lineH;
      totalContentH += lineH * 0.3;  // Espacio entre párrafos
    }
  }

  // Limitar scroll
  int maxScroll = max(0, (int)((totalContentH - contentH) / lineH) + 1);
  readingScrollOffset = constrain(readingScrollOffset, 0, maxScroll);

  // Dibujar contenido visible con scroll
  float drawY = padY;
  int lineCount = 0;
  int skipLines = readingScrollOffset;
  boolean started = false;

  for (String para : paragraphs) {
    if (para.trim().length() == 0) {
      if (started) {
        lineCount++;
        if (lineCount > skipLines) {
          drawY += lineH * 0.5;
        }
      }
      continue;
    }
    started = true;

    // Dividir párrafo en líneas que quepan en contentW
    String[] words = split(para, ' ');
    String currentLine = "";
    for (String w : words) {
      String testLine = currentLine.length() == 0 ? w : currentLine + " " + w;
      if (textWidth(testLine) > contentW && currentLine.length() > 0) {
        lineCount++;
        if (lineCount > skipLines && drawY + lineH <= padY + contentH) {
          text(currentLine, padX, drawY, contentW, lineH);
          drawY += lineH;
        }
        currentLine = w;
      } else {
        currentLine = testLine;
      }
    }
    // Última línea del párrafo
    if (currentLine.length() > 0) {
      lineCount++;
      if (lineCount > skipLines && drawY + lineH <= padY + contentH) {
        text(currentLine, padX, drawY, contentW, lineH);
        drawY += lineH;
      }
    }
    // Espacio entre párrafos
    lineCount++;
    if (lineCount > skipLines) {
      drawY += lineH * 0.3;
    }
  }

  // Indicadores de scroll
  float arrSize = constrain(width * 0.025, 14, 22);
  if (readingScrollOffset > 0) {
    fill(100, 150); textAlign(CENTER, TOP); textSize(arrSize); text("\u25B2", width/2, padY - 2);
  }
  if (readingScrollOffset < maxScroll) {
    fill(100, 150); textAlign(CENTER, BOTTOM); textSize(arrSize); text("\u25BC", width/2, padY + contentH - 2);
  }

  // Botón "Comenzar Evaluación" al fondo
  float bby = height - 55;
  btnStartQuiz.draw(color(30, 150, 50), color(50, 200, 80));
  fill(255); textAlign(LEFT, CENTER);
  textSize(constrain(width * 0.014, 10, 12));
  text(currentQuiz.size() + " preguntas", btnStartQuiz.x + btnStartQuiz.w + 10, bby + btnStartQuiz.h/2);
}

// ===== QUIZ SCREEN =====

void drawQuizScreen() {
  fill(60); noStroke(); rect(0, 0, width, 50);
  float titleSize = constrain(width * 0.02, 14, 18);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text(currentWorkshopTitle, 20, 25);
  textAlign(RIGHT, CENTER);
  textSize(titleSize * 0.85);
  text("Pregunta " + (currentQuestionIndex + 1) + " de " + currentQuiz.size(), width - 20, 25);

  if (currentQuiz.size() == 0) return;
  QuizQuestion q = currentQuiz.get(currentQuestionIndex);

  float qy = 75;
  float qTextSize = constrain(width * 0.02, 13, 17);
  fill(30); textAlign(LEFT, TOP); textSize(qTextSize);
  float qh = textWidth(q.text) > width * 0.75 ? 120 : 60;
  text(q.text, width * 0.05, qy, width * 0.9, qh);

  float pad = width * 0.075;
  float optH = constrain(height * 0.065, 34, 48);
  float optSize = constrain(width * 0.017, 11, 14);
  float optY0 = qy + qh + 15;

  for (int i = 0; i < q.options.length; i++) {
    float optY = optY0 + i * (optH + 8);
    boolean selected = (studentAnswers[currentQuestionIndex] == i);
    fill(selected ? color(200, 230, 255) : 255);
    stroke(selected ? color(50, 150, 255) : 180);
    strokeWeight(selected ? 2 : 1);
    rect(pad, optY, width - pad * 2, optH, 6);

    float radioR = constrain(width * 0.012, 7, 10);
    fill(selected ? color(50, 150, 255) : 190);
    noStroke();
    ellipse(pad + radioR * 2.5, optY + optH / 2, radioR * 2, radioR * 2);
    if (selected) {
      fill(255);
      ellipse(pad + radioR * 2.5, optY + optH / 2, radioR * 0.85, radioR * 0.85);
    }
    fill(selected ? color(20, 80, 180) : 50);
    textAlign(LEFT, CENTER);
    textSize(optSize);
    text((char)('A' + i) + ". " + q.options[i], pad + radioR * 5, optY + optH / 2);
  }

  // Bottom navigation buttons
  if (currentQuestionIndex > 0) btnPrevQuestion.draw();
  if (currentQuestionIndex < currentQuiz.size() - 1) btnNextQuestion.draw();
  if (!quizSubmitted) {
    float bby = height - 55;
    btnSubmitQuiz.draw();
    if (currentQuestionIndex == currentQuiz.size() - 1) {
      fill(255, 100, 100);
      textAlign(LEFT, TOP);
      textSize(constrain(width * 0.014, 10, 12));
      text("Última - presiona Enviar", btnSubmitQuiz.x, bby - 18);
    }
  }
}

// ===== RESULTS SCREEN =====

void drawResultsScreen() {
  fill(60); noStroke(); rect(0, 0, width, 50);
  float titleSize = constrain(width * 0.022, 15, 20);
  fill(255); textAlign(LEFT, CENTER); textSize(titleSize);
  text("Resultados: " + currentWorkshopTitle, 20, 25);

  float boxSize = constrain(width * 0.15, 120, 200);
  fill(255); stroke(200);
  rect(width / 2 - boxSize / 2, 85, boxSize, boxSize * 0.4, 10);
  fill(30); textAlign(CENTER, TOP);
  textSize(constrain(width * 0.05, 28, 44));
  text(quizScore + "/" + quizTotal, width / 2, 92);
  textSize(constrain(width * 0.017, 12, 15));
  fill(100);
  text("Correctas", width / 2, 92 + boxSize * 0.22);

  float y = 85 + boxSize * 0.4 + 20;
  float rh = constrain(height * 0.055, 30, 40);
  textSize(constrain(width * 0.015, 10, 13));
  for (int i = 0; i < currentQuiz.size() && i < quizResults.length; i++) {
    boolean correct = quizResults[i];
    fill(correct ? color(220, 255, 220) : color(255, 220, 220));
    stroke(correct ? color(100, 200, 100) : color(200, 100, 100));
    rect(width * 0.05, y, width * 0.9, rh, 4);
    fill(correct ? color(30, 120, 30) : color(180, 30, 30));
    textAlign(LEFT, CENTER);
    String icon = correct ? "\u2713" : "\u2717";
    text(icon + " P" + (i+1) + ": " + currentQuiz.get(i).text, width * 0.07, y + rh / 2);
    y += rh + 6;
    if (y > height - 70) break;
  }
  btnBackToWorkshops.draw();
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
