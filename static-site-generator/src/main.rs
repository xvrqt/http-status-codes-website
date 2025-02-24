use serde::{Deserialize, Serialize};
use serde_json::Result;

/* The JSON file full of structured HTTP error code infomation */
const HTTP_ERROR_JSON_FILE: &str = "errors.json";

/* The JSON will provide an array of HTTP error information */
#[derive(Serialize, Deserialize)]
struct HttpError {
    code: String,
    reason: String,
    descriptions: String,
    link: String,
}


fn main() {
    println!("Hello, world!");
}
