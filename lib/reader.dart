class Reader {
  factory Reader.forFile(File file) {
    switch(file.header.compressionMethod){
      case CompressionMethod.RAW:
        return new ReaderRAW();
      case CompressionMethod.MG1:
        return new ReaderMG1();
      case CompressionMethod.MG2:
        return new ReaderMG2();
    }
  }
  
  Reader();
  
  abstract read(Stream stream, FileBody body);

}
