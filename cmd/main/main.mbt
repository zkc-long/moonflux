///| MoonFlux command-line client for InfluxDB v2.
async fn main {
  let args = @env.args()
  let command = match args.get(1) {
    Some(value) => value
    None => {
      print_help()
      return
    }
  }

  match command {
    "ping" => run_ping(args)
    "write" => run_write(args)
    "query" => run_query(args)
    "encode" => run_encode(args)
    "help" | "--help" | "-h" => print_help()
    _ => {
      println("unknown command: \{command}")
      print_help()
    }
  }
}

///| Run a health check.
async fn run_ping(args : Array[String]) -> Unit {
  let config = make_config(args, token=false, bucket=false)
  let client = @client.new_client(config)
  match client.ping() {
    Ok(status) => println("InfluxDB /health returned \{status}")
    Err(error) => println(error)
  }
}

///| Write line protocol to InfluxDB.
async fn run_write(args : Array[String]) -> Unit {
  let config = make_config(args, token=true, bucket=true)
  let data = required(args, ["--data", "-d"])
  if data.is_empty() {
    println("write requires --data")
    return
  }
  let client = @client.new_client(config)
  match client.write(data) {
    Ok(status) => println("write accepted with status \{status}")
    Err(error) => println(error)
  }
}

///| Run a Flux query and print parsed annotated CSV rows.
async fn run_query(args : Array[String]) -> Unit {
  let config = make_config(args, token=true, bucket=false)
  let query = required(args, ["--query", "-q"])
  if query.is_empty() {
    println("query requires --query")
    return
  }
  let client = @client.new_client(config)
  match client.query(query) {
    Ok(parsed) => {
      let mut header = ""
      for column in parsed.columns {
        header = header + column.name + ","
      }
      println(header)
      for row in parsed.rows {
        let mut line = ""
        for value in row.values {
          line = line + value + ","
        }
        println(line)
      }
    }
    Err(error) => println(error)
  }
}

///| Encode a tiny command-line point as line protocol.
fn run_encode(args : Array[String]) -> Unit {
  let measurement = required(args, ["--measurement", "-m"])
  let field = required(args, ["--field", "-f"])
  if measurement.is_empty() || field.is_empty() {
    println("encode requires --measurement and --field")
    return
  }
  let point = @moonflux.new_point(measurement).add_field(
    "value",
    @moonflux.DoubleValue(try_parse_double_or_zero(field)),
  )
  match @moonflux.encode_point(point) {
    Ok(line) => println(line)
    Err(error) => println(error)
  }
}

///| Build a client configuration from common CLI options.
fn make_config(
  args : Array[String],
  token~ : Bool,
  bucket~ : Bool,
) -> @client.ClientConfig {
  {
    url: required(args, ["--url", "-u"]),
    token: if token { required(args, ["--token", "-t"]) } else { "" },
    org: required(args, ["--org", "-o"]),
    bucket: if bucket { required(args, ["--bucket", "-b"]) } else { "" },
  }
}

///| Return an option value or a default.
fn option(args : Array[String], names : Array[String], default : String) -> String {
  for i in 1..<args.length() {
    if names.contains(args[i]) {
      match args.get(i + 1) {
        Some(value) => return value
        None => return default
      }
    }
  }
  default
}

///| Return an option value or an empty string.
fn required(args : Array[String], names : Array[String]) -> String {
  option(args, names, "")
}

///| Parse a double for the tiny encode command.
fn try_parse_double_or_zero(value : String) -> Double {
  try {
    @string.parse_double(value)
  } catch {
    _ => Double::from_int(0)
  }
}

///| Print command usage.
fn print_help() -> Unit {
  println("MoonFlux InfluxDB v2 client")
  println("")
  println("Usage:")
  println("  moonflux ping  --url http://localhost:8086")
  println("  moonflux write --url ... --token ... --org ... --bucket ... --data \"m,host=a value=1i\"")
  println("  moonflux query --url ... --token ... --org ... --query \"from(bucket: \\\"mybucket\\\")\"")
  println("  moonflux encode --measurement weather --field 21.5")
}
