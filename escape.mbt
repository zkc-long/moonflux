///|
/// Escape a measurement.
pub fn escape_measurement(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old=",", new="\\,")
  .replace_all(old=" ", new="\\ ")
}

///|
/// Escape a tag key, tag value, or field key.
pub fn escape_key_like(value : String) -> String {
  escape_measurement(value).replace_all(old="=", new="\\=")
}

///|
/// Escape a string field value.
pub fn escape_string_field(value : String) -> String {
  value.replace_all(old="\\", new="\\\\").replace_all(old="\"", new="\\\"")
}

///|
/// Remove InfluxDB key-like escapes.
pub fn unescape_key_like(value : String) -> String {
  unescape_protocol(value)
}

///|
/// Remove InfluxDB measurement escapes.
pub fn unescape_measurement(value : String) -> String {
  unescape_protocol(value)
}

///|
/// Remove string-field escapes.
pub fn unescape_string_field(value : String) -> String {
  let out = StringBuilder()
  let mut escaped = false
  for i in 0..<value.length() {
    let code = value.at(i).to_int()
    if escaped {
      out.write_char(value.at(i).to_char().unwrap())
      escaped = false
    } else if code == 92 {
      escaped = true
    } else {
      out.write_char(value.at(i).to_char().unwrap())
    }
  }
  if escaped {
    out.write_char('\\')
  }
  out.to_string()
}

///|
/// Shared line-protocol unescape logic. Backslash followed by any byte is an escape.
fn unescape_protocol(value : String) -> String {
  let out = StringBuilder()
  let mut escaped = false
  for i in 0..<value.length() {
    if escaped {
      out.write_char(value.at(i).to_char().unwrap())
      escaped = false
    } else if value.at(i).to_int() == 92 {
      escaped = true
    } else {
      out.write_char(value.at(i).to_char().unwrap())
    }
  }
  if escaped {
    out.write_char('\\')
  }
  out.to_string()
}
