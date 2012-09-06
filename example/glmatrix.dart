class Matrix3 {
  Float32Array elements;
  
  Matrix3() : elements = new Float32Array(9);
 
  Matrix3 transpose() {
    var tmp, m = elements;

    tmp = m[1]; m[1] = m[3]; m[3] = tmp;
    tmp = m[2]; m[2] = m[6]; m[6] = tmp;
    tmp = m[5]; m[5] = m[7]; m[7] = tmp;

    return this;
  }
  
  operator [](index) => elements[index];
}
  
  
class Matrix4 {
  Float32Array elements;
  
  Matrix4() : elements = new Float32Array(16);
  
  Matrix4 identity() {
    setValues(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );

    return this;
  }
  
  Matrix4 setValues( num n11, num n12, num n13, num n14, 
                     num n21, num n22, num n23, num n24, 
                     num n31, num n32, num n33, num n34, 
                     num n41, num n42, num n43, num n44 ) {
    var te = this.elements;

    te[0] = n11; te[4] = n12; te[8] = n13; te[12] = n14;
    te[1] = n21; te[5] = n22; te[9] = n23; te[13] = n24;
    te[2] = n31; te[6] = n32; te[10] = n33; te[14] = n34;
    te[3] = n41; te[7] = n42; te[11] = n43; te[15] = n44;

    return this;
  }
  
  Matrix4 translate( Vector3 v ) {
    var te = elements;
    var x = v.x, y = v.y, z = v.z;

    te[12] = te[0] * x + te[4] * y + te[8] * z + te[12];
    te[13] = te[1] * x + te[5] * y + te[9] * z + te[13];
    te[14] = te[2] * x + te[6] * y + te[10] * z + te[14];
    te[15] = te[3] * x + te[7] * y + te[11] * z + te[15];

    return this;
  }
  
  Matrix3 toInverseMat3() {
    // Cache the matrix values (makes for huge speed increases!)
    var a00 = elements[0], a01 = elements[1], a02 = elements[2],
        a10 = elements[4], a11 = elements[5], a12 = elements[6],
        a20 = elements[8], a21 = elements[9], a22 = elements[10],

        b01 = a22 * a11 - a12 * a21,
        b11 = -a22 * a10 + a12 * a20,
        b21 = a21 * a10 - a11 * a20,

        d = a00 * b01 + a01 * b11 + a02 * b21,
        id;

    if (!d) { return null; }
    id = 1 / d;

    var dest = new Matrix3();

    dest[0] = b01 * id;
    dest[1] = (-a22 * a01 + a02 * a21) * id;
    dest[2] = (a12 * a01 - a02 * a11) * id;
    dest[3] = b11 * id;
    dest[4] = (a22 * a00 - a02 * a20) * id;
    dest[5] = (-a12 * a00 + a02 * a10) * id;
    dest[6] = b21 * id;
    dest[7] = (-a21 * a00 + a01 * a20) * id;
    dest[8] = (a11 * a00 - a01 * a10) * id;

    return dest;
  }

  
  Matrix4 multiply( Matrix4 a, Matrix4 b ) {
    var ae = a.elements;
    var be = b.elements;
    var te = elements;

    var a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    var a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    var a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    var a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    var b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    var b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    var b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    var b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
    
    return this;
  }

  Matrix4 rotate( num angle, Vector3 axis ) {
    var te = elements;
    
    num x = axis.x,
      y = axis.y,
      z = axis.z,
      n = Math.sqrt(x * x + y * y + z * z);

    x /= n;
    y /= n;
    z /= n;

    num xx = x * x,
      yy = y * y,
      zz = z * z,
      c = Math.cos(angle),
      s = Math.sin(angle),
      oneMinusCosine = 1 - c,
      xy = x * y * oneMinusCosine,
      xz = x * z * oneMinusCosine,
      yz = y * z * oneMinusCosine,
      xs = x * s,
      ys = y * s,
      zs = z * s,

      r11 = xx + (1 - xx) * c,
      r21 = xy + zs,
      r31 = xz - ys,
      r12 = xy - zs,
      r22 = yy + (1 - yy) * c,
      r32 = yz + xs,
      r13 = xz + ys,
      r23 = yz - xs,
      r33 = zz + (1 - zz) * c;

    var m11 = te[0], m21 = te[1], m31 = te[2], m41 = te[3];
    var m12 = te[4], m22 = te[5], m32 = te[6], m42 = te[7];
    var m13 = te[8], m23 = te[9], m33 = te[10], m43 = te[11];
    var m14 = te[12], m24 = te[13], m34 = te[14], m44 = te[15];

    te[0] = r11 * m11 + r21 * m12 + r31 * m13;
    te[1] = r11 * m21 + r21 * m22 + r31 * m23;
    te[2] = r11 * m31 + r21 * m32 + r31 * m33;
    te[3] = r11 * m41 + r21 * m42 + r31 * m43;

    te[4] = r12 * m11 + r22 * m12 + r32 * m13;
    te[5] = r12 * m21 + r22 * m22 + r32 * m23;
    te[6] = r12 * m31 + r22 * m32 + r32 * m33;
    te[7] = r12 * m41 + r22 * m42 + r32 * m43;

    te[8] = r13 * m11 + r23 * m12 + r33 * m13;
    te[9] = r13 * m21 + r23 * m22 + r33 * m23;
    te[10] = r13 * m31 + r23 * m32 + r33 * m33;
    te[11] = r13 * m41 + r23 * m42 + r33 * m43;


    return this;
  }
  
  Matrix4 multiplySelf( Matrix4 m ) => multiply( this, m );
  
  Matrix4 makeFrustum( num left, num right, num bottom, num top, num near, num far ) {
    var te = elements;
    
    num x, y, a, b, c, d;

    x = 2 * near / ( right - left );
    y = 2 * near / ( top - bottom );

    a = ( right + left ) / ( right - left );
    b = ( top + bottom ) / ( top - bottom );
    c = - ( far + near ) / ( far - near );
    d = - 2 * far * near / ( far - near );

    te[0] = x;  te[4] = 0;  te[8] = a;   te[12] = 0;
    te[1] = 0;  te[5] = y;  te[9] = b;   te[13] = 0;
    te[2] = 0;  te[6] = 0;  te[10] = c;   te[14] = d;
    te[3] = 0;  te[7] = 0;  te[11] = - 1; te[15] = 0;

    return this;
  }

  Matrix4 makePerspective( num fov, num aspect, num near, num far ) {
    num ymax, ymin, xmin, xmax;

    ymax = near * Math.tan( fov * Math.PI / 360 );
    ymin = - ymax;
    xmin = ymin * aspect;
    xmax = ymax * aspect;

    return makeFrustum( xmin, xmax, ymin, ymax, near, far );
  }
}

class Vector3 {
  Float32Array elements;
  
  Vector3([x = 0, y = 0, z = 0]) : elements = new Float32Array(3) {
    setValues(x, y, z);
  }
  
  setValues(x, y, z) {
    elements[0] = x; elements[1] = y; elements[2] = z;
  }
  
  get x() => elements[0];
  get y() => elements[1];
  get z() => elements[2];
}