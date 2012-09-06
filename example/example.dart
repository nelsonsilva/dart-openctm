#import("dart:html");
#import("dart:math", prefix:'Math');
//#import('dart:isolate');
#import("../ctm.dart", prefix:'CTM');

#source("glmatrix.dart");

const shaderVS = '''
  attribute vec3 aVertexPosition;
  attribute vec4 aVertexColor;

  uniform mat4 uMVMatrix;
  uniform mat4 uPMatrix;

  varying vec4 vColor;
  
  void main(void){
    gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1);

    vColor = aVertexColor;
  }
''';

const shaderFS = ''' 
#ifdef GL_ES
  precision highp float;
#endif

  varying vec4 vColor;

  void main(void){
    gl_FragColor = vec4(vColor.rgb, 1);;
  }
''';


WebGLRenderingContext gl;
CanvasElement canvas;
CTM.File file;

WebGLProgram shaderProgram;
Matrix4 mvMatrix,
        pMatrix;
WebGLBuffer vertexIndexBuffer,
            vertexPositionBuffer,
            vertexColorBuffer;
var offsets;
var mouseDown = false;
var lastMouseX;
var lastMouseY;
var translationMatrix;
var rotationMatrix;

Future _get(filename, [Element progress]) {
  Completer completer = new Completer();
  var request = new HttpRequest();
  request.open("GET", filename, true);
  request.overrideMimeType("text/plain; charset=x-user-defined");
  request.on.readyStateChange.add( (e){
    if (request.readyState == HttpRequest.LOADING || request.readyState == HttpRequest.DONE){
      if (progress != null) {
        var size = (request.responseText.length / 1048576).toStringAsPrecision(2);
        progress.innerHTML = "Downloading... $size MB";
      }
    }
    if (request.readyState == HttpRequest.DONE && (request.status == 200 || request.status == 0) ){
      completer.complete(request.responseText);
    }
  });
  request.send();
  return completer.future;
}

main(){
  mvMatrix = new Matrix4();
  pMatrix = new Matrix4();
  translationMatrix = new Vector3();
  rotationMatrix = new Matrix4();
  var progress = document.query("#progress");
  _get("bunny.ctm", progress).then((responseText) {
    progress.innerHTML = "Unpacking...";
    loaded(responseText);
    progress.innerHTML = "";
  });
  
}

echo() {
  port.receive((msg, reply) {
    reply.send("I received: $msg");
  });
}

worker() {
  port.receive((data, reply) {
    print("Got some data");
    reply.send( new CTM.File( new CTM.Stream(data) ) );
  });
}

loaded(responseText){
  /*
  var workerPort = spawnFunction(worker);
  workerPort.call(responseText).then((reply) {
      file = reply;
      webGLStart();
  });*/
      
  file = new CTM.File( new CTM.Stream(responseText) );
  webGLStart();
}

webGLStart(){
  canvas = document.query("#canvas") ;

  initGL(canvas);
  initBoundingBox();
  initOffsets();
  initShaders();
  initBuffers();

  gl.clearColor(1.0, 1.0, 1.0, 1.0);
  gl.enable(WebGLRenderingContext.DEPTH_TEST);
  gl.viewport(0, 0, canvas.width, canvas.height);

  translationMatrix.setValues(0, 0, 0);
  rotationMatrix.identity();

  canvas.on.mouseDown.add(handleMouseDown);
  document.on.mouseUp.add(handleMouseUp);
  document.on.mouseMove.add(handleMouseMove);
  document.on.mouseWheel.add(handleMouseWheel);
  
  window.on["DOMMouseScroll"].add(handleMouseWheel, false); 
  
  tick(0);
}

initGL(canvas){
  try{
    gl = canvas.getContext("experimental-webgl");
  }catch(e){ }
  if (gl == null){
    window.alert("Could not initialise WebGL, sorry :-(");
  }
}
 
initBoundingBox(){
  var v = file.body.vertices;
  var x = double.INFINITY, y = double.INFINITY, z = double.INFINITY;
  var X = double.NEGATIVE_INFINITY, Y = double.NEGATIVE_INFINITY, Z = double.NEGATIVE_INFINITY;
  
  for (var i = 0; i < v.length; i += 3){
    if (v[i] < x) x = v[i];
    if (v[i+1] < y) y = v[i+1];
    if (v[i+2] < z) z = v[i+2];

    if (v[i] > X) X = v[i];
    if (v[i+1] > Y) Y = v[i+1];
    if (v[i+2] > Z) Z = v[i+2];
  }

  for (var i = 0; i < v.length; i += 3){
    v[i] = -( (X-x)/2 ) + ( v[i] - x);
    v[i+1] = -( (Y-y)/2 ) + ( v[i+1] - y);
    v[i+2] = -( (Z-z)/2 ) + ( v[i+2] - z);
  }
}

initOffsets(){
  offsets = [];
  var indices = file.body.indices;
  var start = 0;
  var min = file.body.vertices.length;
  var max = 0;
  var minPrev = min;
  
  var i;
  
  for (i = 0; i < indices.length;){

    for (var j = 0; j < 3; ++ j){
      var idx = indices[i ++];
    
      if (idx < min) min = idx;
      if (idx > max) max = idx;
    }
    
    if (max - min > 65535){
      i -= 3;

      for (var k = start; k < i; ++ k){
        indices[k] -= minPrev;
      }
      offsets.add( {"start": start, "count": i - start, "index": minPrev} );
      
      start = i;
      min = file.body.vertices.length;
      max = 0;
    }
    
    minPrev = min;
  }

  for (var k = start; k < i; ++ k){
    indices[k] -= minPrev;
  }
  offsets.add( {"start": start, "count": i - start, "index": minPrev} );
}
 
int vertexPositionAttribute, vertexColorAttribute;
WebGLUniformLocation pMatrixUniform, mvMatrixUniform;

initShaders(){
  var fragmentShader = gl.createShader(WebGLRenderingContext.FRAGMENT_SHADER);
  gl.shaderSource(fragmentShader, shaderFS);
  gl.compileShader(fragmentShader);

  var vertexShader = gl.createShader(WebGLRenderingContext.VERTEX_SHADER);
  gl.shaderSource(vertexShader, shaderVS);
  gl.compileShader(vertexShader);
  
  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);
  gl.useProgram(shaderProgram);

  
  vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  gl.enableVertexAttribArray(vertexPositionAttribute);

  vertexColorAttribute = gl.getAttribLocation(shaderProgram, "aVertexColor");
  gl.enableVertexAttribArray(vertexColorAttribute);

  pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix");
  mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix");
  
}

int vertexIndexBufferItemSize, vertexIndexBufferNumItems;
int vertexPositionBufferItemSize, vertexPositionBufferNumItems;
int vertexColorBufferItemSize, vertexColorBufferNumItems;

initBuffers(){
  vertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, vertexIndexBuffer);
  gl.bufferData(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
    new Uint16Array.fromList(file.body.indices), WebGLRenderingContext.STATIC_DRAW);
  vertexIndexBufferItemSize = 1;
  vertexIndexBufferNumItems = file.body.indices.length;

  vertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexPositionBuffer);
  gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER,
    file.body.vertices, WebGLRenderingContext.STATIC_DRAW);
  vertexPositionBufferItemSize = 3;
  vertexPositionBufferNumItems = file.body.vertices.length;

  var vertexColors;
  if (file.body.attrMaps != null) {
    vertexColors = file.body.attrMaps[0]["attr"];      
  } else {
    vertexColors = new Float32Array(file.body.vertices.length * 4);
    for (var i = 0; i < file.body.vertices.length; i ++) {
            vertexColors[i] = 0;
            vertexColors[i + 1] = 0;
            vertexColors[i + 2] = 0;
            vertexColors[i + 3] = 0;
    }
  }

  
  vertexColorBuffer = gl.createBuffer();
  gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexColorBuffer);
  gl.bufferData(WebGLRenderingContext.ARRAY_BUFFER, vertexColors, WebGLRenderingContext.STATIC_DRAW);
  vertexColorBufferItemSize = 4;
  vertexColorBufferNumItems = vertexColors.length;
}

tick(int time){
  drawScene();
  window.requestAnimationFrame(tick);
}

drawScene(){
  // gl.clearColor(1, 1, 1, 1);
  gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT | WebGLRenderingContext.DEPTH_BUFFER_BIT);

  pMatrix.makePerspective(45, canvas.width / canvas.height, 0.1, 100.0);
  pMatrix.translate(new Vector3(0.0, 0, -0.6));

  mvMatrix.identity();
  mvMatrix.translate(translationMatrix);
  mvMatrix.multiplySelf(rotationMatrix);

  gl.uniformMatrix4fv(pMatrixUniform, false, pMatrix.elements);
  gl.uniformMatrix4fv(mvMatrixUniform, false, mvMatrix.elements);
  
  //var normalMatrix = mvMatrix.toInverseMat3();
  //normalMatrix.transpose();
  //gl.uniformMatrix3fv(nMatrixUniform, false, normalMatrix);

  for (var i = 0; i < offsets.length; ++ i){
    gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexPositionBuffer);
    gl.vertexAttribPointer(vertexPositionAttribute,
      vertexPositionBufferItemSize, WebGLRenderingContext.FLOAT, false, 0, offsets[i]["index"] * 4 * 3);

    gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, vertexColorBuffer);
    gl.vertexAttribPointer(vertexColorAttribute,
      vertexColorBufferItemSize, WebGLRenderingContext.FLOAT, false, 0, offsets[i]["index"] * 4 * 4);

    gl.bindBuffer(WebGLRenderingContext.ELEMENT_ARRAY_BUFFER, vertexIndexBuffer);
    gl.drawElements(WebGLRenderingContext.TRIANGLES, offsets[i]["count"], WebGLRenderingContext.UNSIGNED_SHORT, offsets[i]["start"] * 2); // 2 = uint16
  }
}

degToRad(degrees) => degrees * Math.PI / 180;

handleMouseWheel(event){
  var delta = event.wheelDelta | -event.detail;
  if (delta < 0){
    translationMatrix.elements[2] -= .05;
  }else{
    translationMatrix.elements[2] += .05;
  }
}
  
handleMouseDown(event){
  mouseDown = true;
  lastMouseX = event.clientX;
  lastMouseY = event.clientY;
}

handleMouseUp(event){
  mouseDown = false;
}

handleMouseMove(MouseEvent event){
  if (mouseDown){
    var newX = event.clientX;
    var newY = event.clientY;

    var newRotationMatrix = new Matrix4();
    newRotationMatrix.identity();
    
    var deltaX = newX - lastMouseX;
    newRotationMatrix.rotate(degToRad(deltaX / 5), new Vector3(0, 1, 0));

    var deltaY = newY - lastMouseY;
    newRotationMatrix.rotate(degToRad(deltaY / 5), new Vector3(1, 0, 0));

    rotationMatrix.multiply(newRotationMatrix, rotationMatrix);

    lastMouseX = newX;
    lastMouseY = newY;
  }
}
