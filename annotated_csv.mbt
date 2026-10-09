///|
/// Column metadata from an InfluxDB annotated CSV response.
pub(all) struct AnnotatedColumn {
  name : String
  data_type : String
  group : Bool
  default : String
}

///|
/// One data row from an annotated CSV response.
pub(all) struct AnnotatedRow {
  values : Array[String]
}

///|
/// Parsed annotated CSV response.
pub(all) struct AnnotatedCsv {
  columns : Array[AnnotatedColumn]
  rows : Array[AnnotatedRow]
}

///|
/// Parse an InfluxDB annotated CSV response.
pub fn parse_annotated_csv(text : String) -> Result[AnnotatedCsv, String] {
  let data_types : Array[String] = Array(capacity=0)
  let groups : Array[Bool] = Array(capacity=0)
  let defaults : Array[String] = Array(capacity=0)
  let data_rows : Array[Array[String]] = Array(capacity=0)
  let mut column_names : Array[String] = Array(capacity=0)

  for line in text.split("\n") {
    let clean = line.trim().to_owned()
    if clean.is_empty() {
      continue
    }
    if clean.has_prefix("#datatype") {
      match parse_csv_row(clean[9:].to_owned()) {
        Ok(values) => {
          data_types.clear()
          data_types.append(values)
        }
        Err(error) => return Err(error)
      }
      continue
    }
    if clean.has_prefix("#group") {
      match parse_bool_annotation(clean[6:].to_owned()) {
        Ok(values) => {
          groups.clear()
          groups.append(values)
        }
        Err(error) => return Err(error)
      }
      continue
    }
    if clean.has_prefix("#default") {
      match parse_csv_row(clean[8:].to_owned()) {
        Ok(values) => {
          defaults.clear()
          defaults.append(values)
        }
        Err(error) => return Err(error)
      }
      continue
    }
    if clean.has_prefix("#") {
      continue
    }

    match parse_csv_row(clean) {
      Ok(row) =>
        if column_names.is_empty() {
          column_names = row
        } else {
          data_rows.push(row)
        }
      Err(error) => return Err(error)
    }
  }

  if column_names.is_empty() {
    return Err("annotated CSV must contain a column-name row")
  }

  let columns : Array[AnnotatedColumn] = Array(capacity=0)
  for i in 1..<column_names.length() {
    let data_type = if i < data_types.length() {
      data_types[i]
    } else {
      "string"
    }
    let group = if i < groups.length() { groups[i] } else { false }
    let default = if i < defaults.length() { defaults[i] } else { "" }
    columns.push({ name: column_names[i], data_type, group, default, })
  }

  let rows : Array[AnnotatedRow] = Array(capacity=0)
  for raw in data_rows {
    if raw.length() != column_names.length() {
      return Err("annotated CSV row column count does not match header")
    }
    rows.push({ values: raw, })
  }

  Ok({ columns, rows, })
}

///|
/// Parse a CSV row while respecting double quotes.
fn parse_csv_row(line : String) -> Result[Array[String], String] {
  let values : Array[String] = Array(capacity=0)
  let field = StringBuilder()
  let mut in_quotes = false
  let mut i = 0

  while i < line.length() {
    let code = line.at(i).to_int()
    if in_quotes {
      if code == 34 {
        if i + 1 < line.length() && line.at(i + 1).to_int() == 34 {
          field.write_char('"')
          i = i + 1
        } else {
          in_quotes = false
        }
      } else {
        field.write_char(line.at(i).to_char().unwrap())
      }
    } else if code == 34 {
      in_quotes = true
    } else if code == 44 {
      values.push(field.to_string())
      field.reset()
    } else {
      field.write_char(line.at(i).to_char().unwrap())
    }
    i = i + 1
  }
  values.push(field.to_string())
  Ok(values)
}

///|
/// Parse the #group annotation, which contains true/false tokens.
fn parse_bool_annotation(line : String) -> Result[Array[Bool], String] {
  match parse_csv_row(line) {
    Ok(values) => {
      let out : Array[Bool] = Array(capacity=0)
      for value in values {
        if value.is_empty() {
          out.push(false)
        } else if value == "true" {
          out.push(true)
        } else if value == "false" {
          out.push(false)
        } else {
          return Err("invalid #group value \{value}")
        }
      }
      Ok(out)
    }
    Err(error) => Err(error)
  }
}
