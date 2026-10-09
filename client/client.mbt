///|
/// InfluxDB v2 client configuration.
pub(all) struct ClientConfig {
  url : String
  token : String
  org : String
  bucket : String
}

///|
/// A small InfluxDB v2 HTTP client.
pub(all) struct Client {
  config : ClientConfig
}

///|
/// Create a client from configuration.
pub fn new_client(config : ClientConfig) -> Client {
  { config, }
}

///|
/// Ping the InfluxDB /health endpoint and return the HTTP status.
pub async fn Client::ping(self : Client) -> Result[Int, String] {
  try {
    let url = base_url(self) + "/health"
    let (response, body) = @http.get(url)
    if response.code >= 200 && response.code < 300 {
      Ok(response.code)
    } else {
      Err(
        "InfluxDB /health returned status \{response.code}: " + body_text(body),
      )
    }
  } catch {
    _ => Err("failed to reach InfluxDB health endpoint")
  }
}

///|
/// Write a line-protocol payload to the configured bucket.
pub async fn Client::write(self : Client, line : String) -> Result[Int, String] {
  self.write_with_precision(line, "ns")
}

///|
/// Write a payload with an explicit InfluxDB timestamp precision.
pub async fn Client::write_with_precision(
  self : Client,
  line : String,
  precision : String,
) -> Result[Int, String] {
  try {
    let headers : Map[@http.CaseInsensitiveString, String] = Map([
      ("Authorization", "Token " + self.config.token),
      ("Content-Type", "text/plain; charset=utf-8"),
    ])
    let url = write_url(self, precision)
    let (response, body) = @http.post(url, line, headers~)
    if response.code >= 200 && response.code < 300 {
      Ok(response.code)
    } else {
      Err(
        "InfluxDB write failed with status \{response.code}: " + body_text(body),
      )
    }
  } catch {
    _ => Err("failed to write to InfluxDB")
  }
}

///|
/// Run a Flux query and parse the annotated CSV response.
pub async fn Client::query(
  self : Client,
  flux : String,
) -> Result[@moonflux.AnnotatedCsv, String] {
  try {
    let headers : Map[@http.CaseInsensitiveString, String] = Map([
      ("Authorization", "Token " + self.config.token),
      ("Accept", "application/csv"),
      ("Content-Type", "application/vnd.flux"),
    ])
    let url = query_url(self)
    let (response, body) = @http.post(url, flux, headers~)
    if response.code < 200 || response.code >= 300 {
      return Err(
        "InfluxDB query failed with status \{response.code}: " + body_text(body),
      )
    }
    match @moonflux.parse_annotated_csv(body.text()) {
      Ok(parsed) => Ok(parsed)
      Err(error) => Err(error)
    }
  } catch {
    _ => Err("failed to query InfluxDB or decode annotated CSV")
  }
}

///|
/// Normalize the configured server URL and remove one trailing slash.
fn base_url(client : Client) -> String {
  if client.config.url.has_suffix("/") {
    client.config.url[0:client.config.url.length() - 1].to_owned()
  } else {
    client.config.url
  }
}

///|
/// Build an encoded `/api/v2/write` URL.
fn write_url(client : Client, precision : String) -> String {
  base_url(client) +
  "/api/v2/write?org=" +
  @percent.encode(client.config.org) +
  "&bucket=" +
  @percent.encode(client.config.bucket) +
  "&precision=" +
  @percent.encode(precision)
}

///|
/// Build an encoded `/api/v2/query` URL.
fn query_url(client : Client) -> String {
  base_url(client) + "/api/v2/query?org=" + @percent.encode(client.config.org)
}

///|
/// Read an HTTP response body for error reporting.
fn body_text(body : &@io.Data) -> String {
  body.text() catch {
    _ => ""
  }
}
