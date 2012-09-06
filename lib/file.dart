class File {
 
  FileHeader header;
  FileBody body;
  var _reader;
  
  File(Stream stream) {
    load(stream);
  }

  load(Stream stream){
    header = new FileHeader(stream);
  
    body = new FileBody(header);
    
    var reader = new Reader.forFile(this);
    reader.read(stream, body);
  }
}

class FileHeader {
  var fileFormat,
      compressionMethod,
      vertexCount,
      triangleCount,
      uvMapCount,
      attrMapCount,
      flags;
  String comment;

  FileHeader(stream) {
    stream.readInt32(); //magic "OCTM"
    fileFormat = stream.readInt32();
    compressionMethod = stream.readInt32();
    vertexCount = stream.readInt32();
    triangleCount = stream.readInt32();
    uvMapCount = stream.readInt32();
    attrMapCount = stream.readInt32();
    flags = stream.readInt32();
    comment = stream.readString();
  }

  bool get hasNormals => (flags & Flags.NORMALS) > 0;
}

class FileBody {
  
  Uint32Array indices;
  Float32Array vertices,
               normals;

  List<Map<String, Float32Array>> uvMaps, attrMaps;
  
  FileBody(FileHeader header) {
    var i = header.triangleCount * 3,
        v = header.vertexCount * 3,
        n = header.hasNormals ? header.vertexCount * 3: 0,
        u = header.vertexCount * 2,
        a = header.vertexCount * 4,
        j = 0;
  
    var data = new ArrayBuffer(
      (i + v + n + (u * header.uvMapCount) + (a * header.attrMapCount) ) * 4);
  
    indices = new Uint32Array.fromBuffer(data, 0, i);
  
    vertices = new Float32Array.fromBuffer(data, i * 4, v);
  
    if ( header.hasNormals ){
      normals = new Float32Array.fromBuffer(data, (i + v) * 4, n);
    }
    
    if (header.uvMapCount > 0){
      uvMaps = new List(header.uvMapCount);
      for (j = 0; j < header.uvMapCount; ++ j){
        uvMaps[j] = {"uv": new Float32Array.fromBuffer(data, (i + v + n + (j * u) ) * 4, u) };
      }
    }
    
    if (header.attrMapCount > 0){
      attrMaps = new List(header.attrMapCount);
      for (j = 0; j < header.attrMapCount; ++ j){
        attrMaps[j] = {"attr": new Float32Array.fromBuffer(data,
          (i + v + n + (u * header.uvMapCount) + (j * a) ) * 4, a) };
      }
    }
  }
}