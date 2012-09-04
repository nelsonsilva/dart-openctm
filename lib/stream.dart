class Stream implements LZMA.InStream {
  var data;
  var offset;
  
  Stream(data) : offset = 0;
  
  static num _A, _B;
  static get TWO_POW_MINUS23 => _A == null ? _A = Math.pow(2, -23) : _A;
  static get TWO_POW_MINUS126 => _B == null ? _B = Math.pow(2, -126) : _B;

  readByte() => data.charCodeAt(offset ++) & 0xff;

  readInt32(){
    var i = readByte();
    i |= readByte() << 8;
    i |= readByte() << 16;
    return i | (readByte() << 24);
  }

  readFloat32(){
    var m = readByte();
    m += readByte() << 8;
  
    var b1 = readByte();
    var b2 = readByte();
  
    m += (b1 & 0x7f) << 16; 
    var e = ( (b2 & 0x7f) << 1) | ( (b1 & 0x80) >>> 7);
    var s = b2 & 0x80? -1: 1;
  
    if (e === 255){
      return m !== 0? double.NAN : s * double.INFINITY;
    }
    if (e > 0){
      return s * (1 + (m * TWO_POW_MINUS23) ) * Math.pow(2, e - 127);
    }
    if (m !== 0){
      return s * m * TWO_POW_MINUS126;
    }
    return s * 0;
  }

  readString(){
    var len = readInt32();
  
    offset += len;
  
    return data.substr(offset - len, len);
  }
  
  readArrayInt32(array){
    var i = 0, len = array.length;
    
    while(i < len){
      array[i ++] = readInt32();
    }
  
    return array;
  }
  
  readArrayFloat32(array){
    var i = 0, len = array.length;
  
    while(i < len){
      array[i ++] = readFloat32();
    }
  
    return array;
  }
}
