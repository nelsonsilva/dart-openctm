class ReaderMG2 extends Reader {

  FileMG2Header MG2Header;
  
  read(stream, body){
    MG2Header = new FileMG2Header(stream);
    
    readVertices(stream, body.vertices);
    readIndices(stream, body.indices);
    
    if (body.normals){
      readNormals(stream, body);
    }
    if (body.uvMaps){
      readUVMaps(stream, body.uvMaps);
    }
    if (body.attrMaps){
      readAttrMaps(stream, body.attrMaps);
    }
  }
  
  readVertices(stream, vertices){
    stream.readInt32(); //magic "VERT"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(vertices, 3);
    LZMA.decompress(stream, interleaved);
    
    var gridIndices = this.readGridIndices(stream, vertices);
    
    restoreVertices(vertices, MG2Header, gridIndices, MG2Header.vertexPrecision);
  }
  
  readGridIndices(stream, vertices){
    stream.readInt32(); //magic "GIDX"
    stream.readInt32(); //packed size
    
    var gridIndices = new Uint32Array(vertices.length / 3);
    
    var interleaved = new InterleavedStream(gridIndices, 1);
    LZMA.decompress(stream, interleaved);
    
    restoreGridIndices(gridIndices, gridIndices.length);
    
    return gridIndices;
  }
  
  readIndices(stream, indices){
    stream.readInt32(); //magic "INDX"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(indices, 3);
    LZMA.decompress(stream, interleaved);
  
    restoreIndices(indices, indices.length);
  }
  
  readNormals(stream, body){
    stream.readInt32(); //magic "NORM"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(body.normals, 3);
    LZMA.decompress(stream, interleaved);
  
    var smooth = calcSmoothNormals(body.indices, body.vertices);
  
    restoreNormals(body.normals, smooth, MG2Header.normalPrecision);
  }
  
  readUVMaps(stream, uvMaps){
    var i = 0;
    for (; i < uvMaps.length; ++ i){
      stream.readInt32(); //magic "TEXC"
  
      uvMaps[i].name = stream.readString();
      uvMaps[i].filename = stream.readString();
      
      var precision = stream.readFloat32();
      
      stream.readInt32(); //packed size
  
      var interleaved = new InterleavedStream(uvMaps[i].uv, 2);
      LZMA.decompress(stream, interleaved);
      
      restoreMap(uvMaps[i].uv, 2, precision);
    }
  }
  
  readAttrMaps(stream, attrMaps){
    var i = 0;
    for (; i < attrMaps.length; ++ i){
      stream.readInt32(); //magic "ATTR"
  
      attrMaps[i].name = stream.readString();
      
      var precision = stream.readFloat32();
      
      stream.readInt32(); //packed size
  
      var interleaved = new InterleavedStream(attrMaps[i].attr, 4);
      LZMA.decompress(stream, interleaved);
      
      restoreMap(attrMaps[i].attr, 4, precision);
    }
  }
}

class FileMG2Header {
  // Float32
  var vertexPrecision,
      normalPrecision,
      lowerBoundx,
      lowerBoundy,
      lowerBoundz,
      higherBoundx,
      higherBoundy,
      higherBoundz;
  
  // Int32
  var divx, divy, divz;
  
  var sizex, sizey, sizez;
  
  
  FileMG2Header (stream){
    stream.readInt32(); //magic "MG2H"
    vertexPrecision = stream.readFloat32();
    normalPrecision = stream.readFloat32();
    lowerBoundx = stream.readFloat32();
    lowerBoundy = stream.readFloat32();
    lowerBoundz = stream.readFloat32();
    higherBoundx = stream.readFloat32();
    higherBoundy = stream.readFloat32();
    higherBoundz = stream.readFloat32();
    divx = stream.readInt32();
    divy = stream.readInt32();
    divz = stream.readInt32();
    
    sizex = (higherBoundx - lowerBoundx) / divx;
    sizey = (higherBoundy - lowerBoundy) / divy;
    sizez = (higherBoundz - lowerBoundz) / divz;
  }
}
