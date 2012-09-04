class ReaderMG1 extends Reader {

  read(stream, body){
    readIndices(stream, body.indices);
    readVertices(stream, body.vertices);
    
    if (body.normals){
      readNormals(stream, body.normals);
    }
    if (body.uvMaps){
      readUVMaps(stream, body.uvMaps);
    }
    if (body.attrMaps){
      readAttrMaps(stream, body.attrMaps);
    }
  }
  
  readIndices(stream, indices){
    stream.readInt32(); //magic "INDX"
    stream.readInt32(); //packed size
    
    var interleaved = new InterleavedStream(indices, 3);
    LZMA.decompress(stream, interleaved);
  
    restoreIndices(indices, indices.length);
  }
  
  readVertices(stream, vertices){
    stream.readInt32(); //magic "VERT"
    stream.readInt32(); //packed size
    
    var interleaved = new InterleavedStream(vertices, 1);
    LZMA.decompress(stream, interleaved);
  }
  
  readNormals(stream, normals){
    stream.readInt32(); //magic "NORM"
    stream.readInt32(); //packed size
  
    var interleaved = new InterleavedStream(normals, 3);
    LZMA.decompress(stream, interleaved);
  }
  
  readUVMaps(stream, uvMaps){
    var i = 0;
    for (; i < uvMaps.length; ++ i){
      stream.readInt32(); //magic "TEXC"
  
      uvMaps[i].name = stream.readString();
      uvMaps[i].filename = stream.readString();
      
      stream.readInt32(); //packed size
  
      var interleaved = new InterleavedStream(uvMaps[i].uv, 2);
      
      LZMA.decompress(stream, interleaved);
    }
  }
  
  readAttrMaps(stream, attrMaps){
    var i = 0;
    for (; i < attrMaps.length; ++ i){
      stream.readInt32(); //magic "ATTR"
  
      attrMaps[i].name = stream.readString();
      
      stream.readInt32(); //packed size
  
      var interleaved = new InterleavedStream(attrMaps[i].attr, 4);
      LZMA.decompress(stream, interleaved);
    }
  }
}
