class ReaderMG2 extends Reader {

  FileMG2Header MG2Header;
  
  read(Stream stream, FileBody body){
    MG2Header = new FileMG2Header(stream);
    
    readVertices(stream, body.vertices);
    readIndices(stream, body.indices);
    
    if (body.normals != null){
      readNormals(stream, body);
    }
    if (body.uvMaps != null){
      readUVMaps(stream, body.uvMaps);
    }
    if (body.attrMaps != null){
      readAttrMaps(stream, body.attrMaps);
    }
  }
  
  readVertices(Stream stream, html.Float32Array vertices){
    stream.readInt32(); //magic "VERT"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(vertices, 3);
    LZMA.decompress(stream, interleaved, interleaved.data.length);
    
    var gridIndices = this.readGridIndices(stream, vertices);
    
    restoreVertices(vertices, MG2Header, gridIndices, MG2Header.vertexPrecision);
  }
  
  readGridIndices(Stream stream, html.Float32Array vertices){
    stream.readInt32(); //magic "GIDX"
    stream.readInt32(); //packed size
    
    var gridIndices = new html.Uint32Array( (vertices.length / 3).toInt() );
    
    var interleaved = new InterleavedStream(gridIndices, 1);
    LZMA.decompress(stream, interleaved, interleaved.data.length);
    
    restoreGridIndices(gridIndices, gridIndices.length);
    
    return gridIndices;
  }
  
  readIndices(stream, indices){
    stream.readInt32(); //magic "INDX"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(indices, 3);
    LZMA.decompress(stream, interleaved, interleaved.data.length);
  
    restoreIndices(indices, indices.length);
  }
  
  readNormals(stream, body){
    stream.readInt32(); //magic "NORM"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(body.normals, 3);
    LZMA.decompress(stream, interleaved, interleaved.data.length);
  
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
      LZMA.decompress(stream, interleaved, interleaved.data.length);
      
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
      LZMA.decompress(stream, interleaved, interleaved.data.length);
      
      restoreMap(attrMaps[i].attr, 4, precision);
    }
  }
}

class FileMG2Header {
  // Float32
  num vertexPrecision,
      normalPrecision,
      lowerBoundx,
      lowerBoundy,
      lowerBoundz,
      higherBoundx,
      higherBoundy,
      higherBoundz;
  
  // Int32
  int divx, divy, divz;
  
  num sizex, sizey, sizez;
  
  
  FileMG2Header (Stream stream){
    stream.readInt32(); //magic "MG2H"
    vertexPrecision = stream.readFloat32();
    normalPrecision = stream.readFloat32();
    lowerBoundx = stream.readFloat32();
    lowerBoundy = stream.readFloat32();
    lowerBoundz = stream.readFloat32();
    higherBoundx = stream.readFloat32();
    higherBoundy = stream.readFloat32();
    higherBoundz = stream.readFloat32();
    divx = stream.readInt32().toInt();
    divy = stream.readInt32().toInt();
    divz = stream.readInt32().toInt();
    
    sizex = (higherBoundx - lowerBoundx) / divx;
    sizey = (higherBoundy - lowerBoundy) / divy;
    sizez = (higherBoundz - lowerBoundz) / divz;
  }
}
