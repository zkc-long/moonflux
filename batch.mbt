///|
/// Limits used when splitting a Line Protocol payload for transport.
pub(all) struct BatchLimits {
  max_points : Int32
  max_bytes : Int32
}

///|
/// Create explicit batch limits.
pub fn BatchLimits::new(max_points : Int32, max_bytes : Int32) -> BatchLimits {
  { max_points, max_bytes, }
}

///|
/// Split a newline-delimited payload without exceeding point or byte limits.
pub fn split_line_protocol(
  text : String,
  limits : BatchLimits,
) -> Result[Array[String], String] {
  if limits.max_points <= 0 {
    return Err("max_points must be positive")
  }
  if limits.max_bytes <= 0 {
    return Err("max_bytes must be positive")
  }

  let batches : Array[String] = Array(capacity=0)
  let current = StringBuilder()
  let mut current_points = 0
  let mut current_bytes = 0

  for raw_line in text.split("\n") {
    let line = raw_line.trim().to_owned()
    if line.is_empty() {
      continue
    }
    let line_bytes = line.length()
    if line_bytes > limits.max_bytes {
      return Err(
        "single point exceeds max_bytes: \{line_bytes} > \{limits.max_bytes}",
      )
    }
    let separator_bytes = if current_points == 0 { 0 } else { 1 }
    let next_points = current_points + 1
    let next_bytes = current_bytes + separator_bytes + line_bytes
    if current_points > 0 &&
      (next_points > limits.max_points || next_bytes > limits.max_bytes) {
      batches.push(current.to_string())
      current.reset()
      current_points = 0
      current_bytes = 0
    }
    if current_points > 0 {
      current.write_char('\n')
    }
    current.write_string(line)
    current_points = current_points + 1
    let separator = if current_points > 1 { 1 } else { 0 }
    current_bytes = current_bytes + line_bytes + separator
  }

  if current_points > 0 {
    batches.push(current.to_string())
  }
  Ok(batches)
}

///|
/// Encode points into bounded Line Protocol batches.
pub fn encode_point_batches(
  points : Array[Point],
  limits : BatchLimits,
) -> Result[Array[String], String] {
  let lines : Array[String] = Array(capacity=points.length())
  for point in points {
    match encode_point(point) {
      Ok(line) => lines.push(line)
      Err(error) => return Err(error)
    }
  }
  split_line_protocol(lines.join("\n"), limits)
}
