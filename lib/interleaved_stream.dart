class InterleavedStream implements LZMA.OutStream {
  html.Uint8Array data;
  int offset;
  int count;
  int length;
  
  InterleavedStream(data, count) {
    this.data = new html.Uint8Array.fromBuffer(data.buffer, data.byteOffset, data.byteLength);
    this.offset = isLittleEndian? 3: 0;
    this.count = count * 4;
    this.length = this.data.length;
  }

  void writeByte(final int value){
    data[offset] = value;
    
    offset += count;
    if (offset >= length){
    
      offset -= length - 4;
      if (offset >= count){
      
        offset -= count + (isLittleEndian? 1: -1);
      }
    }
  }
}