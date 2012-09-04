#import("dart:html");
#import("dart:math", prefix:'Math');

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

var request;
var file;
var gl;
var shaderProgram;
var mvMatrix;
var pMatrix;
var vertexIndexBuffer;
var vertexPositionBuffer;
var vertexColorBuffer;
var offsets = [];
var mouseDown = false;
var lastMouseX;
var lastMouseY;
var translationMatrix = vec3.create();
var rotationMatrix = mat4.create();

window.requestAnimFrame = (function(){
  return window.requestAnimationFrame ||
         window.webkitRequestAnimationFrame ||
         window.mozRequestAnimationFrame ||
         window.oRequestAnimationFrame ||
         window.msRequestAnimationFrame ||
         function(callback, element){
           window.setTimeout(callback, 1000/60);
         };
})(); 

function formatNumber(numero, decimales){
  var pot = Math.pow(10, decimales);
  return parseInt(numero * pot) / pot;
}

main(){
  mvMatrix = new Matrix4();
  pMatrix = new Matrix4();
  translationMatrix = new Vector3();
  rotationMatrix = new Matrix4();

  
  request = new XMLHttpRequest();
  request.open("GET", "male02.ctm", true);
  request.overrideMimeType("text/plain; charset=x-user-defined");
  request.on.readyStateChange.add(e){
    if (request.readyState == 3 || request.readyState == 4){
      document.query("#progress").innerHTML = "Downloading... "
        + formatNumber(this.responseText.length / 1048576, 2) + " MB";
    }
    if (this.readyState == 4 && (this.status == 200 || this.status == 0) ){
      document.getElementById("progress").innerHTML = "Unpacking...";
      setTimeout(loaded, 1);
    }
  }
  request.send();
}

function loaded(){
  if ( navigator.userAgent.indexOf("WebKit") == -1){
    var worker = new Worker("loader.js");
    
    worker.onmessage = function(event){
      file = event.data;
      webGLStart();
      document.getElementById("progress").innerHTML = "";
    };
    
    worker.postMessage(request.responseText);
    
  }else{
      file = new CTM.File( new CTM.Stream(request.responseText) );
      webGLStart();
      document.getElementById("progress").innerHTML = "";
  }
}

function webGLStart(){
  var canvas = document.getElementById("canvas") ;

  initGL(canvas);
  initBoundingBox();
  initOffsets();
  initShaders();
  initBuffers();

  gl.clearColor(1.0, 1.0, 1.0, 1.0);
  gl.enable(gl.DEPTH_TEST);
  gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);

  vec3.set(translationMatrix, [0, 0, 0]);
  mat4.identity(rotationMatrix);

  canvas.onmousedown = handleMouseDown;
  document.onmouseup = handleMouseUp;
  document.onmousemove = handleMouseMove;
  document.onmousewheel = handleMouseWheel;
  
  window.addEventListener("DOMMouseScroll", handleMouseWheel, false); 
  
  tick();
}

function initGL(canvas){
  try{
    gl = canvas.getContext("experimental-webgl");
    gl.viewportWidth = canvas.width;
    gl.viewportHeight = canvas.height;
  }catch(e){
  }
  if (!gl){
    alert("Could not initialise WebGL, sorry :-(");
  }
}
 
function initBoundingBox(){
  var v = file.body.vertices;
  var x = Infinity, y = Infinity, z = Infinity;
  var X = -Infinity, Y = -Infinity, Z = -Infinity;
  
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

function initOffsets(){
  var indices = file.body.indices;
  var start = 0;
  var min = file.body.vertices.length;
  var max = 0;
  var minPrev = min;
  
  for (var i = 0; i < indices.length;){

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
      offsets.push( {start: start, count: i - start, index: minPrev} );
      
      start = i;
      min = file.body.vertices.length;
      max = 0;
    }
    
    minPrev = min;
  }

  for (var k = start; k < i; ++ k){
    indices[k] -= minPrev;
  }
  offsets.push( {start: start, count: i - start, index: minPrev} );
}
 
function initShaders(){
  var fragmentShader = getShader(gl, "shader-fs");
  var vertexShader = getShader(gl, "shader-vs");

  shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);
  gl.useProgram(shaderProgram);

  shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "aVertexPosition");
  gl.enableVertexAttribArray(shaderProgram.vertexPositionAttribute);

  shaderProgram.vertexColorAttribute = gl.getAttribLocation(shaderProgram, "aVertexColor");
  gl.enableVertexAttribArray(shaderProgram.vertexColorAttribute);

  shaderProgram.pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix");
  shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix");
}

function getShader(gl, id){
  var shaderScript = document.getElementById(id);

  var str = "";
  var node = shaderScript.firstChild;
  while(node){
    if (node.nodeType == 3){
      str += node.textContent;
    }
    node = node.nextSibling;
  }

  var shader;
  if (shaderScript.type == "x-shader/x-fragment"){
    shader = gl.createShader(gl.FRAGMENT_SHADER);
  }else if (shaderScript.type == "x-shader/x-vertex"){
    shader = gl.createShader(gl.VERTEX_SHADER);
  }
  
  gl.shaderSource(shader, str);
  gl.compileShader(shader);

  return shader;
}

function initBuffers(){
  vertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, vertexIndexBuffer);
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,
    new Uint16Array(file.body.indices), gl.STATIC_DRAW);
  vertexIndexBuffer.itemSize = 1;
  vertexIndexBuffer.numItems = file.body.indices.length;

  vertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer);
  gl.bufferData(gl.ARRAY_BUFFER,
    file.body.vertices, gl.STATIC_DRAW);
  vertexPositionBuffer.itemSize = 3;
  vertexPositionBuffer.numItems = file.body.vertices.length;

  vertexColorBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexColorBuffer);
  gl.bufferData(gl.ARRAY_BUFFER,
    file.body.attrMaps[0].attr, gl.STATIC_DRAW);
  vertexColorBuffer.itemSize = 4;
  vertexColorBuffer.numItems = file.body.attrMaps[0].attr.length;
}

function tick(){
  drawScene();
  requestAnimFrame(tick);
}

function drawScene(){
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  mat4.perspective(45, gl.viewportWidth / gl.viewportHeight, 0.1, 100.0, pMatrix);
  mat4.translate(pMatrix, [0.0, 0, -0.6]);

  mat4.identity(mvMatrix);
  mat4.translate(mvMatrix, translationMatrix);
  mat4.multiply(mvMatrix, rotationMatrix);

  gl.uniformMatrix4fv(shaderProgram.pMatrixUniform, false, pMatrix);
  gl.uniformMatrix4fv(shaderProgram.mvMatrixUniform, false, mvMatrix);
  
  var normalMatrix = mat3.create();
  mat4.toInverseMat3(mvMatrix, normalMatrix);
  mat3.transpose(normalMatrix);
  gl.uniformMatrix3fv(shaderProgram.nMatrixUniform, false, normalMatrix);

  for (var i = 0; i < offsets.length; ++ i){
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexPositionBuffer);
    gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute,
      vertexPositionBuffer.itemSize, gl.FLOAT, false, 0, offsets[i].index * 4 * 3);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexColorBuffer);
    gl.vertexAttribPointer(shaderProgram.vertexColorAttribute,
      vertexColorBuffer.itemSize, gl.FLOAT, false, 0, offsets[i].index * 4 * 4);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, vertexIndexBuffer);
    gl.drawElements(gl.TRIANGLES, offsets[i].count, gl.UNSIGNED_SHORT, offsets[i].start * 2); // 2 = uint16
  }
}

function degToRad(degrees){
  return degrees * Math.PI / 180;
}

function handleMouseWheel(event){
  var delta = event.wheelDelta | -event.detail;
  if (delta < 0){
    translationMatrix[2] -= .05;
  }else{
    translationMatrix[2] += .05;
  }
}
  
function handleMouseDown(event){
  mouseDown = true;
  lastMouseX = event.clientX;
  lastMouseY = event.clientY;
}

function handleMouseUp(event){
  mouseDown = false;
}

function handleMouseMove(event){
  if (mouseDown){
    var newX = event.clientX;
    var newY = event.clientY;

    var newRotationMatrix = mat4.create();
    mat4.identity(newRotationMatrix);
    
    var deltaX = newX - lastMouseX;
    mat4.rotate(newRotationMatrix, degToRad(deltaX / 5), [0, 1, 0]);

    var deltaY = newY - lastMouseY;
    mat4.rotate(newRotationMatrix, degToRad(deltaY / 5), [1, 0, 0]);

    mat4.multiply(newRotationMatrix, rotationMatrix, rotationMatrix);

    lastMouseX = newX
    lastMouseY = newY;
  }
}
