class ReaderRAW extends Reader {

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
    stream.readArrayInt32(indices);
  }
  
  readVertices(stream, vertices){
    stream.readInt32(); //magic "VERT"
    stream.readArrayFloat32(vertices);
  }
  
  readNormals(stream, normals){
    stream.readInt32(); //magic "NORM"
    stream.readArrayFloat32(normals);
  }
  
  readUVMaps(stream, uvMaps){
    var i = 0;
    for (; i < uvMaps.length; ++ i){
      stream.readInt32(); //magic "TEXC"
  
      uvMaps[i].name = stream.readString();
      uvMaps[i].filename = stream.readString();
      stream.readArrayFloat32(uvMaps[i].uv);
    }
  }
  
  readAttrMaps(stream, attrMaps){
    var i = 0;
    for (; i < attrMaps.length; ++ i){
      stream.readInt32(); //magic "ATTR"
  
      attrMaps[i].name = stream.readString();
      stream.readArrayFloat32(attrMaps[i].attr);
    }
  }
}

