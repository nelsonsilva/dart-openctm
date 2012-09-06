class Stream implements LZMA.InStream {
  var data;
  var length;
  var offset;
  
  Stream(this.data) : offset = 0 { length = data.length; }
  
  // Allows negative exponents
  static _pow(base, exponent) {
    var isNegative = (exponent < 0);
    var exp = isNegative ? exponent.abs() : exponent;
    var res = Math.pow(base, exp);
    return isNegative ? (1 / res) : res;
  }
  
  static num _A, _B;
  static get TWO_POW_MINUS23 => _A == null ? _A =   _pow(2, -23) : _A;
  static get TWO_POW_MINUS126 => _B == null ? _B =  _pow(2, -126) : _B;

  int readByte() => data.charCodeAt(offset ++) & 0xff;

  readInt32(){
    var i = readByte();
    i |= readByte() << 8;
    i |= readByte() << 16;
    return i | (readByte() << 24);
  }
  
  num readFloat32(){
    int m = readByte();
    m += readByte() << 8;
  
    int b1 = readByte();
    int b2 = readByte();
  
    m += (b1 & 0x7f) << 16; 

    var e = ( (b2 & 0x7f) << 1) | new int32.fromInt(b1 & 0x80).shiftRightUnsigned(7).toInt();
    var s = (b2 & 0x80) > 0 ? -1: 1;
  
    if (e == 255){
      return m != 0? double.NAN : s * double.INFINITY;
    }
    if (e > 0){
      return s * (1 + (m.toInt() * TWO_POW_MINUS23) ) * _pow(2, e - 127);
    }
    if (m != 0){
      return s * m.toInt() * TWO_POW_MINUS126;
    }
    return s * 0;
  }

  readString(){
    num len = readInt32();
  
    offset += len;
  
    // substr(offset - len, len);
    return data.substring(offset - len, offset);
  }
  
 List<int> readArrayInt32(List<int>  array){
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
