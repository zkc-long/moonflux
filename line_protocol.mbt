///|
/// Encode one point as a line-protocol row.
pub fn encode_point(point : Point) -> Result[String, String] {
  match validate_point(point) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }

  let out = StringBuilder()
  out.write_string(escape_measurement(point.measurement))

  for i in 0..<point.tags.length() {
    let (key, value) = point.tags[i]
    out.write_char(',')
    out.write_string(escape_key_like(key))
    out.write_char('=')
    out.write_string(escape_key_like(value))
  }

  out.write_char(' ')
  for i in 0..<point.fields.length() {
    let (key, value) = point.fields[i]
    if i > 0 {
      out.write_char(',')
    }
    out.write_string(escape_key_like(key))
    out.write_char('=')
    out.write_string(field_value_to_protocol(value))
  }

  match point.timestamp {
    Some(timestamp) => {
      out.write_char(' ')
      out.write_string(timestamp.to_string())
    }
    None => ()
  }

  Ok(out.to_string())
}

///|
/// Validate point invariants required by InfluxDB Line Protocol.
pub fn validate_point(point : Point) -> Result[Unit, String] {
  if point.measurement.is_empty() {
    return Err("measurement must not be empty")
  }
  if point.fields.is_empty() {
    return Err("at least one field is required")
  }
  for i in 0..<point.tags.length() {
    let (key, _) = point.tags[i]
    if key.is_empty() {
      return Err("tag key must not be empty")
    }
    for j in 0..<i {
      if point.tags[j].0 == key {
        return Err("duplicate tag key: \{key}")
      }
    }
  }
  for i in 0..<point.fields.length() {
    let (key, value) = point.fields[i]
    if key.is_empty() {
      return Err("field key must not be empty")
    }
    match value {
      DoubleValue(value) =>
        if value.is_nan() || value.is_inf() {
          return Err("float field must be finite: \{key}")
        }
      _ => ()
    }
    for j in 0..<i {
      if point.fields[j].0 == key {
        return Err("duplicate field key: \{key}")
      }
    }
  }
  Ok(())
}

///|
/// Encode many points, separated by newlines.
pub fn encode_points(points : Array[Point]) -> Result[String, String] {
  let out = StringBuilder()
  for i in 0..<points.length() {
    if i > 0 {
      out.write_char('\n')
    }
    match encode_point(points[i]) {
      Ok(line) => out.write_string(line)
      Err(error) => return Err(error)
    }
  }
  Ok(out.to_string())
}

///|
/// Parse one line-protocol row.
pub fn parse_line(line : String) -> Result[Point, String] {
  if line.is_empty() {
    return Err("line must not be empty")
  }

  let comma = find_unescaped(line, 0, 44)
  let space = find_unescaped(line, 0, 32)
  let measurement_end = match (comma, space) {
    (Some(a), Some(b)) => if a < b { a } else { b }
    (Some(a), None) => a
    (None, Some(b)) => b
    (None, None) => return Err("line must contain fields")
  }
  if measurement_end == 0 {
    return Err("measurement must not be empty")
  }

  let measurement = unescape_measurement(line[0:measurement_end].to_owned())
  let mut cursor = measurement_end
  let mut point = new_point(measurement)

  if cursor < line.length() && line.at(cursor).to_int() == 44 {
    match parse_tag_set(line, cursor, point) {
      Ok((updated, next)) => {
        point = updated
        cursor = next
      }
      Err(error) => return Err(error)
    }
  }

  if cursor >= line.length() || line.at(cursor).to_int() != 32 {
    return Err("tags must be followed by a space")
  }
  let field_start = cursor + 1
  let timestamp_start = find_field_unescaped(line, field_start, 32)
  let field_end = match timestamp_start {
    Some(index) => index
    None => line.length()
  }
  if field_end <= field_start {
    return Err("at least one field is required")
  }
  match parse_field_set(line[field_start:field_end].to_owned()) {
    Ok(fields) =>
      for field in fields {
        point.fields.push(field)
      }
    Err(error) => return Err(error)
  }

  match timestamp_start {
    Some(index) => {
      let raw = line[index + 1:line.length()].to_owned()
      if raw.is_empty() {
        return Err("timestamp must not be empty")
      }
      match try_parse_int64(raw) {
        Ok(timestamp) => point = { ..point, timestamp: Some(timestamp), }
        Err(error) => return Err(error)
      }
    }
    None => ()
  }

  Ok(point)
}

///|
/// Parse a newline-delimited line-protocol payload.
pub fn parse_lines(text : String) -> Result[Array[Point], String] {
  let points : Array[Point] = Array(capacity=0)
  for line in text.split("\n") {
    let clean = line.trim().to_owned()
    if clean.is_empty() {
      continue
    }
    match parse_line(clean) {
      Ok(point) => points.push(point)
      Err(error) => return Err(error)
    }
  }
  Ok(points)
}

///|
/// Return the first unescaped occurrence of an ASCII code, or None.
fn find_unescaped(value : String, start : Int32, target : Int32) -> Int32? {
  let mut escaped = false
  for i in start..<value.length() {
    let code = value.at(i).to_int()
    if escaped {
      escaped = false
    } else if code == 92 {
      escaped = true
    } else if code == target {
      return Some(i)
    }
  }
  None
}

///|
/// Like find_unescaped, but treats double-quoted string fields as opaque.
fn find_field_unescaped(
  value : String,
  start : Int32,
  target : Int32,
) -> Int32? {
  let mut escaped = false
  let mut in_string = false
  for i in start..<value.length() {
    let code = value.at(i).to_int()
    if in_string {
      if escaped {
        escaped = false
      } else if code == 92 {
        escaped = true
      } else if code == 34 {
        in_string = false
      }
    } else if escaped {
      escaped = false
    } else if code == 92 {
      escaped = true
    } else if code == 34 {
      in_string = true
    } else if code == target {
      return Some(i)
    }
  }
  None
}

///|
/// Parse the tag set between a leading comma and the next space.
fn parse_tag_set(
  line : String,
  start : Int32,
  point : Point,
) -> Result[(Point, Int32), String] {
  let content_start = start + 1
  let end = match find_unescaped(line, content_start, 32) {
    Some(index) => index
    None => line.length()
  }
  if end == content_start {
    return Err("tag set must not be empty")
  }
  match parse_pairs(line[content_start:end].to_owned()) {
    Ok(tags) => {
      let updated = point
      for tag in tags {
        updated.tags.push(tag)
      }
      Ok((updated, end))
    }
    Err(error) => Err(error)
  }
}

///|
/// Parse tag or field pairs.
fn parse_pairs(content : String) -> Result[Array[(String, String)], String] {
  let pairs : Array[(String, String)] = Array(capacity=0)
  let mut start = 0
  while start < content.length() {
    let end = match find_field_unescaped(content, start, 44) {
      Some(index) => index
      None => content.length()
    }
    if end == start {
      return Err("empty tag or field pair")
    }
    let raw = content[start:end].to_owned()
    let eq_index = match find_field_unescaped(raw, 0, 61) {
      Some(index) => index
      None => return Err("tag or field pair must contain '='")
    }
    if eq_index == 0 || eq_index + 1 >= raw.length() {
      return Err("tag or field key/value must not be empty")
    }
    let key = raw[0:eq_index].to_owned()
    let value = raw[eq_index + 1:raw.length()].to_owned()
    pairs.push((unescape_key_like(key), unescape_key_like(value)))
    start = if end == content.length() { end } else { end + 1 }
  }
  Ok(pairs)
}

///|
/// Parse the field set.
fn parse_field_set(
  content : String,
) -> Result[Array[(String, FieldValue)], String] {
  let fields : Array[(String, FieldValue)] = Array(capacity=0)
  let mut start = 0
  while start < content.length() {
    let end = match find_field_unescaped(content, start, 44) {
      Some(index) => index
      None => content.length()
    }
    if end == start {
      return Err("empty field pair")
    }
    let raw = content[start:end].to_owned()
    let eq_index = match find_field_unescaped(raw, 0, 61) {
      Some(index) => index
      None => return Err("field pair must contain '='")
    }
    if eq_index == 0 || eq_index + 1 >= raw.length() {
      return Err("field key/value must not be empty")
    }
    let key = raw[0:eq_index].to_owned()
    let value = raw[eq_index + 1:raw.length()].to_owned()
    match parse_field_value(value) {
      Ok(parsed) => fields.push((unescape_key_like(key), parsed))
      Err(error) => return Err(error)
    }
    start = if end == content.length() { end } else { end + 1 }
  }
  Ok(fields)
}

///|
/// Convert a field value to line-protocol text.
fn field_value_to_protocol(value : FieldValue) -> String {
  match value {
    IntValue(value) => value.to_string() + "i"
    UIntValue(value) => value.to_string() + "u"
    DoubleValue(value) => value.to_string()
    StringValue(value) => "\"" + escape_string_field(value) + "\""
    BoolValue(value) => if value { "true" } else { "false" }
  }
}

///|
/// Parse an InfluxDB field value.
fn parse_field_value(raw : String) -> Result[FieldValue, String] {
  if raw.has_prefix("\"") {
    if raw.length() < 2 || !raw.has_suffix("\"") {
      return Err("unterminated string field")
    }
    return Ok(
      StringValue(unescape_string_field(raw[1:raw.length() - 1].to_owned())),
    )
  }

  let lower = raw.to_lower()
  if lower == "t" || lower == "true" {
    return Ok(BoolValue(true))
  }
  if lower == "f" || lower == "false" {
    return Ok(BoolValue(false))
  }

  if raw.has_suffix("i") {
    let numeric = raw[0:raw.length() - 1].to_owned()
    return match try_parse_int64(numeric) {
      Ok(value) => Ok(IntValue(value))
      Err(error) => Err(error)
    }
  }
  if raw.has_suffix("u") {
    let numeric = raw[0:raw.length() - 1].to_owned()
    return match try_parse_uint64(numeric) {
      Ok(value) => Ok(UIntValue(value))
      Err(error) => Err(error)
    }
  }

  match try_parse_double(raw) {
    Ok(value) => Ok(DoubleValue(value))
    Err(error) => Err(error)
  }
}

///|
/// Parse an Int64 without leaking parser exceptions.
fn try_parse_int64(text : String) -> Result[Int64, String] {
  Ok(@string.parse_int64(text)) catch {
    _ => Err("invalid integer \{text}")
  }
}

///|
/// Parse a UInt64 without leaking parser exceptions.
fn try_parse_uint64(text : String) -> Result[UInt64, String] {
  Ok(@string.parse_uint64(text)) catch {
    _ => Err("invalid unsigned integer \{text}")
  }
}

///|
/// Parse a Double without leaking parser exceptions.
fn try_parse_double(text : String) -> Result[Double, String] {
  Ok(@string.parse_double(text)) catch {
    _ => Err("invalid float \{text}")
  }
}
